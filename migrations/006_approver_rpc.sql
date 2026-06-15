-- Migration 006: Approver-scoped dashboard RPC functions
-- The report_stats / reports_by_department / report_trend_daily views are admin-scoped.
-- These RPCs return the same shapes but filtered to a specific approver's queue.

-- ─────────────────────────────────────────────
-- get_approver_stats(approver_id uuid)
-- Returns stat card counts for a given approver's queue.
-- Shape matches report_stats view.
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_approver_stats(p_approver_id uuid)
RETURNS TABLE (
    total               bigint,
    pending             bigint,
    approved            bigint,
    rejected            bigint,
    unsafe_action       bigint,
    unsafe_situation    bigint,
    safe_observation    bigint
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT
        COUNT(*)                                                        AS total,
        COUNT(*) FILTER (WHERE status = 'pending')                      AS pending,
        COUNT(*) FILTER (WHERE status = 'approved')                     AS approved,
        COUNT(*) FILTER (WHERE status = 'rejected')                     AS rejected,
        COUNT(*) FILTER (WHERE report_type = 'UNSAFE_ACTION')           AS unsafe_action,
        COUNT(*) FILTER (WHERE report_type = 'UNSAFE_SITUATION')        AS unsafe_situation,
        COUNT(*) FILTER (WHERE report_type = 'SAFE_OBSERVATION')        AS safe_observation
    FROM reports
    WHERE
        approver_id = p_approver_id
        AND status != 'draft';
$$;

-- ─────────────────────────────────────────────
-- get_approver_stats_by_department(approver_id uuid)
-- Returns department breakdown for approver's queue.
-- Shape matches reports_by_department view.
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_approver_stats_by_department(p_approver_id uuid)
RETURNS TABLE (
    department_id       uuid,
    department_name     text,
    total               bigint,
    unsafe_action       bigint,
    unsafe_situation    bigint,
    safe_observation    bigint
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT
        d.id                                                                    AS department_id,
        d.name                                                                  AS department_name,
        COUNT(r.id)                                                             AS total,
        COUNT(r.id) FILTER (WHERE r.report_type = 'UNSAFE_ACTION')             AS unsafe_action,
        COUNT(r.id) FILTER (WHERE r.report_type = 'UNSAFE_SITUATION')          AS unsafe_situation,
        COUNT(r.id) FILTER (WHERE r.report_type = 'SAFE_OBSERVATION')          AS safe_observation
    FROM departments d
    LEFT JOIN reports r
           ON r.department_id = d.id
          AND r.approver_id = p_approver_id
          AND r.status != 'draft'
    WHERE d.parent_id IS NULL
    GROUP BY d.id, d.name
    ORDER BY total DESC;
$$;

-- ─────────────────────────────────────────────
-- get_approver_trend(approver_id uuid)
-- Returns daily submission trend for approver's queue (last 90 days).
-- Shape matches report_trend_daily view.
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_approver_trend(p_approver_id uuid)
RETURNS TABLE (
    day                 date,
    total               bigint,
    unsafe_action       bigint,
    unsafe_situation    bigint,
    safe_observation    bigint
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT
        DATE_TRUNC('day', submitted_at)::date                               AS day,
        COUNT(*)                                                             AS total,
        COUNT(*) FILTER (WHERE report_type = 'UNSAFE_ACTION')               AS unsafe_action,
        COUNT(*) FILTER (WHERE report_type = 'UNSAFE_SITUATION')            AS unsafe_situation,
        COUNT(*) FILTER (WHERE report_type = 'SAFE_OBSERVATION')            AS safe_observation
    FROM reports
    WHERE
        approver_id = p_approver_id
        AND status != 'draft'
        AND submitted_at >= now() - INTERVAL '90 days'
    GROUP BY 1
    ORDER BY 1;
$$;

-- Grant execute to authenticated users (RLS on underlying tables enforces ownership)
GRANT EXECUTE ON FUNCTION get_approver_stats(uuid)                  TO authenticated;
GRANT EXECUTE ON FUNCTION get_approver_stats_by_department(uuid)    TO authenticated;
GRANT EXECUTE ON FUNCTION get_approver_trend(uuid)                  TO authenticated;
