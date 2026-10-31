// Public GUI gallery (templates people can remix).
//   GET  /api/guis?offset=N        -> {items:[{id,name,brief,style,created,spec}], next}
//   GET  /api/guis?id=X            -> one
//   POST /api/guis {spec, brief, style}   -> share (signed in)
//   DELETE /api/guis?id=X          -> delete your own (or admin)
import crypto from 'crypto';
import { json, readJson, readSession, redis, isAdmin } from '../lib/core.mjs';

const PAGE = 12;
const clean = (s, max) => String(s || '').replace(/[\u0000-\u001f<>]/g, '').replace(/\s+/g, ' ').trim().slice(0, max);

export default async (req) => {
  const url = new URL(req.url);
  const s = readSession(req);
  try {
    if (req.method === 'GET') {
      const id = url.searchParams.get('id');
      if (id) {
        const raw = await redis('GET', 'gs:' + id);
        if (!raw) return json({ error: 'Not found.' }, 404);
        const g = JSON.parse(raw);
        return json({ ...g, acct: undefined, mine: !!(s && s.sub === g.acct) });
      }
      const offset = Math.max(0, parseInt(url.searchParams.get('offset') || '0', 10) || 0);
      const ids = (await redis('ZREVRANGE', 'guis:recent', offset, offset + PAGE - 1)) || [];
      const total = (await redis('ZCARD', 'guis:recent')) || 0;
      const items = [];
      for (const gid of ids) {
        const raw = await redis('GET', 'gs:' + gid);
        if (!raw) { await redis('ZREM', 'guis:recent', gid); continue; }
        const g = JSON.parse(raw);
        items.push({ id: g.id, name: g.name, brief: g.brief, style: g.style, created: g.created, spec: g.spec, mine: !!(s && s.sub === g.acct) });
      }
      return json({ items, next: offset + PAGE < total ? offset + PAGE : null });
    }
    if (!s) return json({ error: 'login_required' }, 401);
    if (req.method === 'POST') {
      const b = await readJson(req);
      const spec = b.spec;
      const raw = JSON.stringify(spec || null);
      if (!spec || typeof spec !== 'object' || !spec.root || raw.length > 120000) return json({ error: 'Nothing to share.' }, 400);
      const recent = await redis('GET', 'gshare:' + s.sub);
      if (recent) return json({ error: 'Please wait a minute before sharing another GUI.' }, 429);
      await redis('SET', 'gshare:' + s.sub, '1', 'EX', 60);
      const id = crypto.randomBytes(6).toString('base64url'), created = Date.now();
      const g = { id, acct: s.sub, name: clean(spec.name, 40) || 'GUI', brief: clean(b.brief, 300), style: clean(b.style, 30), created, spec };
      await redis('SET', 'gs:' + id, JSON.stringify(g));
      await redis('ZADD', 'guis:recent', created, id);
      return json({ id });
    }
    if (req.method === 'DELETE') {
      const id = url.searchParams.get('id');
      const raw = id && await redis('GET', 'gs:' + id);
      const g = raw && JSON.parse(raw);
      if (!g || (g.acct !== s.sub && !isAdmin(s.sub))) return json({ error: 'Not found.' }, 404);
      await redis('ZREM', 'guis:recent', id); await redis('DEL', 'gs:' + id);
      return json({ ok: true });
    }
    return json({ error: 'Method not allowed' }, 405);
  } catch (e) {
    return json({ error: 'Server error' }, 500);
  }
};

export const config = { path: '/api/guis' };
