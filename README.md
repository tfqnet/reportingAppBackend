# SafeReport — Backend

Supabase PostgreSQL schema, RLS policies, seed data, dashboard views, and Edge Functions for the SafeReport HSSE field reporting mobile app.

---

## Current Status — ✅ MVP Complete (2026-06-15)

| Component | Status |
|---|---|
| Database schema (13 tables + 3 views) | ✅ Live |
| RLS policies | ✅ Applied |
| Seed data (locations, departments, categories, risk factors) | ✅ Loaded |
| Demo accounts (admin / approver / end_user) | ✅ Live |
| Triggers (report number, timestamps, audit log) | ✅ Active |
| Edge Function: `send-notification` | ✅ Deployed |
| Edge Function: `invite-user` | ✅ Deployed |
| Notification trigger via pg_net | ✅ Active |
| Approver dashboard RPC functions | ✅ Deployed |
| `.env.example` for frontend | ✅ In repo |

---

## Stack

| Concern | Choice |
|---|---|
| Database | PostgreSQL (via Supabase) |
| Auth | Supabase Auth (email + password) |
| Storage | Supabase Storage |
| Edge Functions | Deno (Supabase Edge Functions) |
| Push Notifications | Expo Push Notification API |

---

## Folder Structure

```
backend/
├── migrations/
│   ├── 001_initial_schema.sql        — all tables, enums, indexes
│   ├── 002_triggers.sql              — report_number, updated_at, auto-profile, audit log
│   ├── 003_storage.sql               — storage bucket setup
│   ├── 004_views.sql                 — dashboard aggregate views (admin-scoped)
│   ├── 005_notification_trigger.sql  — pg_net HTTP trigger for push notifications
│   └── 006_approver_rpc.sql          — approver-scoped dashboard RPC functions
├── policies/
│   └── rls_policies.sql              — Row Level Security for all tables + storage
├── seed/
│   ├── 001_master_data.sql           — locations, departments, categories, risk factors
│   └── 002_demo_users.sql            — demo account role patches (run after Auth users created)
└── functions/
    ├── send-notification/
    │   └── index.ts                  — Expo push notification Edge Function
    └── invite-user/
        └── index.ts                  — Admin invite user Edge Function
```

---

## Database Schema

### Core Tables

| Table | Purpose |
|---|---|
| `profiles` | Extends `auth.users` — stores role, department, push token |
| `locations` | Hierarchical site locations (supports sub-locations via `parent_id`) |
| `departments` | Hierarchical departments (supports sub-departments via `parent_id`) |
| `categories` | Observation categories per report type, hierarchical |
| `risk_factors` | Risk level options (Low / Medium / High / Critical) |
| `reports` | Main report records covering all 4 form steps |
| `report_categories` | Junction: categories selected per report |
| `report_observers` | Additional observers listed on a report |
| `report_attachments` | Photo attachment metadata (files in Supabase Storage) |
| `approval_history` | Append-only audit log of every status transition |

### Dashboard Views (admin-scoped)

| View | Used For |
|---|---|
| `report_stats` | Stat cards — total, pending, approved, rejected, by type |
| `reports_by_department` | Bar chart — report count per top-level department |
| `report_trend_daily` | Line chart — daily submissions over last 90 days |

### Approver-Scoped RPC Functions

| Function | Returns |
|---|---|
| `get_approver_stats(p_approver_id)` | Same shape as `report_stats`, filtered to approver queue |
| `get_approver_stats_by_department(p_approver_id)` | Same shape as `reports_by_department` |
| `get_approver_trend(p_approver_id)` | Same shape as `report_trend_daily` |

### Report Types

| Label | Internal Key |
|---|---|
| Unsafe Action | `UNSAFE_ACTION` |
| Unsafe Situation | `UNSAFE_SITUATION` |
| Safe Observation | `SAFE_OBSERVATION` |

### Report Status Flow

```
draft → pending → approved
              ↘ rejected → (resubmitted) → pending
```

### User Roles

| Role | Key |
|---|---|
| End User | `end_user` |
| Approver | `approver` |
| Admin | `admin` |

---

## Deployment Guide

### Prerequisites

- Supabase account and a new project
- Supabase CLI (`brew install supabase/tap/supabase`)

### 1. Run Migrations (in order via SQL Editor)

```
migrations/001_initial_schema.sql
migrations/002_triggers.sql
migrations/003_storage.sql
migrations/004_views.sql
migrations/005_notification_trigger.sql
migrations/006_approver_rpc.sql
```

