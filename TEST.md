# SafeReport — Bug & Error Log

> Maintained by the Tester session. Developers check this file for active bugs assigned to them.

---

## How to Use This File

- **Tester** logs every bug found here with full reproduction steps
- **Developer** picks up assigned bugs, updates status, and notes the fix
- **Architect** reviews during phase reviews for patterns or recurring issues

Status labels: `[open]` · `[in progress]` · `[fixed]` · `[wont fix]` · `[needs info]`
Priority: `P1` critical (app crash / data loss) · `P2` high (broken feature) · `P3` medium (wrong behaviour) · `P4` low (cosmetic)

---

## Active Bugs

> No active bugs.

> **Phase 5 QA note (2026-06-15):** Full `src/` scan — zero `console.log` calls, all data-fetching screens have loading/empty/error states, no `any` types in services/stores. One minor naming deviation: store files are `camelCase.ts` instead of `camelCase.store.ts` per PLAN.md Section 13. Not fixed — 17 import sites would need updating; flagged for post-MVP cleanup.

> **GitHub push (2026-06-15):** MVP codebase pushed to `https://github.com/tfqnet/reportingAppFrontEnd` — commit `506a79f`, 70 files, 5,890 insertions. Branch: `main`.

### BUG-010 — RLS infinite recursion on profiles table blocks all logins ⚠️ CRITICAL

| Field | Detail |
|---|---|
| ID | BUG-010 |
| Priority | P1 |
| Status | fixed |
| Phase | Phase 5 |
| Reported by | Architect |
| Assigned to | **Backend** |
| Date reported | 2026-06-15 |
| Date fixed | 2026-06-15 |

**Environment**
- Supabase: `rkgfrhcnhfffmgidnknb.supabase.co`
- Affects all 3 roles — nobody can log in

**Steps to Reproduce**
1. Login with any demo account — spinner shows then app returns to Login
2. Confirmed via direct API: `GET /rest/v1/profiles` with valid user JWT returns:
   `{"code":"42P17","message":"infinite recursion detected in policy for relation \"profiles\""}`

**Expected Result**
Authenticated user reads their own profile row successfully, navigator switches to Home.

**Actual Result**
RLS policy on `profiles` references `profiles` inside itself → infinite recursion → `getCurrentUser()` throws → `clearAuth()` fires → kicked back to Login.

**Fix Notes** *(backend fixes in Supabase Dashboard → Authentication → Policies → profiles)*
The admin-check SELECT policy is querying `profiles` inside a `profiles` policy. Fix with a security definer function:
```sql
-- Step 1: drop all existing policies on profiles
DROP POLICY IF EXISTS "admin_all" ON profiles;
DROP POLICY IF EXISTS "users_own_profile" ON profiles;
-- (drop any others that exist)

-- Step 2: create a security definer helper (avoids recursion)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$;

-- Step 3: recreate policies using the helper
CREATE POLICY "users_read_own_profile" ON profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "users_update_own_profile" ON profiles
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "admin_all_profiles" ON profiles
  FOR ALL USING (public.get_my_role() = 'admin');
```

---

### BUG-009 — expo-notifications crashes on Android without Firebase (FCM)

| Field | Detail |
|---|---|
| ID | BUG-009 |
| Priority | P2 |
| Status | fixed |
| Phase | Phase 5 |
| Reported by | Tester (Android emulator run) |
| Assigned to | Frontend |
| Date reported | 2026-06-15 |
| Date fixed | 2026-06-15 |

**Environment**
- Device: Android Emulator (`Medium_Phone_API_36.1`)
- Error: `FirebaseApp is not initialized in this process com.safereport.app`

**Steps to Reproduce**
1. Run `npm run android`
2. App crashes on launch with Firebase init error

**Expected Result**
App launches without push notification setup blocking startup.

**Actual Result**
Fatal crash — `expo-notifications` plugin requires Firebase on Android.

**Fix Notes**
Removed `expo-notifications` from `app.json` plugins temporarily to unblock local testing. Push notifications are deferred to post-MVP — requires Firebase project + `google-services.json`. Documented in `PLAN.md` Post-MVP section.

---

---

## Bug Template

Copy this when logging a new bug:

```
### BUG-XXX — [Short title]

| Field | Detail |
|---|---|
| ID | BUG-XXX |
| Priority | P1 / P2 / P3 / P4 |
| Status | open |
| Phase | Phase 1 / 2 / 3 / 4 / 5 |
| Reported by | Tester |
| Assigned to | Frontend / Backend |
| Date reported | YYYY-MM-DD |
| Date fixed | — |

**Environment**
- Device: e.g. iPhone 15 Pro / Samsung Galaxy S24 / iPad Pro 12.9"
- OS: e.g. iOS 17.4 / Android 14
- App version / branch: e.g. main / phase-2-branch

**Steps to Reproduce**
1. 
2. 
3. 

**Expected Result**
What should happen.

**Actual Result**
What actually happens.

**Error Log / Screenshot**
Paste error message or attach screenshot path here.

**Fix Notes** *(developer fills this in)*
—
```

---

## Fixed Bugs

> Bugs resolved and verified by tester will be moved here.

| ID | Title | Priority | Fixed by | Date Fixed |
|---|---|---|---|---|
| BUG-001 | Direct Supabase call in UserManagementScreen bypasses service layer | P3 | Frontend | 2026-06-15 |
| BUG-002 | `uploadAttachment` used wrong bucket name and wrong storage path | P2 | Frontend | 2026-06-15 |
| BUG-003 | Inline role check in ReportDetailScreen should be in useRole() hook | P3 | Frontend | 2026-06-15 |
| BUG-004 | Hardcoded `#fff` in Switch thumbColor instead of COLORS constant | P4 | Frontend | 2026-06-15 |
| BUG-005 | Login button unresponsive when app not built natively (Expo Go) | P1 | Frontend | 2026-06-15 |
| BUG-006 | Login validation Alert hidden behind keyboard on iOS | P2 | Frontend | 2026-06-15 |
| BUG-007 | Supabase anon key hardcoded in app.json (security) | P2 | Frontend | 2026-06-15 |
| BUG-008 | Login button shows no feedback on Android emulator | P1 | Frontend | 2026-06-15 |
| BUG-009 | expo-notifications crashes on Android without Firebase (FCM) | P2 | Frontend | 2026-06-15 |
| BUG-010 | RLS infinite recursion on profiles table blocks all logins | P1 | Backend | 2026-06-15 |

---

## Recurring Issues / Patterns

> Architect notes patterns across bugs that may indicate structural problems.

| Pattern | Affected Area | Recommendation |
|---|---|---|
| Wrong Supabase bucket/path constants | `reportService.ts` | All storage bucket names and path patterns should be defined in `constants.ts` as named exports to prevent typos across the codebase |
| Role logic duplicated inline in screens | `screens/listing/` | Create `useRole()` hook once and import it — do not repeat role string comparisons in individual screens |
