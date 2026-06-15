-- Migration 004: Dashboard Views

-- ─────────────────────────────────────────────
-- DASHBOARD STATS VIEW
-- Returns aggregate counts used by the dashboard.
-- Filtered in-app based on role; admins query without filters,
-- approvers supply their own uid as approver_id filter.
-- ─────────────────────────────────────────────

CREATE OR REPLACE VIEW report_stats AS
SELECT
    COUNT(*)                                                    AS total,
    COUNT(*) FILTER (WHERE status = 'pending')                  AS pending,
    COUNT(*) FILTER (WHERE status = 'approved')                 AS approved,
    COUNT(*) FILTER (WHERE status = 'rejected')                 AS rejected,
    COUNT(*) FILTER (WHERE report_type = 'UNSAFE_ACTION')       AS unsafe_action,
    COUNT(*) FILTER (WHERE report_type = 'UNSAFE_SITUATION')    AS unsafe_situation,
    COUNT(*) FILTER (WHERE report_type = 'SAFE_OBSERVATION')    AS safe_observation
FROM reports
WHERE status != 'draft';

-- ─────────────────────────────────────────────
-- REPORTS BY DEPARTMENT
-- Used for the bar chart on the dashboard.
-- ─────────────────────────────────────────────

CREATE OR REPLACE VIEW reports_by_department AS
SELECT
    d.id            AS department_id,
    d.name          AS department_name,
    COUNT(r.id)     AS total,
    COUNT(r.id) FILTER (WHERE r.report_type = 'UNSAFE_ACTION')    AS unsafe_action,
    COUNT(r.id) FILTER (WHERE r.report_type = 'UNSAFE_SITUATION') AS unsafe_situation,
    COUNT(r.id) FILTER (WHERE r.report_type = 'SAFE_OBSERVATION') AS safe_observation
FROM departments d
LEFT JOIN reports r
       ON r.department_id = d.id AND r.status != 'draft'
WHERE d.parent_id IS NULL   -- top-level departments only
GROUP BY d.id, d.name
ORDER BY total DESC;

-- ─────────────────────────────────────────────
-- DAILY SUBMISSION TREND
-- Returns daily counts for the last 90 days.
-- Client filters to 7/30/90 day windows.
-- ─────────────────────────────────────────────

CREATE OR REPLACE VIEW report_trend_daily AS
SELECT
    DATE_TRUNC('day', submitted_at)::date   AS day,
    COUNT(*)                                AS total,
    COUNT(*) FILTER (WHERE report_type = 'UNSAFE_ACTION')    AS unsafe_action,
    COUNT(*) FILTER (WHERE report_type = 'UNSAFE_SITUATION') AS unsafe_situation,
    COUNT(*) FILTER (WHERE report_type = 'SAFE_OBSERVATION') AS safe_observation
FROM reports
WHERE
    status != 'draft'
    AND submitted_at >= now() - INTERVAL '90 days'
GROUP BY 1
ORDER BY 1;
