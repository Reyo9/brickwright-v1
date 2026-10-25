// Background worker (up to 15 minutes): calls the AI, saves the text to the database as it streams,
// marks the job done/failed, and refunds the credits if no complete script came back.
import { CONFIG } from '../lib/config.mjs';
import { redis, refund, internalToken } from '../lib/core.mjs';
import { COACH } from '../lib/coach.mjs';

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
  const t0 = Date.now();
  const log = (...a) => console.log('[build ' + id.slice(0, 8) + ' +' + Math.round((Date.now() - t0) / 1000) + 's]', ...a);
  // give up if the AI sends nothing at all (no text, no thinking) for this long
  const IDLE_MS = (parseInt(process.env.AI_IDLE_SECONDS || '150', 10) || 150) * 1000;
  const ctrl = new AbortController();
  let idleTimer = null;
  const poke = () => { clearTimeout(idleTimer); idleTimer = setTimeout(() => ctrl.abort(), IDLE_MS); };

  let full = '', failure = null, lastSave = 0, cancelled = false, thinking = 0;
  const save = async (force) => {
    if (!force && Date.now() - lastSave < 700) return;
    lastSave = Date.now();
    await redis('SET', 'job:' + id + ':text', full, 'EX', 3600);
    if (thinking && !full) await setJob(id, { thinking });
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
      const model = process.env.AI_MODEL || CONFIG.aiModel;
      const body = { model, max_tokens: maxTokens, stream: true, messages: [{ role: 'system', content: COACH }, ...messages] };
      // Nemotron thinks before writing (better builds, slower). AI_THINKING=off turns it off for speed.
      // AI_THINKING=off: ask any model (Nemotron, DeepSeek, GLM, Qwen…) to skip its hidden thinking
      if (process.env.AI_THINKING === 'off') {
        if (/nemotron/i.test(model)) body.messages[0] = { role: 'system', content: '/no_think\n\n' + COACH };
        body.chat_template_kwargs = { enable_thinking: false, thinking: false };
        body.reasoning_effort = 'none';
      }
      log('calling', model, 'thinking', process.env.AI_THINKING === 'off' ? 'off' : 'on');
      poke();
      const call = (b) => fetch(base + '/chat/completions', {
        method: 'POST', signal: ctrl.signal,
        headers: { 'content-type': 'application/json', authorization: 'Bearer ' + process.env.AI_API_KEY },
        body: JSON.stringify(b),
      });
      // busy/overloaded → wait and retry, then try the backup models in AI_FALLBACK_MODELS (comma-separated)
      const models = [model, ...String(process.env.AI_FALLBACK_MODELS || '').split(',').map((x) => x.trim()).filter(Boolean)];
      const busy = (st) => st === 429 || st === 500 || st === 502 || st === 503 || st === 504 || st === 529;
      outer: for (const m of models) {
        body.model = m;
        for (let attempt = 0; attempt < 3; attempt++) {
          if (attempt) { await new Promise((r) => setTimeout(r, attempt * 4000)); poke(); }
          upstream = await call(body);
          log('AI answered HTTP', upstream.status, 'model', m, 'try', attempt + 1);
          if (upstream.status === 400 && (body.chat_template_kwargs || body.reasoning_effort)) {
            // provider rejected the extra switches — retry without them
            await upstream.text().catch(() => '');
            delete body.chat_template_kwargs; delete body.reasoning_effort;
            upstream = await call(body);
          }
          if (!busy(upstream.status)) break outer;
          if (await redis('GET', 'job:' + id + ':cancel')) break outer;
          await upstream.text().catch(() => '');
        }
      }
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
      poke();
      if (!full && !thinking && value && value.length) log('first data from AI');
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
          if (c && c.delta && (c.delta.reasoning_content || c.delta.reasoning)) thinking += String(c.delta.reasoning_content || c.delta.reasoning).length;
          if (ev.error) throw new Error(ev.error.message || String(ev.error));
        }
      }
      await save(false);
      if (cancelled) { try { await reader.cancel(); } catch (e) {} break; }
    }
  } catch (e) {
    failure = ctrl.signal.aborted
      ? 'The AI didn’t respond for ' + Math.round(IDLE_MS / 1000) + 's — NVIDIA’s free server may be overloaded. Try again or switch AI_MODEL.'
      : String(e.message || e);
    log('failed:', failure);
  }

  clearTimeout(idleTimer);
  log('finished', full.length, 'chars of text,', thinking, 'chars of thinking');
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
                
