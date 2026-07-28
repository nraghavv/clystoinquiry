# Clysto Inquiry System

A static (no build step) inquiry form + admin dashboard, backed by Supabase.

## What this is

- `index.html` — your existing inquiry form, unchanged visually. The submit
  handlers now write directly to Supabase instead of FormSubmit.
- `admin/index.html` — a new admin dashboard: login, sidebar (Dashboard /
  Grow With Us / Partnerships / General), summary cards, searchable +
  filterable submission lists, a detail drawer, mark-as-read, delete,
  and pagination.
- `supabase-config.js` — the only file you need to edit. Holds your
  Supabase project URL and anon key, used by both the form and the
  dashboard.
- `migrations/001_create_inquiries_table.sql` — the database schema (this
  was already correct from the earlier session and is used as-is).

There is no Next.js, no build step, no `node_modules`. Every file here can
be opened directly or hosted on any static file host.

## Setup

### 1. Create a Supabase project
Go to https://supabase.com → New Project. Save your database password.

### 2. Run the migration
Supabase Dashboard → **SQL Editor** → paste the full contents of
`migrations/001_create_inquiries_table.sql` → Run. This creates the
`inquiries` table, indexes, and Row Level Security policies:
- Anyone can `INSERT` (public form submissions)
- Only authenticated users can `SELECT` / `UPDATE` / `DELETE` (admin dashboard)

### 3. Enable email auth + create your admin login
Authentication → Providers → make sure **Email** is on.
Authentication → Users → **Create user** → enter the email/password you'll
use to log into `/admin`.

### 4. Fill in `supabase-config.js`
Settings → API → copy your **Project URL** and **anon public** key into:

```js
window.SUPABASE_CONFIG = {
  url: "https://your-project-ref.supabase.co",
  anonKey: "eyJhbGc..."
};
```

The anon key is safe to ship in client-side code — it's constrained by the
RLS policies above. Never put the `service_role` key in this file or in
any client-side code.

### 5. Test locally
Any static server works, e.g.:

```bash
npx serve .
```

Visit the form at `/` and the dashboard at `/admin`.

## Deployment

Push this folder to GitHub and deploy on Vercel/Netlify as a **static
site** (no framework preset needed — there's no build command). Or drag
the folder straight into Netlify's manual deploy. `supabase-config.js` can
ship as-is since it only contains the public anon key.

## Notes on what changed from the previous session

- The earlier session had scaffolded a full Next.js + Prisma-style project
  (package.json, tsconfig, next.config.ts) but no actual source files
  (`src/app/page.tsx`, admin pages, `lib/supabase.ts`, etc.) were ever
  created — only config and docs existed.
- The real, working asset was a single static HTML file using FormSubmit.
- Given that, this rebuild skips the Next.js layer entirely: same result
  (Supabase-backed form + full admin dashboard), far less surface area to
  maintain or host, and it deploys anywhere without a build step.
- If you'd genuinely prefer a Next.js/React version later (e.g. for
  server-side rendering, a bigger app around this), the current
  `inquiries` table and RLS policies carry over unchanged — only the
  frontend would need porting.

## Future extensions

The schema already has `assigned_to`, `notes`, and `tags` columns ready
for team assignment, internal notes, and tagging when you want them —
no migration needed to start using them from the dashboard.
