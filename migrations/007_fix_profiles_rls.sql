-- Migration 007: Fix infinite recursion in profiles RLS (BUG-010)
-- Root cause: is_admin() and is_approver_or_admin() query `profiles` inside
-- a policy on `profiles`, triggering RLS recursion even though they are
-- SECURITY DEFINER. The fix is a get_my_role() helper that reads the role
-- column directly via auth.uid() without triggering row-level policy checks.

-- ─────────────────────────────────────────────
-- Step 1: Drop all existing policies on profiles
-- ─────────────────────────────────────────────

DROP POLICY IF EXISTS "profiles_select_own"             ON profiles;
DROP POLICY IF EXISTS "profiles_select_approvers_list"  ON profiles;
DROP POLICY IF EXISTS "profiles_select_all_for_admin"   ON profiles;
DROP POLICY IF EXISTS "profiles_update_own"             ON profiles;
DROP POLICY IF EXISTS "profiles_update_admin"           ON profiles;
DROP POLICY IF EXISTS "profiles_insert_admin"           ON profiles;

-- ─────────────────────────────────────────────
-- Step 2: Safe role helper — reads profiles without triggering its own RLS
-- SECURITY DEFINER + SET search_path ensures it runs as the function owner
-- (postgres) which bypasses RLS on profiles.
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role::text FROM public.profiles WHERE id = auth.uid();
$$;

-- ─────────────────────────────────────────────
-- Step 3: Recreate profiles policies using get_my_role()
-- No policy calls is_admin() or is_approver_or_admin() on profiles anymore.
-- ─────────────────────────────────────────────

-- Any authenticated user reads their own profile
CREATE POLICY "profiles_select_own"
    ON profiles FOR SELECT
    USING (id = auth.uid());

-- Any authenticated user can see approvers (for the approver picker in the form)
CREATE POLICY "profiles_select_approvers_list"
    ON profiles FOR SELECT
    USING (
        role = 'approver'
        AND is_active = true
        AND auth.uid() IS NOT NULL
    );

-- Admins can read all profiles
CREATE POLICY "profiles_select_all_for_admin"
    ON profiles FOR SELECT
    USING (public.get_my_role() = 'admin');

-- Users can update their own profile (avatar, push_token, etc.)
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Admins can update any profile (role changes, deactivation)
CREATE POLICY "profiles_update_admin"
    ON profiles FOR UPDATE
    USING (public.get_my_role() = 'admin');

-- Profile insert: only via trigger on auth.users signup, or admin
CREATE POLICY "profiles_insert_admin"
    ON profiles FOR INSERT
    WITH CHECK (
        public.get_my_role() = 'admin'
        OR id = auth.uid()
    );
