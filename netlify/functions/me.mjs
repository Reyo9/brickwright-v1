// Account status for the page + public plan list and costs.
import { CONFIG } from '../lib/config.mjs';
import { json, readSession, account, publicPlans, isAdmin } from '../lib/core.mjs';

export default async (req) => {
  const pub = {
    turnstileSiteKey: process.env.TURNSTILE_SITE_KEY || null,
    costs: CONFIG.costs,
    freeCreditsPerMonth: CONFIG.freeCreditsPerMonth,
    allowedEmailDomains: CONFIG.allowedEmailDomains || [],
    plans: publicPlans(),
    billingReady: !!process.env.STRIPE_SECRET_KEY,
  };
  const s = readSession(req);
  if (!s) return json({ signedIn: false, ...pub });
  try {
    const a = await account(s.sub);
    delete a.bucket;
    return json({ signedIn: true, user: { id: s.sub, name: s.name }, ...a, ...pub, admin: isAdmin(s.sub) });
  } catch (e) {
    return json({ signedIn: true, user: { id: s.sub, name: s.name }, error: String(e.message || e), ...pub }, 500);
  }
};

export const config = { path: '/api/me' };
