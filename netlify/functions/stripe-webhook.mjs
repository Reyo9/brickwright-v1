// Stripe tells us here when someone subscribes, renews, changes plan or cancels.
// We store the subscription per account; credits are worked out from it on each request.
import { planByPriceId } from '../lib/config.mjs';
import { json, redis, stripe, verifyStripeSignature } from '../lib/core.mjs';

const iso = (sec) => (sec ? new Date(sec * 1000).toISOString() : null);

async function saveSubscription(sub) {
  const acct = sub.metadata && sub.metadata.acct;
  if (!acct) return;
  const item = sub.items && sub.items.data && sub.items.data[0];
  const priceId = item && item.price && item.price.id;
  const plan = planByPriceId(priceId);
  // newer Stripe API versions keep the billing period on the item, older ones on the subscription
  const start = (item && item.current_period_start) || sub.current_period_start;
  const end = (item && item.current_period_end) || sub.current_period_end;
  await redis('SET', 'cust:' + acct, sub.customer);
  await redis('SET', 'sub:' + acct, JSON.stringify({
    id: sub.id, customer: sub.customer, status: sub.status, planId: plan ? plan.id : null,
    start: iso(start), end: iso(end), cancelAtPeriodEnd: !!sub.cancel_at_period_end,
  }));
}

export default async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const raw = await req.text();
  if (!verifyStripeSignature(raw, req.headers.get('stripe-signature'), process.env.STRIPE_WEBHOOK_SECRET)) {
    return json({ error: 'bad signature' }, 400);
  }
  let ev; try { ev = JSON.parse(raw); } catch (e) { return json({ error: 'bad json' }, 400); }
  try {
    const o = ev.data && ev.data.object;
    if (ev.type === 'checkout.session.completed' && o.mode === 'subscription' && o.subscription) {
      if (o.client_reference_id && o.customer) await redis('SET', 'cust:' + o.client_reference_id, o.customer);
      await saveSubscription(await stripe('GET', 'subscriptions/' + o.subscription));
    } else if (ev.type && ev.type.startsWith('customer.subscription.')) {
      await saveSubscription(o);
    } else if (ev.type === 'invoice.paid') {
      const subRef = o.subscription || (o.parent && o.parent.subscription_details && o.parent.subscription_details.subscription);
      if (subRef) await saveSubscription(await stripe('GET', 'subscriptions/' + (subRef.id || subRef)));
    }
  } catch (e) {
    return json({ error: String(e.message || e) }, 500); // Stripe will retry
  }
  return json({ received: true });
};

export const config = { path: '/api/stripe-webhook' };
