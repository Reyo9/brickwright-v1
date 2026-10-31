// /b/<id> — the Explore page, but with link-preview tags (Discord, Twitter/X, WhatsApp…)
// filled in for that build: its title, maker, description and snapshot image.
import { redis } from '../lib/core.mjs';

const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

export default async (req) => {
  const url = new URL(req.url);
  const origin = url.origin;
  const page = await fetch(origin + '/explore.html').then((r) => r.text());
  const id = decodeURIComponent(url.pathname.split('/')[2] || '').replace(/[^A-Za-z0-9_-]/g, '').slice(0, 40);
  let build = null;
  try { const raw = id && await redis('GET', 'build:' + id); build = raw ? JSON.parse(raw) : null; } catch (e) {}
  if (!build) return new Response(page, { headers: { 'content-type': 'text/html; charset=utf-8' } });

  const title = (build.title || 'A Brickwright build') + ' — by ' + (build.name || 'a builder');
  const desc = (build.brief ? build.brief.slice(0, 180) : 'A studded Roblox model made with Brickwright.') +
    (build.parts ? ' · ' + build.parts + ' parts' : '') + ' · Spin it in 3D, copy the script or remix it.';
  const img = build.hasThumb ? origin + '/api/thumb?id=' + encodeURIComponent(id) : origin + '/og.png';
  const tags = [
    '<meta property="og:type" content="website">',
    '<meta property="og:site_name" content="Brickwright">',
    '<meta property="og:url" content="' + esc(origin + '/b/' + id) + '">',
    '<meta property="og:title" content="' + esc(title) + '">',
    '<meta property="og:description" content="' + esc(desc) + '">',
    '<meta property="og:image" content="' + esc(img) + '">',
    '<meta name="twitter:card" content="summary_large_image">',
    '<meta name="twitter:title" content="' + esc(title) + '">',
    '<meta name="twitter:description" content="' + esc(desc) + '">',
    '<meta name="twitter:image" content="' + esc(img) + '">',
    '<meta name="theme-color" content="#ff6b35">',
  ].join('\n');
  const html = page
    .replace(/<title>[^<]*<\/title>/, '<title>' + esc(title) + '</title>')
    .replace(/<meta (property|name)="(og:[a-z_]+|twitter:[a-z]+)" content="[^"]*">\n?/g, '')
    .replace(/<meta name="theme-color" content="[^"]*">/, '')
    .replace('</head>', tags + '\n</head>');
  return new Response(html, { headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'public, max-age=300' } });
};

export const config = { path: '/b/*' };
