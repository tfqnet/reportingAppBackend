# SafeReport — Progress Tracker

> Used by the frontend (mobile/) and backend sessions to log progress and flag blockers or dependencies for the other side.

---

## Session Plan

| Session | Role | Start When |
|---|---|---|
| Backend | Database, migrations, RLS, Edge Functions | ✅ Done |
| Frontend | React Native app development | ✅ Phase 1 done, Phase 2 in progress |
| Tester | Bug logging and end-to-end flow testing | After Phase 3 complete |
| UI | Screen polish, visual design, styling | After Phase 4 complete |
| Architect | Architecture review after each phase | Ongoing |

---

## Project Repositories

| Layer | Repo |
|---|---|
| Backend | https://github.com/tfqnet/reportingAppBackend.git |
| Frontend | https://github.com/tfqnet/reportingAppFrontEnd |

---

## How to Use This File

- Update your section when you **start**, **complete**, or **get blocked on** a phase item
- If you need something from the other side, add it to the **Cross-Team Dependencies** table
- Architect reads this file during phase reviews

Status labels: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked

---

## Supabase Setup — ✅ DONE (2026-06-15)

All migrations executed. 13 tables + 3 views live. Seed data loaded (11 locations, 36 categories, 4 risk factors). Edge Function deployed. pg_net notification trigger active. `.env.example` with real keys in backend repo.

---

## Backend Progress

### Phase 1 — Foundation
- [x] Supabase project created (dev environment) — live at `https://rkgfrhcnhfffmgidnknb.supabase.co`
- [x] Schema migrations written (`profiles`, `locations`, `departments`, `categories`, `risk_factors`) — `migrations/001_initial_schema.sql`
- [x] Schema migrations written (`reports`, `report_categories`, `report_observers`, `report_attachments`, `approval_history`) — `migrations/001_initial_schema.sql`
- [x] RLS policies applied (end_user, approver, admin) — `policies/rls_policies.sql`
- [x] Storage bucket created for photo attachments — `migrations/003_storage.sql`
- [x] Seed data loaded (sample locations, departments, categories per report type) — `seed/001_master_data.sql` (11 locations, 36 categories, 4 risk factors confirmed)
- [x] Supabase anon key + URL shared with frontend (via `.env.example`) — pushed to `reportingAppBackend` repo

### Phase 2 — Report Form Support
- [x] `reports` insert/update confirmed working via Supabase client — schema + RLS done
- [x] `report_attachments` storage upload path confirmed — see dependency #2 below
- [x] `profiles` query for approver selection returns correct role filter — see dependency #3 below
- [x] Auto-generated `report_number` trigger in place — `migrations/002_triggers.sql`

### Phase 3 — Approval & Notifications
- [x] Supabase DB trigger fires on report status change — `migrations/002_triggers.sql` (`trg_log_approval_history`)
- [x] Push notification payload format documented for frontend — see dependency #4 below
- [x] `approval_history` insert on every status change confirmed — trigger handles `submitted`, `approved`, `rejected`, `resubmitted`
- [x] Edge Function `send-notification` deployed to Supabase — live at `rkgfrhcnhfffmgidnknb.supabase.co/functions/v1/send-notification`
- [x] Notification trigger wired via `pg_net` (`migrations/005_notification_trigger.sql`) — fires on every `reports.status` change

### Phase 4 — Dashboard Queries
- [x] Aggregate query for stat cards (total, pending, approved, rejected by type) documented — see dependency #5 below
- [x] Department breakdown query documented — see dependency #5 below
- [x] Trend query (submissions over time) documented — see dependency #5 below

### Pending Action Items (Backend — do before Phase 4 starts)
- [ ] Run `seed/002_demo_users.sql` and confirm 3 test accounts are live (end_user, approver, admin) — needed by Tester session
- [ ] Create approver-scoped dashboard RPC function in Supabase (current views are admin-only) — document query shape in Notes section below so frontend is not blocked during Phase 4

---

## Frontend Progress

