# CekCek Marketplace Supabase

This folder contains the database migration and Edge Functions for the CekCek Marketplace.

## Local Setup

```bash
supabase start
supabase db reset
supabase functions serve marketplace-auth --env-file supabase/.env.local
supabase functions serve marketplace --env-file supabase/.env.local
```

## Required Secrets

```bash
supabase secrets set MARKETPLACE_JWT_SECRET=...
supabase secrets set APPLE_TEAM_ID=...
supabase secrets set APPLE_KEY_ID=...
supabase secrets set APPLE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----'
supabase secrets set APPLE_DEVICECHECK_ENV=development
```

For local development only, DeviceCheck verification can be bypassed:

```bash
supabase secrets set MARKETPLACE_SKIP_DEVICE_CHECK=true
```

## Edge Function Routes

- `POST /functions/v1/marketplace-auth/cloudkit-login`
- `GET /functions/v1/marketplace/categories`
- `GET /functions/v1/marketplace/checklists/featured`
- `GET /functions/v1/marketplace/categories/:categoryId/checklists`
- `GET /functions/v1/marketplace/checklists/:id`
- `POST /functions/v1/marketplace/checklists/publish`
- `POST /functions/v1/marketplace/checklists/:id/download`

Set `MarketplaceAPIBaseURL` in the app to the Supabase functions base URL, for example:

```text
https://PROJECT_REF.supabase.co/functions/v1
```
