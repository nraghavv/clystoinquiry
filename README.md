# Clysto — Student Founders Program

A static (no build step) application form + admin dashboard, backed by
Supabase. Built as a completely separate project from the Clysto
inquiries site — deploy it to its own URL/hosting independently.

## Files

- `index.html` — the public 6-step application form (autosaves progress
  to localStorage as applicants fill it in).
- `admin/index.html` — the admin dashboard: login, sidebar with a full
  pipeline (Pending / Shortlisted / Interview / Accepted / Rejected /
  Archived), stat cards, searchable + filterable applications table,
  quick actions (Shortlist / Accept / Reject) right in the row, a full
  detail drawer with all submitted fields, editable internal notes +
  reviewer, and delete with confirmation.
- `supabase-config.js` — the file you edit with your Supabase project
  URL + anon key.
- `migrations/002_create_student_founders_table.sql` — schema, indexes,
  RLS policies, and a stats view. Safe to re-run — it drops any
  existing version of this table first, then rebuilds clean.
- `vercel.json` — routes `/admin` correctly on Vercel's static hosting
  (this was a real issue on the Clysto inquiries deploy — included
  here from the start so it isn't hit again).

## Setup

### 1. Supabase
You can reuse your **existing Clysto Supabase project** (just adds a
new table alongside `inquiries`), or spin up a fresh project — either
works.

1. SQL Editor → paste the full contents of
   `migrations/002_create_student_founders_table.sql` → Run.
2. Authentication → Users → **Create user** with the email/password
   you'll use to log into this dashboard (can be the same admin login
   as Clysto, or a different one — your call).
3. Settings → API Keys → copy your **Project URL** and **anon public**
   key into `supabase-config.js`.

### 2. Test locally

```bash
npx serve .
```

Form at `/`, dashboard at `/admin`.

### 3. Deploy — as its own separate project

Push this folder to its **own GitHub repo** (separate from the Clysto
inquiries repo), then:

- **Vercel**: Import the repo → Framework Preset: **Other** → leave
  Build Command / Output Directory blank → Deploy.
- **Netlify**: same idea — no framework, no build command.

You'll get an independent URL (e.g. `student-founders.vercel.app`, or
point a subdomain like `founders.clysto.net` at it later).

## Notes

- Design language, fonts, colors, buttons, cards, and animations were
  copied directly from the existing Clysto inquiry form — nothing here
  was redesigned.
- The `help_needed` field is stored as a comma-separated string (same
  pattern as `services` in the inquiries table) rather than a separate
  join table, to keep this dependency-free and simple to query/export.
- `reviewed_by` is a free-text field, not a dropdown tied to a real
  admin-users table — fine for a small reviewing team; worth revisiting
  if you add multiple reviewers with real accounts later.
