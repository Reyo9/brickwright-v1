// Shared server helpers: Redis (Upstash REST), sessions, credits, email login, captcha, Stripe.
import crypto from 'crypto';
import { CONFIG, planPriceId } from './config.mjs';

// ---------------------------------------------------------------- responses
export const json = (obj, status = 200, extra = {}) =>
  new Response(JSON.stringify(obj), { status, headers: { 'content-type': 'application/json', 'cache-control': 'no-store', ...extra } });
export async function readJson(req) { try { return await req.json(); } catch (e) { return {}; } }

// ---------------------------------------------------------------- Redis (Upstash REST API)
export async function redis(...command) {
  const url = process.env.UPSTASH_REDIS_REST_URL, token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) throw new Error('Database not set up — add UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN in Netlify environment variables.');
  const r = await fetch(url, {
    method: 'POST',
    headers: { authorization: 'Bearer ' + token, 'content-type': 'application/json' },
    body: JSON.stringify(command),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || j.error) throw new Error('Database error: ' + (j.error || r.status));
  return j.result;
}

// ---------------------------------------------------------------- sessions (HMAC-signed, 30 days)
const secret = () => process.env.SESSION_SECRET || '';
const b64u = (buf) => Buffer.from(buf).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const sign = (data) => b64u(crypto.createHmac('sha256', secret()).update(data).digest());
export const internalToken = () => sign('internal-background-call');

export function makeSession(user) {
  if (!secret()) throw new Error('SESSION_SECRET is not set in Netlify environment variables.');
  const payload = b64u(JSON.stringify({ sub: user.sub, name: user.name || '', exp: Date.now() + 30 * 864e5 }));
  return payload + '.' + sign(payload);
}
export function readSession(req) {
  const h = req.headers.get('authorization') || '';
  const tok = h.startsWith('Bearer ') ? h.slice(7) : '';
  if (!tok || !secret()) return null;
  const [payload, sig] = tok.split('.');
  if (!payload || !sig) return null;
  const good = sign(payload);
  if (good.length !== sig.length || !crypto.timingSafeEqual(Buffer.from(good), Buffer.from(sig))) return null;
  try {
    const p = JSON.parse(Buffer.from(payload.replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString('utf8'));
    return p.sub && p.exp > Date.now() ? p : null;
  } catch (e) { return null; }
}

// ---------------------------------------------------------------- credits
function monthKey(d) { return d.getUTCFullYear() + '-' + String(d.getUTCMonth() + 1).padStart(2, '0'); }
function nextMonthStart(d) { return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1)).toISOString(); }

// Subscription state is written by the Stripe webhook: { planId, status, start, end, id, customer }
export async function activeSubscription(acct) {
  const raw = await redis('GET', 'sub:' + acct);
  if (!raw) return null;
  const s = JSON.parse(raw);
  const live = (s.status === 'active' || s.status === 'trialing') && (!s.end || Date.parse(s.end) > Date.now() - 3600e3);
  return live ? s : null;
}

export async function account(acct) {
  const now = new Date();
  const sub = await activeSubscription(acct);
  const plan = sub ? CONFIG.plans.find((p) => p.id === sub.planId) || null : null;
  let bucket, allowance, resetsAt;
  if (plan && plan.per === 'period' && sub.start) {
    bucket = 'cr:' + acct + ':' + sub.id + ':' + sub.start; allowance = plan.credits; resetsAt = sub.end || nextMonthStart(now);
  } else if (plan) {
    bucket = 'cr:' + acct + ':' + sub.id + ':' + monthKey(now); allowance = plan.credits; resetsAt = nextMonthStart(now);
  } else {
    bucket = 'cr:' + acct + ':free:' + monthKey(now); allowance = CONFIG.freeCreditsPerMonth; resetsAt = nextMonthStart(now);
  }
  const used = parseInt((await redis('GET', bucket)) || '0', 10) || 0;
  const customer = await redis('GET', 'cust:' + acct);
  return { plan: plan ? plan.id : 'free', planName: plan ? plan.name : 'Free', bucket, allowance, used,
    remaining: Math.max(0, allowance - used), resetsAt, hasBilling: !!customer };
}
export async function reserve(bucket, allowance, cost) {
  const after = await redis('INCRBY', bucket, cost);
  await redis('EXPIRE', bucket, 60 * 60 * 24 * 400);
  if (after > allowance) { await redis('DECRBY', bucket, cost); return false; }
  return true;
}
export async function refund(bucket, cost) { try { await redis('DECRBY', bucket, cost); } catch (e) {} }

export function publicPlans() {
  return CONFIG.plans.map((p) => ({ id: p.id, name: p.name, price: p.price, credits: p.credits, label: p.label, available: !!planPriceId(p) }));
}

