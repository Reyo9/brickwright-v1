// Serves a shared build's snapshot image: GET /api/thumb?id=X
import { redis } from '../lib/core.mjs';

export default async (req) => {
  const id = new URL(req.url).searchParams.get('id') || '';
  const data = id && await redis('GET', 'thumb:' + id).catch(() => null);
  const m = data && /^data:(image\/(?:webp|jpeg|png));base64,(.+)$/.exec(data);
  if (!m) return new Response('not found', { status: 404 });
  return new Response(Buffer.from(m[2], 'base64'), {
    headers: { 'content-type': m[1], 'cache-control': 'public, max-age=86400, immutable' },
  });
};

export const config = { path: '/api/thumb' };
