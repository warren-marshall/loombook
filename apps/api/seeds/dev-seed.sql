-- Dev-environment fake data for LoomBook.
--
-- Creates the clients / contact / lead / projects / tasks tables and fills
-- them, plus a few extra users, so the app has something to render against.
--
-- These tables are created here rather than by TypeORM because only
-- UserModule and AuthModule are wired into AppModule right now, so
-- autoLoadEntities never sees the rest of the entity graph (see the comment
-- in src/app.module.ts). The DDL below mirrors the entity decorators and
-- TypeORM's naming strategy, so once those modules are re-added,
-- synchronize should find the schema already matching.
--
-- Re-runnable: every seeded row uses a fixed UUID and is deleted first, so
-- running this twice leaves the same result and never touches real rows.
--
-- Usage:  npm run seed:dev

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------- schema

DO $$ BEGIN
  CREATE TYPE clients_status_enum AS ENUM ('active', 'past', 'churned');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE lead_status_enum AS ENUM
    ('new', 'contacted', 'contract_sent', 'booked', 'lost', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS "clients" (
  "id"                  uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "companyName"         character varying NOT NULL,
  "industry"            character varying,
  "website"             character varying,
  "status"              clients_status_enum NOT NULL DEFAULT 'active',
  "convertedFromLeadId" character varying,
  "stripeCustomerId"    character varying UNIQUE,
  "updatedByUserId"     uuid REFERENCES "user" ("id") ON DELETE SET NULL,
  "createdAt"           timestamptz NOT NULL DEFAULT now(),
  "updatedAt"           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "lead" (
  "id"                   uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "businessName"         character varying NOT NULL,
  "website"              character varying,
  "status"               lead_status_enum NOT NULL DEFAULT 'new',
  "updatedByUserId"      uuid REFERENCES "user" ("id") ON DELETE SET NULL,
  "convertedToClientId"  character varying,
  "createdAt"            timestamptz NOT NULL DEFAULT now(),
  "updatedAt"            timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "contact" (
  "id"        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "name"      character varying NOT NULL,
  "email"     character varying NOT NULL,
  "phone"     character varying,
  "role"      character varying,
  "isPrimary" boolean NOT NULL DEFAULT false,
  "clientId"  uuid REFERENCES "clients" ("id") ON DELETE CASCADE,
  "leadId"    uuid REFERENCES "lead" ("id") ON DELETE CASCADE,
  "createdAt" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "projects" (
  "id"               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "name"             character varying NOT NULL,
  "description"      text,
  "status"           character varying NOT NULL DEFAULT 'future',
  "startDate"        date,
  "dueDate"          date,
  "expectedDuration" integer,
  "completedDate"    timestamptz,
  "createdById"      uuid NOT NULL REFERENCES "user" ("id"),
  "clientId"         uuid REFERENCES "clients" ("id") ON DELETE SET NULL,
  "leadId"           uuid REFERENCES "lead" ("id") ON DELETE SET NULL,
  "lastModifiedById" uuid REFERENCES "user" ("id"),
  "createdAt"        timestamptz NOT NULL DEFAULT now(),
  "updatedAt"        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "IDX_projects_clientId" ON "projects" ("clientId");
CREATE INDEX IF NOT EXISTS "IDX_projects_leadId"   ON "projects" ("leadId");

CREATE TABLE IF NOT EXISTS "tasks" (
  "id"                  uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "name"                character varying NOT NULL,
  "description"         text,
  "status"              character varying NOT NULL DEFAULT 'future',
  "projectId"           uuid NOT NULL REFERENCES "projects" ("id") ON DELETE CASCADE,
  "startDate"           date,
  "dueDate"             date,
  "expectedDuration"    integer,
  "assigneeName"        character varying,
  "assigneeUserId"      uuid REFERENCES "user" ("id") ON DELETE SET NULL,
  "assigneeContactId"   uuid REFERENCES "contact" ("id") ON DELETE SET NULL,
  "isRecurring"         boolean NOT NULL DEFAULT false,
  "recurrencePattern"   character varying,
  "recurrenceInterval"  integer,
  "recurrenceDayOfWeek" integer,
  "recurrenceEndDate"   date,
  "recurrenceCount"     integer,
  "recurringGroupId"    uuid,
  "createdById"         uuid NOT NULL REFERENCES "user" ("id"),
  "lastModifiedById"    uuid REFERENCES "user" ("id"),
  "createdAt"           timestamptz NOT NULL DEFAULT now(),
  "updatedAt"           timestamptz NOT NULL DEFAULT now(),
  "completedAt"         timestamptz
);
CREATE INDEX IF NOT EXISTS "IDX_tasks_projectId" ON "tasks" ("projectId");

CREATE TABLE IF NOT EXISTS "task_dependencies" (
  "taskId"          uuid NOT NULL REFERENCES "tasks" ("id") ON DELETE CASCADE,
  "dependsOnTaskId" uuid NOT NULL REFERENCES "tasks" ("id") ON DELETE CASCADE,
  PRIMARY KEY ("taskId", "dependsOnTaskId")
);

-- ------------------------------------------------------------- clean up
-- Seeded rows only. Fixed UUID blocks per table: users 1111..., clients 2222...,
-- contacts 3333..., leads 4444..., projects 5555..., tasks 6666...

DELETE FROM "task_dependencies"
  WHERE "taskId"::text LIKE '66666666-%' OR "dependsOnTaskId"::text LIKE '66666666-%';
DELETE FROM "tasks"    WHERE "id"::text LIKE '66666666-%';
DELETE FROM "projects" WHERE "id"::text LIKE '55555555-%';
DELETE FROM "contact"  WHERE "id"::text LIKE '33333333-%';
DELETE FROM "lead"     WHERE "id"::text LIKE '44444444-%';
DELETE FROM "clients"  WHERE "id"::text LIKE '22222222-%';
DELETE FROM "user"     WHERE "id"::text LIKE '11111111-%';

-- ---------------------------------------------------------------- users
-- Password for all seeded users: Password123!

INSERT INTO "user" ("id", "firstName", "lastName", "email", "password", "userRole", "userType") VALUES
  ('11111111-0000-4000-8000-000000000001', 'Nadia', 'Okonkwo',   'nadia@loombook.dev', '$2b$10$spZ5cMTHHAc2oUDMNt.xLu4LhIhdIRMJFESRwJONEHGRw9m9.EfNa', 'admin', 'photographer'),
  ('11111111-0000-4000-8000-000000000002', 'Elias', 'Ferrante',  'elias@loombook.dev', '$2b$10$spZ5cMTHHAc2oUDMNt.xLu4LhIhdIRMJFESRwJONEHGRw9m9.EfNa', 'basic', 'photographer'),
  ('11111111-0000-4000-8000-000000000003', 'Priya', 'Raghunath', 'priya@loombook.dev', '$2b$10$spZ5cMTHHAc2oUDMNt.xLu4LhIhdIRMJFESRwJONEHGRw9m9.EfNa', 'basic', 'photographer');

-- -------------------------------------------------------------- clients

INSERT INTO "clients" ("id", "companyName", "industry", "website", "status", "stripeCustomerId", "updatedByUserId", "createdAt") VALUES
  ('22222222-0000-4000-8000-000000000001', 'Cedar & Sage Restaurant Group', 'Hospitality',  'https://cedarandsage.example.com',    'active',  'cus_dev_cedarsage',  '11111111-0000-4000-8000-000000000001', now() - interval '14 months'),
  ('22222222-0000-4000-8000-000000000002', 'Harborline Real Estate',        'Real Estate',  'https://harborline.example.com',      'active',  'cus_dev_harborline', '11111111-0000-4000-8000-000000000001', now() - interval '9 months'),
  ('22222222-0000-4000-8000-000000000003', 'Vantage Point Architects',      'Architecture', 'https://vantagepoint.example.com',    'active',  'cus_dev_vantage',    '11111111-0000-4000-8000-000000000002', now() - interval '5 months'),
  ('22222222-0000-4000-8000-000000000004', 'Northlight Fitness Collective', 'Fitness',      'https://northlightfit.example.com',   'past',    NULL,                 '11111111-0000-4000-8000-000000000002', now() - interval '2 years'),
  ('22222222-0000-4000-8000-000000000005', 'Bramble & Bloom Florists',      'Retail',       'https://brambleandbloom.example.com', 'churned', 'cus_dev_bramble',    '11111111-0000-4000-8000-000000000001', now() - interval '3 years');

-- ---------------------------------------------------------------- leads

INSERT INTO "lead" ("id", "businessName", "website", "status", "updatedByUserId", "createdAt") VALUES
  ('44444444-0000-4000-8000-000000000001', 'Tidewater Brewing Co.',     'https://tidewaterbrew.example.com',  'new',           '11111111-0000-4000-8000-000000000001', now() - interval '6 days'),
  ('44444444-0000-4000-8000-000000000002', 'Marlowe Dental Studio',     'https://marlowedental.example.com',  'contacted',     '11111111-0000-4000-8000-000000000002', now() - interval '3 weeks'),
  ('44444444-0000-4000-8000-000000000003', 'Ironwood Furniture Makers', 'https://ironwoodmakers.example.com', 'contract_sent', '11111111-0000-4000-8000-000000000001', now() - interval '5 weeks'),
  ('44444444-0000-4000-8000-000000000004', 'Solstice Yoga Retreats',    'https://solsticeyoga.example.com',   'booked',        '11111111-0000-4000-8000-000000000003', now() - interval '2 months'),
  ('44444444-0000-4000-8000-000000000005', 'Pellwood Legal Partners',   'https://pellwoodlegal.example.com',  'lost',          '11111111-0000-4000-8000-000000000002', now() - interval '4 months'),
  ('44444444-0000-4000-8000-000000000006', 'Glasshouse Interiors',      NULL,                                 'archived',      '11111111-0000-4000-8000-000000000002', now() - interval '8 months');

-- ------------------------------------------------------------- contacts

INSERT INTO "contact" ("id", "name", "email", "phone", "role", "isPrimary", "clientId", "leadId") VALUES
  ('33333333-0000-4000-8000-000000000001', 'Marguerite Osei',   'marguerite@cedarandsage.example.com', '+1-503-555-0142', 'Marketing Director',  true,  '22222222-0000-4000-8000-000000000001', NULL),
  ('33333333-0000-4000-8000-000000000002', 'Dov Steinberg',     'dov@cedarandsage.example.com',        '+1-503-555-0188', 'Operations Manager',  false, '22222222-0000-4000-8000-000000000001', NULL),
  ('33333333-0000-4000-8000-000000000003', 'Yolanda Prescott',  'yolanda@harborline.example.com',      '+1-206-555-0119', 'Broker / Owner',      true,  '22222222-0000-4000-8000-000000000002', NULL),
  ('33333333-0000-4000-8000-000000000004', 'Kwame Adjei',       'kwame@harborline.example.com',        '+1-206-555-0173', 'Listing Coordinator', false, '22222222-0000-4000-8000-000000000002', NULL),
  ('33333333-0000-4000-8000-000000000005', 'Ingrid Halvorsen',  'ingrid@vantagepoint.example.com',     '+1-415-555-0164', 'Principal Architect', true,  '22222222-0000-4000-8000-000000000003', NULL),
  ('33333333-0000-4000-8000-000000000006', 'Tobias Renner',     'tobias@northlightfit.example.com',    '+1-312-555-0155', 'Studio Owner',        true,  '22222222-0000-4000-8000-000000000004', NULL),
  ('33333333-0000-4000-8000-000000000007', 'Saoirse Byrne',     'saoirse@brambleandbloom.example.com', NULL,              'Founder',             true,  '22222222-0000-4000-8000-000000000005', NULL),
  ('33333333-0000-4000-8000-000000000008', 'Hal Whitaker',      'hal@tidewaterbrew.example.com',       '+1-757-555-0128', 'Head of Brand',       true,  NULL, '44444444-0000-4000-8000-000000000001'),
  ('33333333-0000-4000-8000-000000000009', 'Dr. Amara Marlowe', 'amara@marlowedental.example.com',     '+1-919-555-0191', 'Practice Owner',      true,  NULL, '44444444-0000-4000-8000-000000000002'),
  ('33333333-0000-4000-8000-000000000010', 'Bjorn Lindqvist',   'bjorn@ironwoodmakers.example.com',    '+1-608-555-0137', 'Co-founder',          true,  NULL, '44444444-0000-4000-8000-000000000003'),
  ('33333333-0000-4000-8000-000000000011', 'Rosalind Achebe',   'rosalind@solsticeyoga.example.com',   '+1-802-555-0146', 'Retreat Director',    true,  NULL, '44444444-0000-4000-8000-000000000004'),
  ('33333333-0000-4000-8000-000000000012', 'Curtis Pellwood',   'curtis@pellwoodlegal.example.com',    NULL,              'Managing Partner',    true,  NULL, '44444444-0000-4000-8000-000000000005');

-- ------------------------------------------------------------- projects

INSERT INTO "projects" ("id", "name", "description", "status", "startDate", "dueDate", "expectedDuration", "completedDate", "createdById", "clientId", "leadId", "lastModifiedById") VALUES
  ('55555555-0000-4000-8000-000000000001', 'Autumn Menu Launch Shoot',      'Food and interior photography for the seasonal menu relaunch across all four locations.', 'active',    CURRENT_DATE - 12,  CURRENT_DATE + 18, 30, NULL, '11111111-0000-4000-8000-000000000001', '22222222-0000-4000-8000-000000000001', NULL, '11111111-0000-4000-8000-000000000002'),
  ('55555555-0000-4000-8000-000000000002', 'Waterfront Listings - Q4',      'Rotating property shoots for new waterfront listings. Drone plus interior coverage.',      'active',    CURRENT_DATE - 30,  CURRENT_DATE + 45, 75, NULL, '11111111-0000-4000-8000-000000000001', '22222222-0000-4000-8000-000000000002', NULL, '11111111-0000-4000-8000-000000000001'),
  ('55555555-0000-4000-8000-000000000003', 'Team Headshot Refresh',         'Updated headshots for 14 staff members, matching the existing brand lighting setup.',      'planning',  CURRENT_DATE + 10,  CURRENT_DATE + 24, 14, NULL, '11111111-0000-4000-8000-000000000002', '22222222-0000-4000-8000-000000000002', NULL, '11111111-0000-4000-8000-000000000002'),
  ('55555555-0000-4000-8000-000000000004', 'Brennan House Portfolio Shoot', 'Architectural portfolio documentation of the completed Brennan House residence.',          'on_hold',   CURRENT_DATE - 60,  CURRENT_DATE + 30, 40, NULL, '11111111-0000-4000-8000-000000000001', '22222222-0000-4000-8000-000000000003', NULL, '11111111-0000-4000-8000-000000000003'),
  ('55555555-0000-4000-8000-000000000005', 'Studio Rebrand Campaign',       'Full campaign shoot supporting the studio rebrand. Delivered and archived.',               'completed', CURRENT_DATE - 400, CURRENT_DATE - 360, 40, now() - interval '11 months', '11111111-0000-4000-8000-000000000001', '22222222-0000-4000-8000-000000000004', NULL, '11111111-0000-4000-8000-000000000001'),
  ('55555555-0000-4000-8000-000000000006', 'Holiday Lookbook',              'Cancelled when the client ended the engagement mid-production.',                           'cancelled', CURRENT_DATE - 700, CURRENT_DATE - 670, 30, NULL, '11111111-0000-4000-8000-000000000002', '22222222-0000-4000-8000-000000000005', NULL, '11111111-0000-4000-8000-000000000002'),
  ('55555555-0000-4000-8000-000000000007', 'Solstice Retreat - Spring Set', 'Lifestyle coverage of the spring retreat weekend. Booked, awaiting client onboarding.',    'future',    CURRENT_DATE + 40,  CURRENT_DATE + 47, 7,  NULL, '11111111-0000-4000-8000-000000000003', NULL, '44444444-0000-4000-8000-000000000004', '11111111-0000-4000-8000-000000000003'),
  ('55555555-0000-4000-8000-000000000008', 'Ironwood Workshop Story',       'Proposed documentary-style shoot of the workshop floor. Pending contract signature.',      'future',    NULL, NULL, 12, NULL, '11111111-0000-4000-8000-000000000001', NULL, '44444444-0000-4000-8000-000000000003', '11111111-0000-4000-8000-000000000001');

-- ---------------------------------------------------------------- tasks

INSERT INTO "tasks" ("id", "name", "description", "status", "projectId", "startDate", "dueDate", "expectedDuration", "assigneeName", "assigneeUserId", "assigneeContactId", "isRecurring", "recurrencePattern", "recurrenceInterval", "recurrenceDayOfWeek", "recurrenceEndDate", "recurrenceCount", "recurringGroupId", "createdById", "lastModifiedById", "completedAt") VALUES
  ('66666666-0000-4000-8000-000000000001', 'Scout all four locations',      'Walk each dining room and note available light by time of day.', 'completed', '55555555-0000-4000-8000-000000000001', CURRENT_DATE - 12, CURRENT_DATE - 9, 3, 'Nadia Okonkwo',    '11111111-0000-4000-8000-000000000001', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', now() - interval '9 days'),
  ('66666666-0000-4000-8000-000000000002', 'Confirm final dish list',       'Chef to lock the 12 hero dishes before the shoot date.',          'completed', '55555555-0000-4000-8000-000000000001', CURRENT_DATE - 10, CURRENT_DATE - 7, 3, 'Dov Steinberg',    NULL, '33333333-0000-4000-8000-000000000002', false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000002', now() - interval '8 days'),
  ('66666666-0000-4000-8000-000000000003', 'Shoot day - Riverside',         'Full day, food plus ambience. Bring the 90mm macro.',             'active',    '55555555-0000-4000-8000-000000000001', CURRENT_DATE,      CURRENT_DATE + 1, 1, 'Nadia Okonkwo',    '11111111-0000-4000-8000-000000000001', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', NULL),
  ('66666666-0000-4000-8000-000000000004', 'Cull and edit hero selects',    'Deliver 40 retouched hero frames for the menu inserts.',          'next up',   '55555555-0000-4000-8000-000000000001', CURRENT_DATE + 2,  CURRENT_DATE + 9, 7, 'Elias Ferrante',   '11111111-0000-4000-8000-000000000002', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', NULL),
  ('66666666-0000-4000-8000-000000000005', 'Client review round',           'Send the gallery link and collect consolidated feedback.',        'future',    '55555555-0000-4000-8000-000000000001', CURRENT_DATE + 10, CURRENT_DATE + 14, 4, 'Marguerite Osei', NULL, '33333333-0000-4000-8000-000000000001', false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', NULL, NULL),
  ('66666666-0000-4000-8000-000000000006', 'Weekly listing shoot',          'Standing Tuesday slot for whatever came on market that week.',    'active',    '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 30, CURRENT_DATE + 45, 1, 'Elias Ferrante',  '11111111-0000-4000-8000-000000000002', NULL, true, 'weekly', 1, 2, CURRENT_DATE + 45, 12, '77777777-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', NULL),
  ('66666666-0000-4000-8000-000000000007', 'Renew drone permit',            'FAA Part 107 currency plus the marina-specific clearance.',       'stuck',     '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 20, CURRENT_DATE - 3, 5, 'Nadia Okonkwo',    '11111111-0000-4000-8000-000000000001', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', NULL),
  ('66666666-0000-4000-8000-000000000008', 'Deliver October batch',         'Upload to the MLS-ready gallery and notify the coordinator.',     'paused',    '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 8,  CURRENT_DATE + 6, 4, 'Kwame Adjei',      NULL, '33333333-0000-4000-8000-000000000004', false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000002', NULL),
  ('66666666-0000-4000-8000-000000000009', 'Book the studio space',         'Half day rental, needs the wide cyc wall.',                       'next up',   '55555555-0000-4000-8000-000000000003', CURRENT_DATE + 10, CURRENT_DATE + 13, 3, 'Priya Raghunath', '11111111-0000-4000-8000-000000000003', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000002', NULL, NULL),
  ('66666666-0000-4000-8000-000000000010', 'Circulate scheduling sheet',    'Fourteen 20-minute slots across the morning.',                    'future',    '55555555-0000-4000-8000-000000000003', CURRENT_DATE + 14, CURRENT_DATE + 17, 3, 'Yolanda Prescott', NULL, '33333333-0000-4000-8000-000000000003', false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000002', NULL, NULL),
  ('66666666-0000-4000-8000-000000000011', 'Shoot day - headshots',         NULL,                                                              'future',    '55555555-0000-4000-8000-000000000003', CURRENT_DATE + 20, CURRENT_DATE + 20, 1, 'Priya Raghunath', '11111111-0000-4000-8000-000000000003', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000002', NULL, NULL),
  ('66666666-0000-4000-8000-000000000012', 'Await landscaping completion',  'Client paused until the garden is planted.',                      'paused',    '55555555-0000-4000-8000-000000000004', NULL, NULL, NULL, 'Ingrid Halvorsen', NULL, '33333333-0000-4000-8000-000000000005', false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000003', NULL),
  ('66666666-0000-4000-8000-000000000013', 'Final archive handoff',         'Delivered full-res archive on the client drive.',                 'completed', '55555555-0000-4000-8000-000000000005', CURRENT_DATE - 370, CURRENT_DATE - 360, 10, 'Nadia Okonkwo',  '11111111-0000-4000-8000-000000000001', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', now() - interval '11 months'),
  ('66666666-0000-4000-8000-000000000014', 'Send onboarding questionnaire', 'Shot list, timings, and who is on site each day.',                'next up',   '55555555-0000-4000-8000-000000000007', CURRENT_DATE + 3, CURRENT_DATE + 7, 4, 'Rosalind Achebe',  NULL, '33333333-0000-4000-8000-000000000011', false, NULL, NULL, NULL, NULL, NULL, NULL, '11111111-0000-4000-8000-000000000003', NULL, NULL),
  ('66666666-0000-4000-8000-000000000015', 'Monthly gear maintenance',      'Sensor clean, firmware, and battery health check.',               'active',    '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 30, CURRENT_DATE + 60, 1, 'Elias Ferrante',  '11111111-0000-4000-8000-000000000002', NULL, true, 'monthly', 1, NULL, NULL, NULL, '77777777-0000-4000-8000-000000000002', '11111111-0000-4000-8000-000000000002', NULL, NULL);

-- Dependencies: "taskId depends on dependsOnTaskId".
INSERT INTO "task_dependencies" ("taskId", "dependsOnTaskId") VALUES
  ('66666666-0000-4000-8000-000000000003', '66666666-0000-4000-8000-000000000001'),
  ('66666666-0000-4000-8000-000000000003', '66666666-0000-4000-8000-000000000002'),
  ('66666666-0000-4000-8000-000000000004', '66666666-0000-4000-8000-000000000003'),
  ('66666666-0000-4000-8000-000000000005', '66666666-0000-4000-8000-000000000004'),
  ('66666666-0000-4000-8000-000000000006', '66666666-0000-4000-8000-000000000007'),
  ('66666666-0000-4000-8000-000000000010', '66666666-0000-4000-8000-000000000009'),
  ('66666666-0000-4000-8000-000000000011', '66666666-0000-4000-8000-000000000010');

COMMIT;
