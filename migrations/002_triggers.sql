-- Migration 002: Triggers and Functions

-- ─────────────────────────────────────────────
-- AUTO-GENERATE report_number
-- Format: SR-YYYY-NNNNN (sequential per year)
-- ─────────────────────────────────────────────

CREATE SEQUENCE IF NOT EXISTS report_number_seq START 1;

CREATE OR REPLACE FUNCTION generate_report_number()
RETURNS TRIGGER AS $$
DECLARE
    year_str text;
    seq_val  bigint;
BEGIN
    IF NEW.report_number IS NOT NULL THEN
        RETURN NEW;
    END IF;

    year_str := to_char(now(), 'YYYY');
    seq_val  := nextval('report_number_seq');
    NEW.report_number := 'SR-' || year_str || '-' || lpad(seq_val::text, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_report_number
    BEFORE INSERT ON reports
    FOR EACH ROW
    EXECUTE FUNCTION generate_report_number();

-- ─────────────────────────────────────────────
-- KEEP updated_at CURRENT
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reports_updated_at
    BEFORE UPDATE ON reports
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- ─────────────────────────────────────────────
-- SET submitted_at / approved_at / rejected_at
-- automatically on status transitions
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_report_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'pending' AND OLD.status IS DISTINCT FROM 'pending' THEN
        NEW.submitted_at := now();
    END IF;

    IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
        NEW.approved_at := now();
    END IF;

    IF NEW.status = 'rejected' AND OLD.status IS DISTINCT FROM 'rejected' THEN
        NEW.rejected_at := now();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_report_status_timestamps
    BEFORE UPDATE ON reports
    FOR EACH ROW
    EXECUTE FUNCTION set_report_timestamps();

-- ─────────────────────────────────────────────
-- AUTO-CREATE PROFILE on new auth.user signup
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ─────────────────────────────────────────────
-- APPROVAL HISTORY — auto-log on status change
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_approval_history()
RETURNS TRIGGER AS $$
DECLARE
    action_taken approval_action;
BEGIN
    -- Only log meaningful status transitions
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    CASE NEW.status
        WHEN 'pending'  THEN
            action_taken := CASE WHEN OLD.status = 'rejected' THEN 'resubmitted' ELSE 'submitted' END;
        WHEN 'approved' THEN action_taken := 'approved';
        WHEN 'rejected' THEN action_taken := 'rejected';
        ELSE RETURN NEW;
    END CASE;

    INSERT INTO approval_history (report_id, action, actor_id, note)
    VALUES (
        NEW.id,
        action_taken,
        auth.uid(),
        NEW.rejection_reason
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_log_approval_history
    AFTER UPDATE OF status ON reports
    FOR EACH ROW
    EXECUTE FUNCTION log_approval_history();
