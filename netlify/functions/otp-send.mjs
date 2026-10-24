// Email login, step 1: check the captcha + email, then email a 6-digit code (valid 10 minutes).
import crypto from 'crypto';
import { CONFIG } from '../lib/config.mjs';
import { json, readJson, redis, clientIp, normalizeEmail, hashCode, verifyCaptcha, sendLoginCode } from '../lib/core.mjs';

export default async (req, context) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const body = await readJson(req);
  const ip = clientIp(req, context);
  const email = normalizeEmail(body.email);
  if (!email) return json({ error: 'That doesn’t look like an email address.' }, 400);
  const allowed = CONFIG.allowedEmailDomains || [];
  if (allowed.length && !allowed.includes(email.split('@')[1])) {
    return json({ error: 'Please use a ' + allowed.map((d) => '@' + d).join(' / ') + ' address.' }, 400);
  }
  try {
    if (!(await verifyCaptcha(body.captcha, ip))) return json({ error: 'captcha_failed' }, 400);
    if (!(await redis('SET', 'otp-wait:' + email, '1', 'NX', 'EX', 60))) {
      return json({ error: 'A code was just sent — wait a minute before asking for another.' }, 429);
    }
    const ipKey = 'otp-ip:' + ip + ':' + new Date().toISOString().slice(0, 13);
    const n = await redis('INCR', ipKey);
    await redis('EXPIRE', ipKey, 3600);
    if (n > 8) return json({ error: 'Too many code requests from this network — try again in an hour.' }, 429);

    const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    await redis('SET', 'otp:' + email, JSON.stringify({ h: hashCode(email, code), tries: 0 }), 'EX', 600);
    await sendLoginCode(String(body.email).trim(), code);
    return json({ ok: true });
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
};

export const config = { path: '/api/otp-send' };
