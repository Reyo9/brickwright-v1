// Admin dashboard data — only for accounts listed in ADMIN_EMAILS.
// GET /api/admin → last 14 days of counters, top users, recent failures, totals.
import { json, readSession, redis, isAdmin, dayKey } from '../lib/core.mjs';

const METRICS = ['builds_started', 'builds_done', 'builds_failed', 'busy', 'fixes', 'cancelled',
  'task_rig', 'task_animate', 'task_enhance', 'task_gui', 'task_done', 'task_failed',
  'signups', 'logins', 'credits', 'detail_quick', 'detail_standard', 'detail_detailed', 'detail_ultra'];

async function topUsers(day, n) {
  const flat = (await redis('ZREVRANGE', 'st:' + day + ':users', 0, n - 1, 'WITHSCORES')) || [];
  const out = [];
  for (let i = 0; i < flat.length; i += 2) out.push({ acct: String(flat[i]).replace(/^em:/, ''), builds: Number(flat[i + 1]) || 0 });
  return out;
}

export default async (req) => {
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  if (!isAdmin(s.sub)) return json({ error: 'Admins only.' }, 403);

  const days = [];
  for (let i = 13; i >= 0; i--) days.push(dayKey(new Date(Date.now() - i * 864e5)));
  const series = {};
  for (const m of METRICS) series[m] = [];
  for (const d of days) {
    const vals = await Promise.all(METRICS.map((m) => redis('GET', 'st:' + d + ':' + m).catch(() => null)));
    METRICS.forEach((m, i) => series[m].push(Number(vals[i]) || 0));
  }
  const [today, yesterday] = [days[13], days[12]];
  const failuresRaw = await redis('GET', 'st:failures').catch(() => null);
  return json({
    days, series,
    topToday: await topUsers(today, 10),
    topYesterday: await topUsers(yesterday, 10),
    failures: failuresRaw ? JSON.parse(failuresRaw) : [],
    sharedBuilds: Number(await redis('ZCARD', 'builds:recent').catch(() => 0)) || 0,
    model: process.env.AI_MODEL || '', fallbacks: process.env.AI_FALLBACK_MODELS || '',
  });
};

export const config = { path: '/api/admin' };
