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
  const messages = Array.isArray(prompt) ? prompt : [{ role: 'user', content: prompt }];
  const detail = ['quick', 'standard', 'detailed'].includes(body.detail) ? body.detail : 'standard';
  const cost = body.kind === 'revise' ? CONFIG.costs.revise : CONFIG.costs[detail];

  let acct;
  try { acct = await account(s.sub); } catch (e) { return json({ error: String(e.message || e) }, 500); }
  if (!(await reserve(acct.bucket, acct.allowance, cost))) {
    return json({ error: 'out_of_credits', cost, remaining: acct.remaining, resetsAt: acct.resetsAt }, 402);
  }

  const id = crypto.randomUUID();
  try {
    await redis('SET', 'job:' + id, JSON.stringify({ acct: s.sub, bucket: acct.bucket, cost, status: 'queued', created: Date.now() }), 'EX', 3600);
    await redis('SET', 'job:' + id + ':req', JSON.stringify({ messages, maxTokens: CONFIG.maxTokens[detail] || 24000 }), 'EX', 3600);
    const r = await fetch(new URL('/api/generate-run', req.url), {
      method: 'POST', headers: { 'content-type': 'application/json', 'x-internal': internalToken() }, body: JSON.stringify({ id }),
    });
    if (r.status >= 400) throw new Error('Background worker refused the job (' + r.status + ')');
  } catch (e) {
    await refund(acct.bucket, cost);
    return json({ error: 'Could not start the build: ' + (e.message || e) }, 500);
  }
  return json({ jobId: id, cost });
};

export const config = { path: '/api/generate' };
