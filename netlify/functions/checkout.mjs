// Creates a Stripe Checkout page for a plan and returns its URL.
import { CONFIG, planPriceId } from '../lib/config.mjs';
import { json, readJson, readSession, redis, stripe } from '../lib/core.mjs';

export default async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const s = readSession(req);
  if (!s) return json({ error: 'login_required' }, 401);
  const { plan: planId } = await readJson(req);
  const plan = CONFIG.plans.find((p) => p.id === planId);
  const price = plan && planPriceId(plan);
  if (!price) return json({ error: 'That plan isn’t available yet.' }, 400);
  try {
    const origin = new URL(req.url).origin;
    const customer = await redis('GET', 'cust:' + s.sub);
    const acctRec = JSON.parse((await redis('GET', 'acct:' + s.sub)) || '{}');
    const params = {
      mode: 'subscription',
      line_items: { 0: { price, quantity: 1 } },
      success_url: origin + '/?checkout=success#free',
      cancel_url: origin + '/?checkout=cancel#free',
      client_reference_id: s.sub,
      metadata: { acct: s.sub, plan: plan.id },
      subscription_data: { metadata: { acct: s.sub, plan: plan.id } },
      allow_promotion_codes: 'true',
    };
    if (customer) params.customer = customer;
    else params.customer_email = acctRec.email || s.name;
    const session = await stripe('POST', 'checkout/sessions', params);
    return json({ url: session.url });
  } catch (e) {
    return json({ error: String(e.message || e) }, 500);
  }
};

export const config = { path: '/api/checkout' };
