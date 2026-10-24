// Explore: shared builds.
//   GET    /api/builds?sort=recent|top&offset=N   -> list (no scripts)
//   GET    /api/builds?id=X                       -> one build incl. script (+ whether you liked it)
//   POST   /api/builds  {title, name, brief, script, detail, thumb}  -> share (signed in)
//   POST   /api/builds  {like: id}                -> toggle like (signed in)
//   DELETE /api/builds?id=X                       -> delete your own build
import crypto from 'crypto';
import { json, readJson, readSession, redis } from '../lib/core.mjs';

const PAGE = 24;
const clean = (s, max) => String(s || '').replace(/[\u0000-\u001f<>]/g, '').replace(/\s+/g, ' ').trim().slice(0, max);

async function summary(id) {
  const raw = await redis('GET', 'build:' + id);
  if (!raw) return null;
  const b = JSON.parse(raw);
  const likes = await redis('SCARD', 'likes:' + id);
  return { id: b.id, title: b.title, name: b.name, detail: b.detail, parts: b.parts || null, created: b.created, likes: likes || 0, hasThumb: !!b.hasThumb };
}

export default async (req) => {
  const url = new URL(req.url);
  const s = readSession(req);
  try {
    if (req.method === 'GET') {
      const id = url.searchParams.get('id');
      if (id) {
        const raw = await redis('GET', 'build:' + id);
        if (!raw) return json({ error: 'Build not found.' }, 404);
        const b = JSON.parse(raw);
        const likes = await redis('SCARD', 'likes:' + id);
        const liked = s ? !!(await redis('SISMEMBER', 'likes:' + id, s.sub)) : false;
        return json({ id: b.id, title: b.title, name: b.name, brief: b.brief, detail: b.detail, script: b.script, parts: b.parts,
          created: b.created, likes: likes || 0, liked, mine: !!(s && s.sub === b.acct) });
      }
      const sort = url.searchParams.get('sort') === 'top' ? 'builds:top' : 'builds:recent';
      const offset = Math.max(0, parseInt(url.searchParams.get('offset') || '0', 10) || 0);
      const ids = (await redis('ZREVRANGE', sort, offset, offset + PAGE - 1)) || [];
      const items = (await Promise.all(ids.map(summary))).filter(Boolean);
      const total = await redis('ZCARD', sort);
      return json({ items, next: offset + PAGE < total ? offset + PAGE : null, total });
    }

    if (!s) return json({ error: 'login_required' }, 401);

    if (req.method === 'DELETE') {
      const id = url.searchParams.get('id');
      const raw = id && await redis('GET', 'build:' + id);
      if (!raw) return json({ error: 'Build not found.' }, 404);
      if (JSON.parse(raw).acct !== s.sub) return json({ error: 'You can only delete your own builds.' }, 403);
      await redis('DEL', 'build:' + id); await redis('DEL', 'thumb:' + id); await redis('DEL', 'likes:' + id);
      await redis('ZREM', 'builds:recent', id); await redis('ZREM', 'builds:top', id);
      return json({ ok: true });
    }

    if (req.method === 'POST') {
      const body = await readJson(req);
      if (body.like) {
        const id = String(body.like);
        if (!(await redis('GET', 'build:' + id))) return json({ error: 'Build not found.' }, 404);
        const had = await redis('SISMEMBER', 'likes:' + id, s.sub);
        if (had) await redis('SREM', 'likes:' + id, s.sub); else await redis('SADD', 'likes:' + id, s.sub);
        const likes = (await redis('SCARD', 'likes:' + id)) || 0;
        await redis('ZADD', 'builds:top', likes, id);
        return json({ liked: !had, likes });
      }

      const title = clean(body.title, 60);
      const name = clean(body.name, 24) || 'Anonymous builder';
      const brief = clean(body.brief, 500);
      const script = String(body.script || '');
      const detail = ['quick', 'standard', 'detailed'].includes(body.detail) ? body.detail : 'standard';
      if (title.length < 3) return json({ error: 'Give your build a title (at least 3 characters).' }, 400);
      if (script.length < 40 || script.length > 150000 || !/Instance\.new/.test(script)) return json({ error: 'That doesn’t look like a Brickwright script.' }, 400);
      const thumb = String(body.thumb || '');
      if (thumb && (!/^data:image\/(webp|jpeg|png);base64,/.test(thumb) || thumb.length > 300000)) return json({ error: 'Snapshot image is invalid or too large.' }, 400);

      const dayKey = 'shares:' + s.sub + ':' + new Date().toISOString().slice(0, 10);
      const n = await redis('INCR', dayKey); await redis('EXPIRE', dayKey, 86400);
      if (n > 15) return json({ error: 'You’ve shared a lot today — try again tomorrow.' }, 429);

      const id = crypto.randomBytes(6).toString('base64url');
      const created = Date.now();
      const parts = Number.isFinite(+body.parts) ? Math.max(0, Math.min(100000, Math.round(+body.parts))) : null;
      await redis('SET', 'build:' + id, JSON.stringify({ id, acct: s.sub, title, name, brief, script, detail, parts, created, hasThumb: !!thumb }));
      if (thumb) await redis('SET', 'thumb:' + id, thumb);
      await redis('ZADD', 'builds:recent', created, id);
      await redis('ZADD', 'builds:top', 0, id);
      return json({ id });
    }
    return json({ error: 'Method not allowed' }, 405);
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
};

export const config = { path: '/api/builds' };
