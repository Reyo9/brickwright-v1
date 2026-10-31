// Email login, step 2: check the code, create the account on first login, return a session.
import crypto from 'crypto';
import { CONFIG } from '../lib/config.mjs';
import { json, readJson, redis, clientIp, normalizeEmail, hashCode, makeSession, stat } from '../lib/core.mjs';

export default async (req, context) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const body = await readJson(req);
  const email = normalizeEmail(body.email);
  const code = String(body.code || '').replace(/\D/g, '');
  if (!email || code.length !== 6) return json({ error: 'Enter the 6-digit code from the email.' }, 400);
  try {
    const raw = await redis('GET', 'otp:' + email);
    if (!raw) return json({ error: 'That code expired — ask for a new one.' }, 400);
    const rec = JSON.parse(raw);
    const good = hashCode(email, code);
    if (rec.h.length !== good.length || !crypto.timingSafeEqual(Buffer.from(rec.h), Buffer.from(good))) {
      rec.tries = (rec.tries || 0) + 1;
      if (rec.tries >= 5) { await redis('DEL', 'otp:' + email); return json({ error: 'Too many wrong codes — ask for a new one.' }, 400); }
      await redis('SET', 'otp:' + email, JSON.stringify(rec), 'KEEPTTL');
      return json({ error: 'Wrong code — ' + (5 - rec.tries) + ' tries left.' }, 400);
    }
    await redis('DEL', 'otp:' + email);

    const acct = 'em:' + email;
    if (!(await redis('GET', 'acct:' + acct))) {
      const ip = clientIp(req, context);
      const k = 'newacct:' + ip + ':' + new Date().toISOString().slice(0, 10);
      const n = await redis('INCR', k);
      await redis('EXPIRE', k, 86400);
      if (n > (CONFIG.maxNewAccountsPerIpPerDay || 3)) {
        await redis('DECR', k);
        return json({ error: 'Too many new accounts from this network today — sign in to an existing one, or try tomorrow.' }, 429);
      }
      const k30 = 'newacct30:' + ip;
      const n30 = await redis('INCR', k30);
      if (n30 === 1) await redis('EXPIRE', k30, 60 * 60 * 24 * 30);
      if (n30 > (CONFIG.maxNewAccountsPerIpPer30Days || 4)) {
        await redis('DECR', k30); await redis('DECR', k);
        return json({ error: 'Too many accounts have been created from this network recently — please sign in to your existing account.' }, 429);
      }
      const dev = String(body.device || '').replace(/[^A-Za-z0-9_-]/g, '').slice(0, 40);
      if (dev.length >= 16) {
        const dk = 'dev:' + dev;
        await redis('SADD', dk, acct);
        await redis('EXPIRE', dk, 60 * 60 * 24 * 400);
        if ((await redis('SCARD', dk)) > (CONFIG.maxAccountsPerDevice || 2)) {
          await redis('SREM', dk, acct); await redis('DECR', k30); await redis('DECR', k);
          return json({ error: 'This device already has the maximum number of Brickwright accounts — please sign in to one of them.' }, 429);
        }
      }
      await redis('SET', 'acct:' + acct, JSON.stringify({ created: Date.now(), ip, email: String(body.email).trim().toLowerCase() }));
      await stat('signups');
    }
    await stat('logins');
    const shown = String(body.email).trim().toLowerCase();
    return json({ session: makeSession({ sub: acct, name: shown }), user: { id: acct, name: shown } });
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
};

export const config = { path: '/api/otp-verify' };
