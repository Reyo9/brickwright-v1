// POST /api/promo {code} — redeem a promo code from the PROMO_CODES env variable.
// Each account can use each code once; the credits are added to this month's (or this plan period's) allowance.
import { json, readJson, readSession, account, promoCodes, redis } from '../lib/core.mjs';

export default async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  const body = await readJson(req);
  const code = String(body.code || '').trim().toUpperCase();
  const promo = promoCodes()[code];
  if (!promo) return json({ error: 'That code isn’t valid.' }, 400);
  // slow down guessing: 10 tries per account per hour
  const tries = await redis('INCR', 'promotry:' + s.sub);
  if (tries === 1) await redis('EXPIRE', 'promotry:' + s.sub, 3600);
  if (tries > 10) return json({ error: 'Too many tries — wait an hour.' }, 429);
  const added = await redis('SADD', 'promo:' + code + ':users', s.sub);
  if (!added) return json({ error: 'You already used this code.' }, 409);
  if (promo.maxUses && (await redis('SCARD', 'promo:' + code + ':users')) > promo.maxUses) {
    await redis('SREM', 'promo:' + code + ':users', s.sub);
    return json({ error: 'This code has run out.' }, 410);
  }
  const a = await account(s.sub);
  await redis('INCRBY', 'bonus:' + a.bucket, promo.credits);
  await redis('EXPIRE', 'bonus:' + a.bucket, 60 * 60 * 24 * 400);
  return json({ ok: true, credits: promo.credits });
};

export const config = { path: '/api/promo' };
