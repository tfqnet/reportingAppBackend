# SafeReport — Backend

Supabase backend for the SafeReport HSSE field reporting mobile app. Contains the full PostgreSQL schema, Row Level Security policies, seed data, dashboard views, and an Expo push notification Edge Function.

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
│   ├── 001_initial_schema.sql   — tables, enums, indexes
│   ├── 002_triggers.sql         — report_number gen, updated_at, auto-profile, audit log
│   ├── 003_storage.sql          — storage bucket setup
│   └── 004_views.sql            — dashboard aggregate views
├── policies/
│   └── rls_policies.sql         — Row Level Security for all tables + storage
├── seed/
│   ├── 001_master_data.sql      — locations, departments, categories, risk factors
│   └── 002_demo_users.sql       — demo account role patches
└── functions/
    └── send-notification/
        └── index.ts             — Expo push notification Edge Function
```

---

## Database Schema

### Core Tables

| Table | Purpose |
|---|---|
| `profiles` | Extends `auth.users` — stores role, department, push token |
| `locations` | Hierarchical site locations (supports sub-locations) |
| `departments` | Hierarchical departments (supports sub-departments) |
| `categories` | Observation categories per report type, hierarchical |
| `risk_factors` | Risk level options (Low / Medium / High / Critical) |
| `reports` | Main report records covering all 4 form steps |
| `report_categories` | Junction: categories selected per report |
| `report_observers` | Additional observers listed on a report |
| `report_attachments` | Photo attachment metadata (files stored in Supabase Storage) |
| `approval_history` | Append-only audit log of every status transition |

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
- Supabase CLI installed (`npm i -g supabase`)

### 1. Run Migrations (in order)

Paste each file into the Supabase SQL editor, or use the CLI:

```bash
supabase db push
```

Manual order if running via SQL editor:

```
migrations/001_initial_schema.sql
migrations/002_triggers.sql
migrations/003_storage.sql
migrations/004_views.sql
```

### 2. Apply RLS Policies

```
policies/rls_policies.sql
```

### 3. Load Seed Data

```
seed/001_master_data.sql
```

### 4. Create Demo Auth Users

Create these accounts in the Supabase dashboard under **Authentication → Users**:

| Email | Password | Role |
|---|---|---|
| `admin@safereport.dev` | `Demo@1234` | admin |
| `approver@safereport.dev` | `Demo@1234` | approver |
| `user@safereport.dev` | `Demo@1234` | end_user |

Then run:

```
seed/002_demo_users.sql
```

### 5. Deploy the Edge Function

```bash
supabase functions deploy send-notification
```

### 6. Wire the Database Webhook

In the Supabase dashboard go to **Database → Webhooks → Create webhook**:

- Table: `reports`
- Event: `UPDATE`
- Type: HTTP Request
- URL: `https://<project-ref>.supabase.co/functions/v1/send-notification`
- Method: POST

### 7. Configure Frontend Environment

Copy these values from your Supabase project settings into the mobile app's `.env.local`:

```
EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
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

## Dashboard Views

Three views are pre-built for the mobile dashboard:

| View | Used For |
|---|---|
| `report_stats` | Stat cards — total, pending, approved, rejected, by type |
| `reports_by_department` | Bar chart — report count per department |
| `report_trend_daily` | Line chart — daily submissions over last 90 days |

**Example queries (Supabase JS client):**

```ts
// Stat cards
const { data } = await supabase.from('report_stats').select('*')

// Department bar chart
const { data } = await supabase.from('reports_by_department').select('*')

// Trend line (client filters to 7/30/90 days)
const { data } = await supabase.from('report_trend_daily').select('*')
```

---

## Push Notification Payload

The `send-notification` Edge Function fires on every `reports` status change and sends:

```json
{
  "to": "<expo-push-token>",
  "title": "...",
  "body": "...",
  "data": {
    "reportId": "<uuid>",
    "screen": "ApprovalQueue | ReportDetail"
  },
  "sound": "default",
  "priority": "high"
}
```

| Event | Recipient | `screen` value |
|---|---|---|
| Status → `pending` | Approver | `ApprovalQueue` |
| Status → `approved` | Submitter | `ReportDetail` |
| Status → `rejected` | Submitter | `ReportDetail` |

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

## Key Design Decisions

- **`report_number` is DB-generated** by trigger (`SR-YYYY-NNNNN`) to avoid client-side race conditions.
- **Profile auto-creation** — a trigger on `auth.users` inserts a `profiles` row on every signup; the frontend does not need to call a separate insert.
- **`approval_history` is append-only** — inserts are handled exclusively by a `SECURITY DEFINER` trigger; no client can insert directly.
- **RLS helper functions** (`is_admin()`, `is_approver_or_admin()`) are `SECURITY DEFINER STABLE` so they are evaluated once per query, not per row.
- **Storage paths encode the report ID** as the first path segment so storage RLS policies can enforce ownership without an extra join table.
