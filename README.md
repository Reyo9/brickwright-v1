# Brickwright — website (Netlify)

## What's here
- `public/` — the site: `index.html`, `app.css`, `app.js`, `core.js` (prompt + parser + renderer shared with the Claude version), `vendor/` (three.js, Lua runtime, Roblox preview prelude), `showcase.lua` (hero model)
- `netlify/functions/` — the backend:
  - `otp-send` / `otp-verify` — Gmail login with a 6-digit code + Cloudflare Turnstile captcha
  - `generate` + `generate-run` (background, up to 15 min) + `job` — AI builds, charged in credits, refunded on failure or Stop
  - `builds` + `thumb` — Explore: share, list, view, like, delete your own
  - `checkout` / `portal` / `stripe-webhook` — Stripe subscriptions
  - `me` — account + credits for the page
- `netlify/lib/config.mjs` — **edit credits, costs, plans, allowed email domains, AI model here**
- `build/extract_core.py` — regenerates `public/core.js` from `brickwright.html` after prompt changes

## Environment variables (Netlify → Site configuration → Environment variables)
| Name | What |
|---|---|
| `AI_API_KEY` | your NVIDIA key (build.nvidia.com) |
| `AI_MODEL` | optional — defaults to `nvidia/nemotron-3.5-super-vl-120b-a12b` |
| `AI_BASE_URL` | optional — defaults to `https://integrate.api.nvidia.com/v1` (any OpenAI-compatible API works) |
| `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` | from a free Upstash Redis database (upstash.com) |
| `SESSION_SECRET` | any long random text (40+ characters) |
| `GMAIL_USER`, `GMAIL_APP_PASSWORD` | Gmail that sends login codes + its Google "App password" |
| `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY` | Cloudflare → Turnstile → add your site |
| `STRIPE_SECRET_KEY` | later — Stripe → Developers → API keys |
| `STRIPE_WEBHOOK_SECRET` | later — from the webhook endpoint `https://YOUR-SITE.netlify.app/api/stripe-webhook` (events: checkout.session.completed, customer.subscription.*, invoice.paid) |
| `STRIPE_PRICE_WEEKLY` / `STRIPE_PRICE_MONTHLY` / `STRIPE_PRICE_YEARLY` | later — your `price_...` IDs; plans without one show "Coming soon" |

Redeploy after changing any of these.
