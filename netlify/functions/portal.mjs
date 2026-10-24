// Opens Stripe's customer portal so a subscriber can change plan, update their card, or cancel.
import { json, readSession, redis, stripe } from '../lib/core.mjs';

export default async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  const customer = await redis('GET', 'cust:' + s.sub);
  if (!customer) return json({ error: 'No subscription found for this account.' }, 400);
  try {
    const p = await stripe('POST', 'billing_portal/sessions', { customer, return_url: new URL(req.url).origin + '/#free' });
    return json({ url: p.url });
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
};

export const config = { path: '/api/portal' };
