-- Seed 001: Master Data
-- Locations, Departments, Categories, Risk Factors

-- ─────────────────────────────────────────────
-- LOCATIONS
-- ─────────────────────────────────────────────

INSERT INTO locations (id, name, code) VALUES
    ('10000000-0000-0000-0000-000000000001', 'Main Office',          'MAIN'),
    ('10000000-0000-0000-0000-000000000002', 'Plant A',              'PLANT-A'),
    ('10000000-0000-0000-0000-000000000003', 'Plant B',              'PLANT-B'),
    ('10000000-0000-0000-0000-000000000004', 'Warehouse',            'WH'),
    ('10000000-0000-0000-0000-000000000005', 'Construction Site',    'SITE'),
    ('10000000-0000-0000-0000-000000000006', 'Laboratory',           'LAB'),
    ('10000000-0000-0000-0000-000000000007', 'Loading Bay',          'LB'),
    ('10000000-0000-0000-0000-000000000008', 'Car Park',             'CP');

-- Sub-locations for Plant A
INSERT INTO locations (id, name, code, parent_id) VALUES
    ('10000000-0000-0000-0000-000000000011', 'Plant A — Level 1',   'PLANT-A-L1', '10000000-0000-0000-0000-000000000002'),
    ('10000000-0000-0000-0000-000000000012', 'Plant A — Level 2',   'PLANT-A-L2', '10000000-0000-0000-0000-000000000002'),
    ('10000000-0000-0000-0000-000000000013', 'Plant A — Control Room', 'PLANT-A-CR', '10000000-0000-0000-0000-000000000002');

-- ─────────────────────────────────────────────
-- DEPARTMENTS
-- ─────────────────────────────────────────────

INSERT INTO departments (id, name) VALUES
    ('20000000-0000-0000-0000-000000000001', 'Health, Safety & Environment'),
    ('20000000-0000-0000-0000-000000000002', 'Operations'),
    ('20000000-0000-0000-0000-000000000003', 'Maintenance'),
    ('20000000-0000-0000-0000-000000000004', 'Engineering'),
    ('20000000-0000-0000-0000-000000000005', 'Logistics'),
    ('20000000-0000-0000-0000-000000000006', 'Human Resources'),
    ('20000000-0000-0000-0000-000000000007', 'Finance'),
    ('20000000-0000-0000-0000-000000000008', 'Information Technology'),
    ('20000000-0000-0000-0000-000000000009', 'Quality Assurance'),
    ('20000000-0000-0000-0000-000000000010', 'Security');

-- Sub-departments for Operations
INSERT INTO departments (id, name, parent_id) VALUES
    ('20000000-0000-0000-0000-000000000021', 'Operations — Shift A', '20000000-0000-0000-0000-000000000002'),
    ('20000000-0000-0000-0000-000000000022', 'Operations — Shift B', '20000000-0000-0000-0000-000000000002'),
    ('20000000-0000-0000-0000-000000000023', 'Operations — Shift C', '20000000-0000-0000-0000-000000000002');

-- ─────────────────────────────────────────────
-- CATEGORIES — UNSAFE_ACTION
-- ─────────────────────────────────────────────

INSERT INTO categories (id, report_type, name, sort_order) VALUES
    ('30000000-0000-0000-0000-000000000001', 'UNSAFE_ACTION', 'Personal Protective Equipment (PPE)',   1),
    ('30000000-0000-0000-0000-000000000002', 'UNSAFE_ACTION', 'Tools & Equipment',                     2),
    ('30000000-0000-0000-0000-000000000003', 'UNSAFE_ACTION', 'Body Positioning',                      3),
    ('30000000-0000-0000-0000-000000000004', 'UNSAFE_ACTION', 'Working at Height',                     4),
    ('30000000-0000-0000-0000-000000000005', 'UNSAFE_ACTION', 'Electrical Safety',                     5),
    ('30000000-0000-0000-0000-000000000006', 'UNSAFE_ACTION', 'Chemical Handling',                     6),
    ('30000000-0000-0000-0000-000000000007', 'UNSAFE_ACTION', 'Manual Handling',                       7),
    ('30000000-0000-0000-0000-000000000008', 'UNSAFE_ACTION', 'Permit to Work Violation',              8),
    ('30000000-0000-0000-0000-000000000009', 'UNSAFE_ACTION', 'Housekeeping',                          9),
    ('30000000-0000-0000-0000-000000000010', 'UNSAFE_ACTION', 'Unauthorised Access',                  10);

