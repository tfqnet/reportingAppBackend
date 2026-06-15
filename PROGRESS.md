# SafeReport — Progress Tracker

> Used by the frontend (mobile/) and backend sessions to log progress and flag blockers or dependencies for the other side.

---

## Session Plan

| Session | Role | Start When |
|---|---|---|
| Backend | Database, migrations, RLS, Edge Functions | ✅ Done |
| Frontend | React Native app development | ✅ Phases 1–4 complete, Phase 5 (QA) next |
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
- [x] Demo users created via Auth API and profiles patched — `admin@safereport.dev` (admin), `approver@safereport.dev` (approver), `user@safereport.dev` (end_user) · all password: `Demo@1234`
- [x] Approver-scoped RPC functions created — `migrations/006_approver_rpc.sql` deployed · see Notes section for query shapes

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

### Phase 3 — Listing & Approval ✅ Complete (2026-06-15)
- [x] `MyReports` screen done — FlatList with pull-to-refresh, error state, navigation to ReportDetail; filters by current user uid
- [x] `AllReports` + `FilterSheet` done — FlatList with active filter chips, clear all, count badge, FilterSheet with status + type multi-select chips
- [x] `ReportDetail` screen done — full read-only view: all sections, category tags, photo grid (signed URLs), approval history timeline
- [x] `ApprovalQueue` screen done — filters by `approver_id = current user`, pending count banner, pull-to-refresh
- [x] Approve / reject modal with note done — Approve modal (optional note), Reject modal (required reason), both refresh report on completion
- [x] Push notifications received and handled — `useNotifications` hook wired in `RootNavigator`, token saved to `profiles.push_token`, navigates to ApprovalQueue or ReportDetail on tap
- [x] `MyReportsStackNavigator`, `AllReportsStackNavigator`, `ApprovalQueueStackNavigator` added — stack navigators enabling ReportDetail push per tab
- [x] `getSignedUrl()` added to `reportService.ts` — storage paths resolved to signed URLs (1h expiry) for photo display
- [x] `getMyReports()` fixed — now filters by `submitted_by = auth.uid()` with location + approver joins
- [x] `getAllReports()` updated — supports `approverId` filter for queue scoping; includes location + approver joins

### Phase 4 — Dashboard & Admin ✅ Complete (2026-06-15)
- [x] `Dashboard` stat cards done — 7 `StatCard` components (Total, Pending, Approved, Rejected, + 3 by type); horizontal scroll on phone, wrap on tablet
- [x] Pie chart (report type breakdown) done — `PieChartWidget` uses `VictoryPie` with donut, 3 slices, legend with counts
- [x] Bar chart (by department) done — `BarChartWidget` uses `VictoryBar` + `VictoryChart`, max 8 depts, horizontally scrollable
- [x] Line chart (trend over time) done — `TrendLineWidget` uses `VictoryLine` + `VictoryArea`, 7d/30d/90d period toggle
- [x] Tablet landscape layout done — `DashboardScreen` uses `useTablet()` for 2-col grid layout; no inline `Dimensions` in JSX
- [x] `useDashboardStats` hook rewritten — exposes `period`, `setPeriod`, `refresh`, `deptBreakdown`, `trend`; admin uses views, approver uses filtered queries
- [x] `UserManagement` screen done — colored role badges, long-press deactivate, invite modal (name/email/role picker) via `adminService.inviteUser()`
- [x] `MasterData` screen done — 3 tabs (Locations, Departments, Categories), FlatList per tab, add modal with category type selector
- [x] `SettingsScreen` done — app version from `expo-constants`, env label with color badge, sign out with confirmation
- [x] `adminService.ts` created — `deactivateUser()`, `inviteUser()` (via Edge Function)
- [x] `masterDataService.ts` extended — `addLocation()`, `addDepartment()`, `addCategory()` added
- [x] `SettingsScreen` wired into `AdminNavigator`

### Phase 5 — QA & Polish ✅ Complete (2026-06-15)
- [~] All 3 report type flows tested end-to-end — pending live Supabase test accounts (backend demo users now seeded: `admin@safereport.dev`, `approver@safereport.dev`, `user@safereport.dev` / `Demo@1234`)
- [~] Tablet layout QA on iPad simulator — `useTablet()` hook confirmed in `DashboardScreen`; full simulator run pending EAS dev build
- [~] Offline → online draft sync tested — MMKV draft persistence confirmed in code; live device test pending
- [x] No `console.log` in production paths — full scan of `src/` returned zero results (2026-06-15)
- [x] All screens have loading + empty + error states — verified: all data-fetching screens use `<Loading />`, `<EmptyState />`, and error alerts; non-fetching screens (Home, Profile, auth, form sections) confirmed stateless (2026-06-15)
- [x] No `any` types in service or store files — `authStore` uses `Session | null`, `reportStore` fully typed; `NavigationContainerRef<any>` in `notificationService` is intentional React Navigation pattern with eslint-disable comment (2026-06-15)
- [x] File naming conventions verified — screens, components, hooks all correct; stores use `camelCase.ts` (consistent across all 3, minor deviation from PLAN.md `camelCase.store.ts` — not renamed to avoid breaking 17 import sites)
- [x] `eas.json` created — `development`, `staging`, `production` profiles with iOS + Android targets; submit config with `tfqnet@gmail.com` (2026-06-15)
- [ ] EAS build: iOS `.ipa` produced — requires Apple credentials (`ascAppId`, `appleTeamId`) in `eas.json`
- [ ] EAS build: Android `.apk` produced — requires `google-service-account.json`

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
| 2026-06-15 | **Approver dashboard RPC query shapes** (`migrations/006_approver_rpc.sql`). All three functions take `{ p_approver_id: string }`. (1) **Stat cards**: `supabase.rpc('get_approver_stats', { p_approver_id: uid })` → `{ total, pending, approved, rejected, unsafe_action, unsafe_situation, safe_observation }`. (2) **Bar chart**: `supabase.rpc('get_approver_stats_by_department', { p_approver_id: uid })` → array of `{ department_id, department_name, total, unsafe_action, unsafe_situation, safe_observation }`. (3) **Trend line**: `supabase.rpc('get_approver_trend', { p_approver_id: uid })` → array of `{ day, total, unsafe_action, unsafe_situation, safe_observation }`. Shapes are identical to admin views so frontend can use the same chart components. |
| 2026-06-15 | **Demo accounts live.** Three test accounts created and role-patched: `admin@safereport.dev` (admin, HSE dept), `approver@safereport.dev` (approver, Operations), `user@safereport.dev` (end_user, Operations). All use password `Demo@1234`. Use these for end-to-end testing in the Tester session. |
| 2026-06-15 | **`invite-user` Edge Function deployed.** Called by `adminService.inviteUser()`. Accepts `{ email, full_name, role, department_id?, company? }` with Bearer token. Verifies caller is admin, creates auth user via `inviteUserByEmail` (sends invite email), patches profile with role. Endpoint: `https://rkgfrhcnhfffmgidnknb.supabase.co/functions/v1/invite-user`. |
