// Background worker (up to 15 minutes): calls the AI, saves the text to the database as it streams,
// marks the job done/failed, and refunds the credits if no complete script came back.
import { CONFIG } from '../lib/config.mjs';
import { redis, refund, internalToken } from '../lib/core.mjs';

async function setJob(id, patch) {
  const raw = await redis('GET', 'job:' + id);
  const job = raw ? JSON.parse(raw) : {};
  Object.assign(job, patch, { updated: Date.now() });
  await redis('SET', 'job:' + id, JSON.stringify(job), 'EX', 3600);
  return job;
}

export default async (req) => {
  if (req.headers.get('x-internal') !== internalToken()) return new Response('forbidden', { status: 403 });
  const { id } = await req.json().catch(() => ({}));
  if (!id) return;
  // run each job once, even if Netlify retries the invocation
  if (!(await redis('SET', 'job:' + id + ':lock', '1', 'NX', 'EX', 900))) return;
  const rawJob = await redis('GET', 'job:' + id);
  const rawReq = await redis('GET', 'job:' + id + ':req');
  if (!rawJob || !rawReq) return;
  const job = JSON.parse(rawJob);
  const { messages, maxTokens } = JSON.parse(rawReq);
  await setJob(id, { status: 'running' });

  let full = '', failure = null, lastSave = 0, cancelled = false;
  const save = async (force) => {
    if (!force && Date.now() - lastSave < 700) return;
    lastSave = Date.now();
    await redis('SET', 'job:' + id + ':text', full, 'EX', 3600);
    if (await redis('GET', 'job:' + id + ':cancel')) cancelled = true;
  };

  try {
    const useAnthropic = !process.env.AI_API_KEY && process.env.ANTHROPIC_API_KEY;
    let upstream;
    if (useAnthropic) {
      upstream = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-api-key': process.env.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify({ model: process.env.AI_MODEL || 'claude-sonnet-5-5', max_tokens: maxTokens, stream: true, messages }),
      });
    } else {
      const base = (process.env.AI_BASE_URL || CONFIG.aiBaseUrl).replace(/\/$/, '');
      upstream = await fetch(base + '/chat/completions', {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: 'Bearer ' + process.env.AI_API_KEY },
        body: JSON.stringify({ model: process.env.AI_MODEL || CONFIG.aiModel, max_tokens: maxTokens, stream: true, messages }),
      });
    }
    if (!upstream.ok || !upstream.body) {
      const t = await upstream.text().catch(() => '');
      let msg = t; try { const j = JSON.parse(t); msg = (j.error && (j.error.message || j.error)) || j.detail || t; } catch (e) {}
      throw new Error(String(msg || ('AI service error ' + upstream.status)).slice(0, 400));
    }
    const reader = upstream.body.getReader();
    const dec = new TextDecoder();
    let buf = '';
    for (;;) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += dec.decode(value, { stream: true });
      let nl;
      while ((nl = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        if (!line.startsWith('data:')) continue;
        const data = line.slice(5).trim();
        if (!data || data === '[DONE]') continue;
        let ev; try { ev = JSON.parse(data); } catch (e) { continue; }
        if (useAnthropic) {
          if (ev.type === 'content_block_delta' && ev.delta && ev.delta.type === 'text_delta') full += ev.delta.text;
          if (ev.type === 'error') throw new Error((ev.error && ev.error.message) || 'stream error');
        } else {
          const c = ev.choices && ev.choices[0];
          if (c && c.delta && typeof c.delta.content === 'string') full += c.delta.content;
          if (ev.error) throw new Error(ev.error.message || String(ev.error));
        }
      }
      await save(false);
      if (cancelled) { try { await reader.cancel(); } catch (e) {} break; }
    }
  } catch (e) {
    failure = String(e.message || e);
  }

  // reasoning models may wrap their thinking in <think>...</think>; keep only the answer
  full = full.replace(/<think>[\s\S]*?<\/think>\s*/g, '');
  await save(true);
  const complete = /```(?:lua|luau)?\s*[\s\S]*?```/i.test(full);
  if (!complete || cancelled) await refund(job.bucket, job.cost);
  await setJob(id, {
    status: cancelled ? 'cancelled' : (complete ? 'done' : 'error'),
    error: cancelled ? null : (complete ? null : (failure || 'The AI didn’t return a complete script.')),
    refunded: !complete || cancelled,
  });
};

export const config = { path: '/api/generate-run', background: true };
