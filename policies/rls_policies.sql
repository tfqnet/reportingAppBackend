-- RLS Policies for SafeReport
-- Apply after running migrations 001-003

-- ─────────────────────────────────────────────
-- Enable RLS on all tables
-- ─────────────────────────────────────────────

ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_factors      ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports           ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_observers  ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_history  ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────
-- HELPER: role check functions
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin' AND is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_approver_or_admin()
RETURNS boolean AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role IN ('approver', 'admin') AND is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─────────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────────

-- Users can read their own profile; approvers/admins can read all active profiles
CREATE POLICY "profiles_select_own"
    ON profiles FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "profiles_select_approvers_list"
    ON profiles FOR SELECT
    USING (
        role = 'approver'
        AND is_active = true
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_active = true)
    );

CREATE POLICY "profiles_select_all_for_admin"
    ON profiles FOR SELECT
    USING (is_admin());

CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_admin"
    ON profiles FOR UPDATE
    USING (is_admin());

CREATE POLICY "profiles_insert_admin"
    ON profiles FOR INSERT
    WITH CHECK (is_admin() OR id = auth.uid()); -- trigger creates profile on signup

-- ─────────────────────────────────────────────
-- MASTER DATA — read-only for all authenticated users
-- ─────────────────────────────────────────────

CREATE POLICY "locations_select_all"
    ON locations FOR SELECT
    USING (auth.uid() IS NOT NULL AND is_active = true);

CREATE POLICY "locations_admin_all"
    ON locations FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "departments_select_all"
    ON departments FOR SELECT
    USING (auth.uid() IS NOT NULL AND is_active = true);

CREATE POLICY "departments_admin_all"
    ON departments FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "categories_select_all"
    ON categories FOR SELECT
    USING (auth.uid() IS NOT NULL AND is_active = true);

CREATE POLICY "categories_admin_all"
    ON categories FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "risk_factors_select_all"
    ON risk_factors FOR SELECT
    USING (auth.uid() IS NOT NULL AND is_active = true);

CREATE POLICY "risk_factors_admin_all"
    ON risk_factors FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ─────────────────────────────────────────────
-- REPORTS
-- ─────────────────────────────────────────────

-- End users see reports they submitted or are on behalf of
CREATE POLICY "reports_select_own"
    ON reports FOR SELECT
    USING (
        submitted_by = auth.uid()
        OR on_behalf_of = auth.uid()
    );

-- Approvers see reports assigned to them
CREATE POLICY "reports_select_approver_queue"
    ON reports FOR SELECT
    USING (
        approver_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('approver', 'admin') AND is_active = true
        )
    );

-- Admins see everything
CREATE POLICY "reports_select_admin"
    ON reports FOR SELECT
    USING (is_admin());

-- Any authenticated active user can insert reports
CREATE POLICY "reports_insert"
    ON reports FOR INSERT
    WITH CHECK (
        submitted_by = auth.uid()
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_active = true)
    );

-- Users can update their own draft/rejected reports
CREATE POLICY "reports_update_own_draft"
    ON reports FOR UPDATE
    USING (
        submitted_by = auth.uid()
        AND status IN ('draft', 'rejected')
    )
    WITH CHECK (submitted_by = auth.uid());

-- Approvers can update status of reports assigned to them
CREATE POLICY "reports_update_approver"
    ON reports FOR UPDATE
    USING (
        approver_id = auth.uid()
        AND status = 'pending'
        AND EXISTS (
            SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('approver', 'admin') AND is_active = true
        )
    );

-- Admins can update any report
CREATE POLICY "reports_update_admin"
    ON reports FOR UPDATE
    USING (is_admin());

-- ─────────────────────────────────────────────
-- REPORT CATEGORIES (junction)
-- ─────────────────────────────────────────────

-- Mirrors report access — if you can see the report, you can see its categories
CREATE POLICY "report_categories_select"
    ON report_categories FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND (
            submitted_by = auth.uid()
            OR on_behalf_of = auth.uid()
            OR approver_id = auth.uid()
        ))
        OR is_admin()
    );

CREATE POLICY "report_categories_insert"
    ON report_categories FOR INSERT
    WITH CHECK (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND submitted_by = auth.uid())
    );

CREATE POLICY "report_categories_delete"
    ON report_categories FOR DELETE
    USING (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND submitted_by = auth.uid() AND status IN ('draft', 'rejected'))
        OR is_admin()
    );

-- ─────────────────────────────────────────────
-- REPORT OBSERVERS
-- ─────────────────────────────────────────────

CREATE POLICY "report_observers_select"
    ON report_observers FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND (
            submitted_by = auth.uid()
            OR on_behalf_of = auth.uid()
            OR approver_id = auth.uid()
        ))
        OR is_admin()
    );

CREATE POLICY "report_observers_insert"
    ON report_observers FOR INSERT
    WITH CHECK (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND submitted_by = auth.uid())
    );

-- ─────────────────────────────────────────────
-- REPORT ATTACHMENTS
-- ─────────────────────────────────────────────

CREATE POLICY "report_attachments_select"
    ON report_attachments FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND (
            submitted_by = auth.uid()
            OR on_behalf_of = auth.uid()
            OR approver_id = auth.uid()
        ))
        OR is_admin()
    );

CREATE POLICY "report_attachments_insert"
    ON report_attachments FOR INSERT
    WITH CHECK (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND submitted_by = auth.uid())
    );

CREATE POLICY "report_attachments_delete"
    ON report_attachments FOR DELETE
    USING (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND submitted_by = auth.uid() AND status IN ('draft', 'rejected'))
        OR is_admin()
    );

-- ─────────────────────────────────────────────
-- APPROVAL HISTORY
-- ─────────────────────────────────────────────

CREATE POLICY "approval_history_select"
    ON approval_history FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM reports WHERE id = report_id AND (
            submitted_by = auth.uid()
            OR on_behalf_of = auth.uid()
            OR approver_id = auth.uid()
        ))
        OR is_admin()
    );

-- Inserts are handled only by the trigger (SECURITY DEFINER); direct inserts blocked

-- ─────────────────────────────────────────────
-- STORAGE POLICIES
-- ─────────────────────────────────────────────

-- report-attachments: uploader owns the object; approver/admin can read
CREATE POLICY "storage_attachments_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'report-attachments'
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "storage_attachments_select"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'report-attachments'
        AND (
            -- path format: {report_id}/{file_name}
            EXISTS (
                SELECT 1 FROM reports r
                WHERE r.id::text = split_part(name, '/', 1)
                  AND (
                      r.submitted_by = auth.uid()
                      OR r.on_behalf_of = auth.uid()
                      OR r.approver_id = auth.uid()
                  )
            )
            OR is_admin()
        )
    );

CREATE POLICY "storage_attachments_delete"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'report-attachments'
        AND (
            EXISTS (
                SELECT 1 FROM reports r
                WHERE r.id::text = split_part(name, '/', 1)
                  AND r.submitted_by = auth.uid()
                  AND r.status IN ('draft', 'rejected')
            )
            OR is_admin()
        )
    );

-- avatars: public read, own write
CREATE POLICY "storage_avatars_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid() IS NOT NULL
        AND split_part(name, '/', 1) = auth.uid()::text
    );

CREATE POLICY "storage_avatars_update"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars'
        AND split_part(name, '/', 1) = auth.uid()::text
    );
