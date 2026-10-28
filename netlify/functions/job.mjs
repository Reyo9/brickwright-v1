// Polling endpoint: GET /api/job?id=...&from=N returns the job status plus any new text since N.
// POST /api/job?id=... with {cancel:true} stops a running build (credits are refunded).
import { json, readJson, readSession, redis, refund, refundJob } from '../lib/core.mjs';

export default async (req) => {
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  const url = new URL(req.url);
  const id = url.searchParams.get('id') || '';
  const raw = id && await redis('GET', 'job:' + id);
  if (!raw) return json({ error: 'Job not found (it may have expired).' }, 404);
  const job = JSON.parse(raw);
  if (job.acct !== s.sub) return json({ error: 'Not your job.' }, 403);

  if (req.method === 'POST') {
    const body = await readJson(req);
    if (body.cancel) await redis('SET', 'job:' + id + ':cancel', '1', 'EX', 3600);
    return json({ ok: true });
  }

  const from = Math.max(0, parseInt(url.searchParams.get('from') || '0', 10) || 0);
  const text = (await redis('GET', 'job:' + id + ':text')) || '';
  // a job still "queued" after 90s means the background worker never started
  const stuck = job.status === 'queued' && Date.now() - job.created > 90e3;
  if (stuck && !job.refunded && (await redis('SET', 'job:' + id + ':stuckrefund', '1', 'NX', 'EX', 3600))) {
    await refundJob(job);
    await redis('SET', 'job:' + id, JSON.stringify({ ...job, status: 'error', error: 'The build never started \u2014 please try again.', refunded: true }), 'EX', 3600);
    job.refunded = true;
  }
  return json({
    status: stuck ? 'error' : job.status,
    error: stuck ? 'The build never started — please try again.' : (job.error || null),
    refunded: !!job.refunded,
    thinking: job.thinking || 0,
    length: text.length,
    text: text.slice(from),
  });
};

export const config = { path: '/api/job' };