-- Sub-categories for PPE
INSERT INTO categories (id, report_type, name, parent_id, sort_order) VALUES
    ('30000000-0000-0000-0000-000000000011', 'UNSAFE_ACTION', 'Not wearing hard hat',      '30000000-0000-0000-0000-000000000001', 1),
    ('30000000-0000-0000-0000-000000000012', 'UNSAFE_ACTION', 'Not wearing safety shoes',  '30000000-0000-0000-0000-000000000001', 2),
    ('30000000-0000-0000-0000-000000000013', 'UNSAFE_ACTION', 'Not wearing safety vest',   '30000000-0000-0000-0000-000000000001', 3),
    ('30000000-0000-0000-0000-000000000014', 'UNSAFE_ACTION', 'Not wearing gloves',        '30000000-0000-0000-0000-000000000001', 4),
    ('30000000-0000-0000-0000-000000000015', 'UNSAFE_ACTION', 'Not wearing eye protection','30000000-0000-0000-0000-000000000001', 5),
    ('30000000-0000-0000-0000-000000000016', 'UNSAFE_ACTION', 'Wearing inappropriate PPE', '30000000-0000-0000-0000-000000000001', 6);

-- ─────────────────────────────────────────────
-- CATEGORIES — UNSAFE_SITUATION
-- ─────────────────────────────────────────────

INSERT INTO categories (id, report_type, name, sort_order) VALUES
    ('40000000-0000-0000-0000-000000000001', 'UNSAFE_SITUATION', 'Slippery / Wet Surface',        1),
    ('40000000-0000-0000-0000-000000000002', 'UNSAFE_SITUATION', 'Obstructed Walkway / Exit',     2),
    ('40000000-0000-0000-0000-000000000003', 'UNSAFE_SITUATION', 'Defective Equipment',            3),
    ('40000000-0000-0000-0000-000000000004', 'UNSAFE_SITUATION', 'Inadequate Lighting',            4),
    ('40000000-0000-0000-0000-000000000005', 'UNSAFE_SITUATION', 'Exposed / Unguarded Machinery',  5),
    ('40000000-0000-0000-0000-000000000006', 'UNSAFE_SITUATION', 'Chemical Spill / Leak',          6),
    ('40000000-0000-0000-0000-000000000007', 'UNSAFE_SITUATION', 'Fire Hazard',                    7),
    ('40000000-0000-0000-0000-000000000008', 'UNSAFE_SITUATION', 'Electrical Hazard',              8),
    ('40000000-0000-0000-0000-000000000009', 'UNSAFE_SITUATION', 'Working at Height Risk',         9),
    ('40000000-0000-0000-0000-000000000010', 'UNSAFE_SITUATION', 'Poor Housekeeping / Waste',     10),
    ('40000000-0000-0000-0000-000000000011', 'UNSAFE_SITUATION', 'Noise Hazard',                  11),
    ('40000000-0000-0000-0000-000000000012', 'UNSAFE_SITUATION', 'Structural Defect',             12);

-- ─────────────────────────────────────────────
-- CATEGORIES — SAFE_OBSERVATION
-- ─────────────────────────────────────────────

INSERT INTO categories (id, report_type, name, sort_order) VALUES
    ('50000000-0000-0000-0000-000000000001', 'SAFE_OBSERVATION', 'Correct PPE Usage',                1),
    ('50000000-0000-0000-0000-000000000002', 'SAFE_OBSERVATION', 'Safe Work Practice',               2),
    ('50000000-0000-0000-0000-000000000003', 'SAFE_OBSERVATION', 'Good Housekeeping',                3),
    ('50000000-0000-0000-0000-000000000004', 'SAFE_OBSERVATION', 'Hazard Identified & Reported',     4),
    ('50000000-0000-0000-0000-000000000005', 'SAFE_OBSERVATION', 'Safety Leadership Demonstrated',   5),
    ('50000000-0000-0000-0000-000000000006', 'SAFE_OBSERVATION', 'Correct Tool Usage',               6),
    ('50000000-0000-0000-0000-000000000007', 'SAFE_OBSERVATION', 'Proper Chemical Handling',         7),
    ('50000000-0000-0000-0000-000000000008', 'SAFE_OBSERVATION', 'Near Miss Prevented',              8);

-- ─────────────────────────────────────────────
-- RISK FACTORS
-- ─────────────────────────────────────────────

INSERT INTO risk_factors (id, name, sort_order) VALUES
    ('60000000-0000-0000-0000-000000000001', 'Low — Unlikely, minimal impact',            1),
    ('60000000-0000-0000-0000-000000000002', 'Medium — Possible, moderate impact',        2),
    ('60000000-0000-0000-0000-000000000003', 'High — Likely, significant impact',         3),
    ('60000000-0000-0000-0000-000000000004', 'Critical — Almost certain, severe impact',  4);
