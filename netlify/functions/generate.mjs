// Starts a generation: checks sign-in + credits, takes the credits, stores the job, and hands the
// actual AI call to the background function (Netlify caps normal functions at 60s; big builds can
// take longer). The page then polls /api/job for the text as it's written.
import crypto from 'crypto';
import { CONFIG } from '../lib/config.mjs';
import { json, readJson, readSession, account, reserve, refund, redis, internalToken } from '../lib/core.mjs';

export default async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  const body = await readJson(req);
  const prompt = body.prompt;
  if (!prompt || (typeof prompt !== 'string' && !Array.isArray(prompt))) return json({ error: 'Missing prompt' }, 400);
  if (!(process.env.AI_API_KEY || process.env.ANTHROPIC_API_KEY)) {
    return json({ error: 'No AI key set — add AI_API_KEY (your NVIDIA key) in Netlify → Site configuration → Environment variables, then redeploy.' }, 500);
  }
  let messages = Array.isArray(prompt) ? prompt : [{ role: 'user', content: prompt }];
  const detail = ['quick', 'standard', 'detailed'].includes(body.detail) ? body.detail : 'standard';
  let cost = body.kind === 'revise' ? CONFIG.costs.revise : CONFIG.costs[detail];
  let maxTokens = CONFIG.maxTokens[detail] || 24000;

  // Free automatic repair: once per finished build, the page sends back what its preview found wrong
  if (body.fixOf) {
    const fixOf = String(body.fixOf);
    const rawJob = await redis('GET', 'job:' + fixOf);
    const rawReq = await redis('GET', 'job:' + fixOf + ':req');
    const oldText = await redis('GET', 'job:' + fixOf + ':text');
    const old = rawJob && JSON.parse(rawJob);
    if (!old || !rawReq || !oldText || old.acct !== s.sub || old.status !== 'done' || old.fix) return json({ error: 'This build can’t be auto-fixed.' }, 400);
    if (!(await redis('SET', 'job:' + fixOf + ':fixed', '1', 'NX', 'EX', 3600))) return json({ error: 'Already fixed once.' }, 409);
    const req0 = JSON.parse(rawReq);
    const problems = String(body.problems || '').slice(0, 4000);
    messages = [...req0.messages, { role: 'assistant', content: oldText },
      { role: 'user', content: 'I ran your script in a Roblox-accurate preview and checked it. Problems found:\n' + problems +
        '\n\nFix every problem: replace any non-existent API with real Roblox API, and move every floating part down/over so it rests on or touches what holds it up (the floor, the part below it, or the wall it is mounted on). Keep everything that was already right. Reply in the same SCRIPT:/NOTES: format with the COMPLETE corrected script.' }];
    maxTokens = req0.maxTokens;
    cost = 0;
  }
  let acct;
  try { acct = await account(s.sub); } catch (e) { return json({ error: String(e.message || e) }, 500); }
  if (cost > 0 && !(await reserve(acct.bucket, acct.allowance, cost))) {
    return json({ error: 'out_of_credits', cost, remaining: acct.remaining, resetsAt: acct.resetsAt }, 402);
  }

  const id = crypto.randomUUID();
  try {
    await redis('SET', 'job:' + id, JSON.stringify({ acct: s.sub, bucket: acct.bucket, cost, status: 'queued', created: Date.now(), fix: !!body.fixOf }), 'EX', 3600);
    await redis('SET', 'job:' + id + ':req', JSON.stringify({ messages, maxTokens }), 'EX', 3600);
    const r = await fetch(new URL('/api/generate-run', req.url), {
      method: 'POST', headers: { 'content-type': 'application/json', 'x-internal': internalToken() }, body: JSON.stringify({ id }),
    });
    if (r.status >= 400) throw new Error('Background worker refused the job (' + r.status + ')');
  } catch (e) {
    if (cost > 0) await refund(acct.bucket, cost);
    return json({ error: 'Could not start the build: ' + (e.message || e) }, 500);
  }
  return json({ jobId: id, cost });
};

export const config = { path: '/api/generate' };
