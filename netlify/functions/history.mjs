// Your own generation history (private, per account).
// GET  /api/history?offset=0      → newest first, 12 per page (no scripts, small thumbnails)
// GET  /api/history?id=...        → one item with its script and notes
// POST /api/history {brief, detail, script, notes, parts, thumb}  → saves a build, keeps the newest 40
// DELETE /api/history?id=...      → removes one
import crypto from 'crypto';
import { json, readJson, readSession, redis } from '../lib/core.mjs';

const KEEP = 40, PAGE = 12, TTL = 60 * 60 * 24 * 120;

export default async (req) => {
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  const url = new URL(req.url);
  const list = 'hist:' + s.sub;
  const id = url.searchParams.get('id');

  if (req.method === 'GET' && id) {
    const raw = await redis('GET', 'hi:' + id);
    const it = raw && JSON.parse(raw);
    if (!it || it.acct !== s.sub) return json({ error: 'Not found.' }, 404);
    delete it.acct;
    return json(it);
  }
  if (req.method === 'GET') {
    const offset = Math.max(0, parseInt(url.searchParams.get('offset') || '0', 10) || 0);
    const ids = (await redis('ZREVRANGE', list, offset, offset + PAGE - 1)) || [];
    const total = (await redis('ZCARD', list)) || 0;
    const items = [];
    for (const hid of ids) {
      const raw = await redis('GET', 'hi:' + hid);
      if (!raw) { await redis('ZREM', list, hid); continue; }
      const it = JSON.parse(raw);
      items.push({ id: hid, brief: it.brief, detail: it.detail, parts: it.parts, created: it.created, thumb: it.thumb || null });
    }
    return json({ items, total, next: offset + PAGE < total ? offset + PAGE : null });
  }
  if (req.method === 'POST') {
    const b = await readJson(req);
    const script = String(b.script || '');
    if (!script.includes('Instance.new') || script.length > 150000) return json({ error: 'Nothing to save.' }, 400);
    const thumb = typeof b.thumb === 'string' && b.thumb.startsWith('data:image/') && b.thumb.length < 60000 ? b.thumb : null;
    const hid = crypto.randomBytes(6).toString('base64url');
    const created = Date.now();
    await redis('SET', 'hi:' + hid, JSON.stringify({
      acct: s.sub, brief: String(b.brief || '').slice(0, 600), detail: String(b.detail || 'standard').slice(0, 12),
      script, notes: String(b.notes || '').slice(0, 2000), parts: Number(b.parts) || 0, created, thumb,
    }), 'EX', TTL);
    await redis('ZADD', list, created, hid);
    // keep only the newest KEEP
    const extra = (await redis('ZREVRANGE', list, KEEP, KEEP + 200)) || [];
    for (const old of extra) { await redis('ZREM', list, old); await redis('DEL', 'hi:' + old); }
    return json({ id: hid });
  }
  if (req.method === 'DELETE' && id) {
    const raw = await redis('GET', 'hi:' + id);
    const it = raw && JSON.parse(raw);
    if (!it || it.acct !== s.sub) return json({ error: 'Not found.' }, 404);
    await redis('ZREM', list, id); await redis('DEL', 'hi:' + id);
    return json({ ok: true });
  }
  return json({ error: 'Method not allowed' }, 405);
};

export const config = { path: '/api/history' };