### Phase 1 — Foundation ✅ Complete
- [x] Expo bare project scaffolded in `mobile/` — 63 files written (2026-06-15)
- [x] TypeScript configured — strict mode, `@/` path alias
- [x] React Navigation v7 installed and shell navigators created — `RootNavigator`, `UserNavigator`, `ApproverNavigator`, `AdminNavigator`
- [x] Zustand stores created (`authStore`, `reportStore`, `masterDataStore`) — all with MMKV persistence
- [x] Supabase client wired up in `services/supabase.ts`
- [x] Auth flow screens scaffolded (Login, PIN, ForgotPassword)
- [x] `.env.local` configured — real Supabase keys in place (Dep #1 resolved)
- [x] BUG-001 fixed — `UserManagementScreen` now calls `fetchUsers()` from `masterDataService.ts`; no direct Supabase import in screen

### Phase 2 — Report Form ✅ Complete (2026-06-15)
- [x] `ReportTypeSelect` screen done — card picker with color-coded type cards + draft resume banner
- [x] `StepBar` component done — 4-step progress bar with checkmarks for completed steps
- [x] Section 1 — General Info done — all fields: date, location, dept, company, activity, approver, observers
- [x] Section 2 — Observation Detail done — description, stop work toggles + conditional fields, HSE concern
- [x] Section 3 — Categories & Risk Factors done — multi-select checklist, single-select risk factor, remarks (min 3 words)
- [x] Section 4 — Photo Attachments done — camera + gallery picker, preview grid, remove, max 10 photos
- [x] Preview screen done — full read-only summary of all sections with Edit + Submit buttons
- [x] Submit to Supabase working — `reportStore.submitReport()` calls createReport → insertCategories → resizeImage + uploadAttachment → submitReport
- [x] Offline draft (MMKV persist) working — `saveDraft()` called on each Next press; draft key stored; resume banner on ReportTypeSelect
- [x] `ReportStackNavigator` added — dedicated stack navigator for form flow nested inside UserNavigator NewReport tab
- [x] BUG-002 fixed — `uploadAttachment` bucket corrected from `'attachments'` to `'report-attachments'`, path corrected from `reports/{id}/...` to `{id}/...`
- [x] `resizeImage()` added to `reportService.ts` — uses `expo-image-manipulator`, max 1920px, JPEG 0.8 quality, called before every upload

### Phase 3 — Listing & Approval
- [ ] `MyReports` screen done
- [ ] `AllReports` + `FilterSheet` done
- [ ] `ReportDetail` screen done
- [ ] `ApprovalQueue` screen done
- [ ] Approve / reject modal with note done
- [ ] Push notifications received and handled

### Phase 4 — Dashboard & Admin
- [ ] `Dashboard` stat cards done
- [ ] Pie chart (report type breakdown) done
- [ ] Bar chart (by department) done
- [ ] Line chart (trend over time) done
- [ ] Tablet landscape layout done (`useTablet()` hook)
- [ ] `UserManagement` screen done
- [ ] `MasterData` screen done

### Phase 5 — QA & Polish
- [ ] All 3 report type flows tested end-to-end
- [ ] Tablet layout QA on iPad simulator
- [ ] Offline → online draft sync tested
- [ ] No `console.log` in production paths
- [ ] EAS build: iOS `.ipa` produced
- [ ] EAS build: Android `.apk` produced

---

## Cross-Team Dependencies

| # | Requested By | Needs From | Description | Status |
|---|---|---|---|---|
| 1 | Frontend | Backend | Supabase URL + anon key in `.env.example` | [x] `.env.example` pushed to `reportingAppBackend` repo — copy values into `mobile/.env.local` |
| 2 | Frontend | Backend | Confirm storage bucket name for photo uploads | [x] bucket name: **`report-attachments`** · path format: `{report_id}/{file_name}` · max 10 MB per file · allowed types: jpeg, png, webp, heic |
| 3 | Frontend | Backend | Approver list query — confirm `profiles` filter by role | [x] query: `.from('profiles').select('id, full_name, department_id').eq('role', 'approver').eq('is_active', true)` |
| 4 | Frontend | Backend | Push notification payload schema (fields + event types) | [x] see Notes section below |
| 5 | Frontend | Backend | Dashboard aggregate query shapes (JSON structure) | [x] see Notes section below |
| 6 | Backend | Frontend | Confirm image upload size limit frontend enforces before upload | [x] `reportService.ts` resizes to max 1920px via `expo-image-manipulator` before upload; `MAX_IMAGE_DIMENSION = 1920` in `constants.ts` |

---

## Blockers Log

> Add an entry here whenever work is blocked. Remove it when resolved.

| Date | Team | Blocker | Resolved |
|---|---|---|---|
| — | — | — | — |

---

## Notes & Decisions

> Log any cross-team decisions or clarifications made during development.

| Date | Note |
|---|---|
| 2026-06-15 | **Dep #4 — Push notification `data` payload shape.** The Edge Function (`functions/send-notification/index.ts`) sends: `{ reportId: string, screen: 'ApprovalQueue' \| 'ReportDetail' }`. Frontend should read `notification.request.content.data.reportId` and navigate to the matching screen. |
| 2026-06-15 | **Dep #5 — Dashboard query shapes.** Three Supabase views are ready. (1) **Stat cards**: `.from('report_stats').select('*')` → `{ total, pending, approved, rejected, unsafe_action, unsafe_situation, safe_observation }`. (2) **Bar chart by dept**: `.from('reports_by_department').select('*')` → array of `{ department_id, department_name, total, unsafe_action, unsafe_situation, safe_observation }`. (3) **Trend line**: `.from('report_trend_daily').select('*')` → array of `{ day, total, unsafe_action, unsafe_situation, safe_observation }`. Approver should add `.eq('approver_id', uid)` filter on the `reports` table directly for queue-scoped stats — the views are admin-scoped; use separate RPC or filtered query for approver dashboard. |
| 2026-06-15 | **Storage signed URLs.** Bucket `report-attachments` is private. Frontend must call `supabase.storage.from('report-attachments').createSignedUrl(path, 3600)` to get a readable URL for display. Do not expose the raw `storage_path` directly in the UI. |
| 2026-06-15 | **Profile auto-creation.** A DB trigger (`trg_on_auth_user_created`) auto-inserts a row in `profiles` on every `auth.users` insert. Frontend does not need to insert into `profiles` manually after signup — just call `supabase.auth.signUp()`. |
| 2026-06-15 | **Notification trigger via pg_net.** Dashboard webhook unavailable on free plan (schema `supabase_functions` does not exist). Replaced with a PostgreSQL trigger using `extensions.http_post()` via pg_net (`migrations/005_notification_trigger.sql`). Fires automatically on every `reports.status` UPDATE — no dashboard config needed. |
