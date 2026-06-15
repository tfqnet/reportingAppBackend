-- Migration 005: HTTP notification trigger via pg_net
-- Replaces the dashboard webhook (not available on free plan)

-- Enable pg_net extension (available on all Supabase projects)
CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;

-- Trigger function: calls the Edge Function via HTTP on report status change
CREATE OR REPLACE FUNCTION notify_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
BEGIN
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;

  payload := jsonb_build_object(
    'type',       'UPDATE',
    'table',      'reports',
    'record',     row_to_json(NEW)::jsonb,
    'old_record', row_to_json(OLD)::jsonb
  );

  PERFORM extensions.http_post(
    url     := 'https://rkgfrhcnhfffmgidnknb.supabase.co/functions/v1/send-notification',
    body    := payload::text,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrZ2ZyaGNuaGZmZm1naWRua25iIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTQ3ODE0NywiZXhwIjoyMDk3MDU0MTQ3fQ.o30IpFHU3o1TWiVzgSOmhqSQ_KQ8STCQb11DPXmlA7A'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_notify_status_change
  AFTER UPDATE OF status ON reports
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_status_change();
