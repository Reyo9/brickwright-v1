// ============================================================================
//  Brickwright credits & plans — EDIT THIS FILE to change prices and amounts.
// ============================================================================
export const CONFIG = {
  // Every signed-in free user gets this many credits each calendar month (resets on the 1st, UTC).
  freeCreditsPerMonth: 320,

  // Email login: only these domains may sign up ([] = any). Gmail dots/+tags are merged into one account.
  allowedEmailDomains: ['gmail.com'],
  // At most this many NEW accounts per network (IP address) per day — limits alt farming.
  maxNewAccountsPerIpPerDay: 3,
  // ...and at most this many in any 30 days from the same network.
  maxNewAccountsPerIpPer30Days: 4,
  // At most this many accounts can ever be created from the same browser/device.
  maxAccountsPerDevice: 2,
  // Free credits are also capped per network per month, shared by every FREE account on it
  // (paid plans and admins are never limited by this). 640 = two people's worth.
  freeCreditsPerNetworkPerMonth: 640,

  // What each action costs.
  costs: { quick: 10, standard: 35, detailed: 75, revise: 10, rig: 30, animate: 45, enhance: 3 },

  // Output cap per detail level (reasoning models also spend some of this on thinking).
  maxTokens: { quick: 16000, standard: 24000, detailed: 40000 },

  // Default AI: NVIDIA Nemotron (free endpoint, OpenAI-compatible). Override with AI_BASE_URL / AI_MODEL.
  aiBaseUrl: 'https://integrate.api.nvidia.com/v1',
  aiModel: 'nvidia/nemotron-3.5-super-vl-120b-a12b',

  // Paid plans (Stripe). Create a recurring Price for each in your Stripe dashboard and put its ID
  // (price_...) in Netlify's environment variables under the name shown. A plan without a price ID
  // shows "Coming soon". `price` / `label` are only display text — keep them matching Stripe.
  //   per: 'period' -> credits refill every billing period (weekly / monthly)
  //   per: 'month'  -> credits refill every calendar month (yearly, so a year isn't spent at once)
  plans: [
    { id: 'weekly',  name: 'Weekly',  price: '$2.99 / week',  credits: 750,  per: 'period', label: '750 credits every week',
      priceEnv: 'STRIPE_PRICE_WEEKLY' },
    { id: 'monthly', name: 'Monthly', price: '$7.99 / month', credits: 3500, per: 'period', label: '3,500 credits every month',
      priceEnv: 'STRIPE_PRICE_MONTHLY' },
    { id: 'yearly',  name: 'Yearly',  price: '$79.90 / year', credits: 3500, per: 'month',  label: '3,500 credits every month · 2 months free',
      priceEnv: 'STRIPE_PRICE_YEARLY' },
  ],
};

export function planPriceId(plan) { return process.env[plan.priceEnv] || null; }
export function planByPriceId(priceId) { return CONFIG.plans.find((p) => planPriceId(p) && planPriceId(p) === priceId) || null; }