### 2. Apply RLS Policies

```
policies/rls_policies.sql
```

### 3. Load Seed Data

```
seed/001_master_data.sql
```

### 4. Create Demo Auth Users (optional)

Create in Supabase dashboard **Authentication → Users** then run:

```
seed/002_demo_users.sql
```

| Email | Password | Role |
|---|---|---|
| `admin@safereport.dev` | `Demo@1234` | admin |
| `approver@safereport.dev` | `Demo@1234` | approver |
| `user@safereport.dev` | `Demo@1234` | end_user |

### 5. Deploy Edge Functions

```bash
supabase login
supabase link --project-ref <project-ref>
supabase functions deploy send-notification
supabase functions deploy invite-user
```

### 6. Configure Frontend Environment

Copy into `mobile/.env.local`:

```
EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
EXPO_PUBLIC_APP_ENV=development
```

---

## Row Level Security Summary

| Table | end_user | approver | admin |
|---|---|---|---|
| `profiles` | own row | own row + approver list | all |
| `locations` / `departments` / `categories` / `risk_factors` | read | read | read + write |
| `reports` | own reports | own + assigned queue | all |
| `report_attachments` | own reports | own + assigned | all |
| `approval_history` | own reports | own + assigned | all |

---

## Edge Functions

### `send-notification`

Triggered by a pg_net DB trigger on `reports.status` UPDATE. Sends Expo push notifications to the relevant user.

**Trigger events:**

| Status change | Recipient | Screen |
|---|---|---|
| → `pending` | Approver | `ApprovalQueue` |
| → `approved` | Submitter | `ReportDetail` |
| → `rejected` | Submitter | `ReportDetail` |

**Payload shape:**
```json
{
  "to": "<expo-push-token>",
  "title": "...",
  "body": "...",
  "data": { "reportId": "<uuid>", "screen": "ApprovalQueue | ReportDetail" },
  "sound": "default",
  "priority": "high"
}
```

### `invite-user`

Called by `adminService.inviteUser()` in the mobile app. Requires admin JWT.

**Request:**
```json
{
  "email": "new@example.com",
  "full_name": "New User",
  "role": "end_user | approver | admin",
  "department_id": "<uuid>",
  "company": "ACME Corp"
}
```

**Behaviour:** Verifies caller is admin → creates auth user via `inviteUserByEmail` (sends invite email) → patches profile with role and metadata.

---

## Storage

| Bucket | Access | Max File Size | Allowed Types |
|---|---|---|---|
| `report-attachments` | Private (signed URLs) | 10 MB | jpeg, png, webp, heic |
| `avatars` | Public | 2 MB | jpeg, png, webp |

Upload path format: `{report_id}/{file_name}`

Retrieve with a signed URL:
```ts
const { data } = await supabase.storage
  .from('report-attachments')
  .createSignedUrl(`${reportId}/${fileName}`, 3600)
```

---

## Dashboard Query Reference

### Admin (uses views directly)
```ts
supabase.from('report_stats').select('*')
supabase.from('reports_by_department').select('*')
supabase.from('report_trend_daily').select('*')
```

### Approver (uses RPC functions)
```ts
supabase.rpc('get_approver_stats', { p_approver_id: uid })
supabase.rpc('get_approver_stats_by_department', { p_approver_id: uid })
supabase.rpc('get_approver_trend', { p_approver_id: uid })
```

All shapes are identical so the frontend uses the same chart components for both roles.

---

## Key Design Decisions

- **`report_number` is DB-generated** by trigger (`SR-YYYY-NNNNN`) to avoid client-side race conditions.
- **Profile auto-creation** — a trigger on `auth.users` inserts a `profiles` row on signup; frontend only calls `supabase.auth.signUp()`.
- **`approval_history` is append-only** — inserts handled exclusively by a `SECURITY DEFINER` trigger; no direct client inserts allowed.
- **RLS helpers** (`is_admin()`, `is_approver_or_admin()`) are `SECURITY DEFINER STABLE` — evaluated once per query, not per row.
- **Storage paths encode the report ID** as the first path segment so RLS can enforce ownership without a join table.
- **Dashboard webhook replaced with pg_net** — Supabase free plan lacks the `supabase_functions` schema required for dashboard webhooks; `extensions.http_post()` in a trigger achieves the same result with no dashboard config.
