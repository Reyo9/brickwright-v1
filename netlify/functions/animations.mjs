// Your saved rigs + animations (private, one project per generated build).
// GET  /api/animations?offset=0  → newest first, 12 per page (title, thumb, animation names)
// GET  /api/animations?id=HIST   → one project: {histId, title, rig, anims, current}
// POST /api/animations {histId, rig, anims, current}  → save/update (only for your own builds)
// DELETE /api/animations?id=HIST
import { json, readJson, readSession, redis } from '../lib/core.mjs';

const KEEP = 30, PAGE = 12, TTL = 60 * 60 * 24 * 120;

export default async (req) => {
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  const url = new URL(req.url);
  const list = 'anims:' + s.sub;
  const key = (h) => 'an:' + s.sub + ':' + h;
  const id = (url.searchParams.get('id') || '').replace(/[^A-Za-z0-9_-]/g, '');

  if (req.method === 'GET' && id) {
    const raw = await redis('GET', key(id));
    if (!raw) return json({ error: 'Not found.' }, 404);
    return json(JSON.parse(raw));
  }
  if (req.method === 'GET') {
    const offset = Math.max(0, parseInt(url.searchParams.get('offset') || '0', 10) || 0);
    const ids = (await redis('ZREVRANGE', list, offset, offset + PAGE - 1)) || [];
    const total = (await redis('ZCARD', list)) || 0;
    const items = [];
    for (const h of ids) {
      const raw = await redis('GET', key(h));
      if (!raw) { await redis('ZREM', list, h); continue; }
      const p = JSON.parse(raw);
      items.push({ id: h, title: p.title, thumb: p.thumb || null, updated: p.updated, joints: (p.rig && p.rig.groups || []).length,
        anims: (p.anims || []).map((a) => a.name) });
    }
    return json({ items, total, next: offset + PAGE < total ? offset + PAGE : null });
  }
  if (req.method === 'POST') {
    const b = await readJson(req);
    const histId = String(b.histId || '').replace(/[^A-Za-z0-9_-]/g, '');
    const hraw = histId && await redis('GET', 'hi:' + histId);
    const h = hraw && JSON.parse(hraw);
    if (!h || h.acct !== s.sub) return json({ error: 'You can only save animations for your own builds.' }, 403);
    const body = JSON.stringify({ rig: b.rig, anims: b.anims });
    if (!b.rig || body.length > 400000) return json({ error: 'Nothing to save, or it’s too large.' }, 400);
    const updated = Date.now();
    await redis('SET', key(histId), JSON.stringify({ histId, title: h.brief || 'My build', thumb: h.thumb || null,
      rig: b.rig, anims: Array.isArray(b.anims) ? b.anims.slice(0, 20) : [], current: Number(b.current) || 0, updated }), 'EX', TTL);
    await redis('ZADD', list, updated, histId);
    const extra = (await redis('ZREVRANGE', list, KEEP, KEEP + 200)) || [];
    for (const old of extra) { await redis('ZREM', list, old); await redis('DEL', key(old)); }
    return json({ ok: true });
  }
  if (req.method === 'DELETE' && id) {
    await redis('ZREM', list, id); await redis('DEL', key(id));
    return json({ ok: true });
  }
  return json({ error: 'Method not allowed' }, 405);
};

export const config = { path: '/api/animations' };
