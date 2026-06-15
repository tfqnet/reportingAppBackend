-- Seed 002: Demo Users
-- These are inserted via Supabase Auth; the trigger auto-creates profiles.
-- Run the auth.users inserts via Supabase dashboard or CLI, then run the profile updates below.
--
-- Demo credentials:
--   admin@safereport.dev     / Demo@1234
--   approver@safereport.dev  / Demo@1234
--   user@safereport.dev      / Demo@1234

-- After the auth.users records exist, patch the profiles to set roles & departments:

UPDATE profiles SET
    full_name     = 'Admin User',
    role          = 'admin',
    department_id = '20000000-0000-0000-0000-000000000001',
    company       = 'SafeReport Demo'
WHERE email = 'admin@safereport.dev';

UPDATE profiles SET
    full_name     = 'Approver One',
    role          = 'approver',
    department_id = '20000000-0000-0000-0000-000000000002',
    company       = 'SafeReport Demo'
WHERE email = 'approver@safereport.dev';

UPDATE profiles SET
    full_name     = 'End User',
    role          = 'end_user',
    department_id = '20000000-0000-0000-0000-000000000002',
    company       = 'SafeReport Demo'
WHERE email = 'user@safereport.dev';