// ---------------------------------------------------------------- email login helpers
export function clientIp(req, context) {
  return (context && context.ip) || (req.headers.get('x-nf-client-connection-ip')) ||
    String(req.headers.get('x-forwarded-for') || '').split(',')[0].trim() || 'unknown';
}
export function normalizeEmail(raw) {
  const e = String(raw || '').trim().toLowerCase();
  const m = /^([^@\s]+)@([^@\s]+\.[^@\s]+)$/.exec(e);
  if (!m) return null;
  let [, local, domain] = m;
  if (domain === 'googlemail.com') domain = 'gmail.com';
  if (domain === 'gmail.com') local = local.split('+')[0].replace(/\./g, '');
  return local ? local + '@' + domain : null;
}
export const hashCode = (email, code) => crypto.createHmac('sha256', secret() || 'x').update(email + ':' + code).digest('hex');

export async function verifyCaptcha(token, ip) {
  const key = process.env.TURNSTILE_SECRET_KEY;
  if (!key) return true; // not configured (local testing only)
  if (!token) return false;
  const r = await fetch(process.env.TURNSTILE_VERIFY_URL || 'https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST', body: new URLSearchParams({ secret: key, response: token, remoteip: ip }),
  });
  const j = await r.json().catch(() => ({}));
  return !!j.success;
}

export async function sendLoginCode(to, code) {
  const subject = 'Your Brickwright login code: ' + code;
  const text = 'Your Brickwright login code is ' + code + '\n\nIt expires in 10 minutes. If you didn\'t ask for this, ignore this email.';
  const html = '<div style="font-family:Arial,sans-serif;font-size:15px">Your Brickwright login code is<div style="font-size:30px;font-weight:bold;letter-spacing:6px;margin:12px 0">' + code + '</div>It expires in 10 minutes. If you didn\'t ask for this, ignore this email.</div>';
  if (process.env.EMAIL_DEBUG_LOG) { console.log('[email] to ' + to + ': ' + code); return; }
  if (process.env.RESEND_API_KEY) {
    const r = await fetch('https://api.resend.com/emails', {
      method: 'POST', headers: { authorization: 'Bearer ' + process.env.RESEND_API_KEY, 'content-type': 'application/json' },
      body: JSON.stringify({ from: process.env.EMAIL_FROM, to, subject, text, html }),
    });
    if (!r.ok) throw new Error('Email service error ' + r.status);
    return;
  }
  if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) throw new Error('Email sending is not set up (GMAIL_USER / GMAIL_APP_PASSWORD).');
  const nodemailer = (await import('nodemailer')).default;
  const t = nodemailer.createTransport({ service: 'gmail', auth: { user: process.env.GMAIL_USER, pass: process.env.GMAIL_APP_PASSWORD } });
  await t.sendMail({ from: '"Brickwright" <' + process.env.GMAIL_USER + '>', to, subject, text, html });
}

// ---------------------------------------------------------------- Stripe (REST, no SDK)
export async function stripe(method, path, params) {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) throw new Error('Stripe is not set up yet (STRIPE_SECRET_KEY).');
  const base = process.env.STRIPE_API_BASE || 'https://api.stripe.com';
  let url = base + '/v1/' + path, body;
  const form = new URLSearchParams();
  const add = (prefix, v) => {
    if (v == null) return;
    if (typeof v === 'object') { for (const k of Object.keys(v)) add(prefix ? prefix + '[' + k + ']' : k, v[k]); }
    else form.append(prefix, String(v));
  };
  add('', params || {});
  if (method === 'GET') { const q = form.toString(); if (q) url += '?' + q; } else body = form;
  const r = await fetch(url, { method, headers: { authorization: 'Bearer ' + key }, body });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error('Stripe error: ' + ((j.error && j.error.message) || r.status));
  return j;
}

// Verifies a Stripe webhook signature header ("t=...,v1=...") against the raw body.
export function verifyStripeSignature(raw, header, whsec) {
  if (!header || !whsec) return false;
  const parts = Object.fromEntries(header.split(',').map((kv) => kv.split('=')));
  const t = parts.t;
  const sigs = header.split(',').filter((kv) => kv.startsWith('v1=')).map((kv) => kv.slice(3));
  if (!t || !sigs.length) return false;
  if (Math.abs(Date.now() / 1000 - Number(t)) > 300) return false;
  const expected = crypto.createHmac('sha256', whsec).update(t + '.' + raw).digest('hex');
  return sigs.some((s) => s.length === expected.length && crypto.timingSafeEqual(Buffer.from(s), Buffer.from(expected)));
}
