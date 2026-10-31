// Roblox Studio plugin API.
// Website (signed in):
//   POST /api/plugin {action:'link'}             -> {code}  new plugin code (old one stops working)
//   POST /api/plugin {action:'unlink'}           -> revoke the code
//   POST /api/plugin {action:'saveGui', name, brief, script} -> stores a GUI script so the plugin can insert it
// Plugin (Authorization: Bearer <code>):
//   GET  /api/plugin?list=1                       -> {user, builds:[...], guis:[...]}
//   GET  /api/plugin?build=ID | ?gui=ID           -> {name, script}
import crypto from 'crypto';
import { json, readJson, readSession, redis } from '../lib/core.mjs';

const YEAR = 60 * 60 * 24 * 365, KEEP = 40, TTL = 60 * 60 * 24 * 120;

async function pluginUser(req) {
  const h = req.headers.get('authorization') || '';
  const code = h.replace(/^Bearer\s+/i, '').trim();
  if (!/^bw_[A-Za-z0-9_-]{20,40}$/.test(code)) return null;
  return await redis('GET', 'pt:' + code);
}

export default async (req) => {
  const url = new URL(req.url);
  try {
    if (req.method === 'POST') {
      const s = readSession(req);
      if (!s) return json({ error: 'login_required' }, 401);
      const b = await readJson(req);
      if (b.action === 'link' || b.action === 'unlink') {
        const old = await redis('GET', 'pk:' + s.sub);
        if (old) await redis('DEL', 'pt:' + old);
        await redis('DEL', 'pk:' + s.sub);
        if (b.action === 'unlink') return json({ ok: true });
        const code = 'bw_' + crypto.randomBytes(18).toString('base64url');
        await redis('SET', 'pt:' + code, s.sub, 'EX', YEAR);
        await redis('SET', 'pk:' + s.sub, code, 'EX', YEAR);
        return json({ code });
      }
      if (b.action === 'saveGui') {
        const script = String(b.script || '');
        if (!script.includes('Instance.new') || script.length > 200000) return json({ error: 'Nothing to save.' }, 400);
        const id = crypto.randomBytes(6).toString('base64url'), created = Date.now();
        await redis('SET', 'gi:' + id, JSON.stringify({ acct: s.sub, name: String(b.name || 'GUI').slice(0, 60), brief: String(b.brief || '').slice(0, 300), script, created }), 'EX', TTL);
        await redis('ZADD', 'gh:' + s.sub, created, id);
        const extra = (await redis('ZREVRANGE', 'gh:' + s.sub, KEEP, KEEP + 200)) || [];
        for (const o of extra) { await redis('ZREM', 'gh:' + s.sub, o); await redis('DEL', 'gi:' + o); }
        return json({ id });
      }
      return json({ error: 'Unknown action' }, 400);
    }

    if (req.method === 'GET') {
      const acct = await pluginUser(req);
      if (!acct) return json({ error: 'Plugin code not valid — make a new one at brickwright.netlify.app/plugin' }, 401);
      const bid = url.searchParams.get('build'), gid = url.searchParams.get('gui');
      if (bid || gid) {
        const raw = await redis('GET', (bid ? 'hi:' : 'gi:') + (bid || gid));
        const it = raw && JSON.parse(raw);
        if (!it || it.acct !== acct) return json({ error: 'Not found.' }, 404);
        return json({ name: it.name || it.brief || 'Build', script: it.script });
      }
      const load = async (zkey, prefix, kind) => {
        const ids = (await redis('ZREVRANGE', zkey, 0, 29)) || [];
        const out = [];
        for (const id of ids) {
          const raw = await redis('GET', prefix + id);
          if (!raw) continue;
          const it = JSON.parse(raw);
          out.push({ id, kind, name: (it.name || it.brief || 'Untitled').slice(0, 60), created: it.created, parts: it.parts || null });
        }
        return out;
      };
      const [builds, guis] = await Promise.all([load('hist:' + acct, 'hi:', 'build'), load('gh:' + acct, 'gi:', 'gui')]);
      return json({ builds, guis });
    }
    return json({ error: 'Method not allowed' }, 405);
  } catch (e) {
    return json({ error: 'Server error' }, 500);
  }
};

export const config = { path: '/api/plugin' };
