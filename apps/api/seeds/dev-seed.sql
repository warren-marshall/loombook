-- Dev-environment fake data for LoomBook.
--
-- Creates the clients / contact / lead / projects / tasks / email_messages /
-- invoices / contracts / attachments tables and fills them, so the app has something to
-- render against. The location table is seeded too, but only when PostGIS is available -- see its section below.
--
-- The DDL below is CREATE TABLE IF NOT EXISTS throughout, so it is a no-op
-- against a database TypeORM has already synchronized. It exists so the seed
-- can also stand up a database from scratch, and so tables whose modules are
-- not wired into AppModule (or cannot be synchronized at all, like location)
-- still get created. It mirrors the entity decorators and TypeORM's naming
-- strategy, so synchronize should find the schema already matching.
--
-- Re-runnable: every seeded row uses a fixed UUID and is deleted first, so
-- running this twice leaves the same result and never touches real rows.
--
-- Usage:  npm run seed:dev

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Needed by the location table. Guarded so this file still runs end to end
-- against a stock Postgres, where the extension is simply unavailable and the
-- locations section further down skips itself.
DO $postgis$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'postgis') THEN
    CREATE EXTENSION IF NOT EXISTS postgis;
  END IF;
END $postgis$;

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

CREATE TABLE IF NOT EXISTS "email_messages" (
  "id"        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "subject"   character varying,
  "message"   text NOT NULL,
  "clientId"  uuid REFERENCES "clients" ("id") ON DELETE CASCADE,
  "leadId"    uuid REFERENCES "lead" ("id") ON DELETE CASCADE,
  "contactId" uuid REFERENCES "contact" ("id") ON DELETE SET NULL,
  "createdAt" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "invoices" (
  "id"          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "amountCents" integer NOT NULL,
  "status"      character varying NOT NULL DEFAULT 'draft',
  "clientId"    uuid NOT NULL REFERENCES "clients" ("id") ON DELETE CASCADE,
  "createdAt"   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "contracts" (
  "id"        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "title"     character varying NOT NULL,
  "clientId"  uuid REFERENCES "clients" ("id") ON DELETE CASCADE,
  "leadId"    uuid REFERENCES "lead" ("id") ON DELETE CASCADE,
  "createdAt" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "attachments" (
  "id"        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "filename"  character varying NOT NULL,
  "url"       character varying NOT NULL,
  "clientId"  uuid REFERENCES "clients" ("id") ON DELETE CASCADE,
  "leadId"    uuid REFERENCES "lead" ("id") ON DELETE CASCADE,
  "createdAt" timestamptz NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------- clean up
-- Seeded rows only. Fixed UUID blocks per table: clients 2222...,
-- contacts 3333..., leads 4444..., projects 5555..., tasks 6666...,
-- email messages 8888..., invoices 9999..., contracts aaaa..., attachments
-- bbbb..., locations cccc... (Users 1111... were seeded by an older version of
-- this file; the DELETE below removes them.)

DELETE FROM "attachments"    WHERE "id"::text LIKE 'bbbbbbbb-%';
DELETE FROM "contracts"      WHERE "id"::text LIKE 'aaaaaaaa-%';
DELETE FROM "invoices"       WHERE "id"::text LIKE '99999999-%';
DELETE FROM "email_messages" WHERE "id"::text LIKE '88888888-%';
DELETE FROM "task_dependencies"
  WHERE "taskId"::text LIKE '66666666-%' OR "dependsOnTaskId"::text LIKE '66666666-%';
DELETE FROM "tasks"    WHERE "id"::text LIKE '66666666-%';
DELETE FROM "projects" WHERE "id"::text LIKE '55555555-%';
DELETE FROM "contact"  WHERE "id"::text LIKE '33333333-%';
DELETE FROM "lead"     WHERE "id"::text LIKE '44444444-%';
DELETE FROM "clients"  WHERE "id"::text LIKE '22222222-%';
DELETE FROM "user"     WHERE "id"::text LIKE '11111111-%';

-- ---------------------------------------------------------------- owner
-- No users are seeded. Every created-by / updated-by / assignee reference
-- below points at the one real account (create it first with
-- `npm run seed:owner`). If several real users exist, the oldest is used.

DO $owner$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM "user") THEN
    RAISE EXCEPTION 'No user found. Run npm run seed:owner -- <email> <password> <firstname> <lastname> first.';
  END IF;
END $owner$;

CREATE TEMP TABLE "seed_owner" ON COMMIT DROP AS
  SELECT "id", "firstName" || ' ' || "lastName" AS "fullName"
  FROM "user" ORDER BY "createdAt" ASC LIMIT 1;

-- -------------------------------------------------------------- clients

INSERT INTO "clients" ("id", "companyName", "industry", "website", "status", "stripeCustomerId", "updatedByUserId", "createdAt") VALUES
  ('22222222-0000-4000-8000-000000000001', 'Cedar & Sage Restaurant Group', 'Hospitality',  'https://cedarandsage.example.com',    'active',  'cus_dev_cedarsage',  (SELECT "id" FROM "seed_owner"), now() - interval '14 months'),
  ('22222222-0000-4000-8000-000000000002', 'Harborline Real Estate',        'Real Estate',  'https://harborline.example.com',      'active',  'cus_dev_harborline', (SELECT "id" FROM "seed_owner"), now() - interval '9 months'),
  ('22222222-0000-4000-8000-000000000003', 'Vantage Point Architects',      'Architecture', 'https://vantagepoint.example.com',    'active',  'cus_dev_vantage',    (SELECT "id" FROM "seed_owner"), now() - interval '5 months'),
  ('22222222-0000-4000-8000-000000000004', 'Northlight Fitness Collective', 'Fitness',      'https://northlightfit.example.com',   'past',    NULL,                 (SELECT "id" FROM "seed_owner"), now() - interval '2 years'),
  ('22222222-0000-4000-8000-000000000005', 'Bramble & Bloom Florists',      'Retail',       'https://brambleandbloom.example.com', 'churned', 'cus_dev_bramble',    (SELECT "id" FROM "seed_owner"), now() - interval '3 years');

-- ---------------------------------------------------------------- leads

INSERT INTO "lead" ("id", "businessName", "website", "status", "updatedByUserId", "createdAt") VALUES
  ('44444444-0000-4000-8000-000000000001', 'Tidewater Brewing Co.',     'https://tidewaterbrew.example.com',  'new',           (SELECT "id" FROM "seed_owner"), now() - interval '6 days'),
  ('44444444-0000-4000-8000-000000000002', 'Marlowe Dental Studio',     'https://marlowedental.example.com',  'contacted',     (SELECT "id" FROM "seed_owner"), now() - interval '3 weeks'),
  ('44444444-0000-4000-8000-000000000003', 'Ironwood Furniture Makers', 'https://ironwoodmakers.example.com', 'contract_sent', (SELECT "id" FROM "seed_owner"), now() - interval '5 weeks'),
  ('44444444-0000-4000-8000-000000000004', 'Solstice Yoga Retreats',    'https://solsticeyoga.example.com',   'booked',        (SELECT "id" FROM "seed_owner"), now() - interval '2 months'),
  ('44444444-0000-4000-8000-000000000005', 'Pellwood Legal Partners',   'https://pellwoodlegal.example.com',  'lost',          (SELECT "id" FROM "seed_owner"), now() - interval '4 months'),
  ('44444444-0000-4000-8000-000000000006', 'Glasshouse Interiors',      NULL,                                 'archived',      (SELECT "id" FROM "seed_owner"), now() - interval '8 months');

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
  ('55555555-0000-4000-8000-000000000001', 'Autumn Menu Launch Shoot',      'Food and interior photography for the seasonal menu relaunch across all four locations.', 'active',    CURRENT_DATE - 12,  CURRENT_DATE + 18, 30, NULL, (SELECT "id" FROM "seed_owner"), '22222222-0000-4000-8000-000000000001', NULL, (SELECT "id" FROM "seed_owner")),
  ('55555555-0000-4000-8000-000000000002', 'Waterfront Listings - Q4',      'Rotating property shoots for new waterfront listings. Drone plus interior coverage.',      'active',    CURRENT_DATE - 30,  CURRENT_DATE + 45, 75, NULL, (SELECT "id" FROM "seed_owner"), '22222222-0000-4000-8000-000000000002', NULL, (SELECT "id" FROM "seed_owner")),
  ('55555555-0000-4000-8000-000000000003', 'Team Headshot Refresh',         'Updated headshots for 14 staff members, matching the existing brand lighting setup.',      'planning',  CURRENT_DATE + 10,  CURRENT_DATE + 24, 14, NULL, (SELECT "id" FROM "seed_owner"), '22222222-0000-4000-8000-000000000002', NULL, (SELECT "id" FROM "seed_owner")),
  ('55555555-0000-4000-8000-000000000004', 'Brennan House Portfolio Shoot', 'Architectural portfolio documentation of the completed Brennan House residence.',          'on_hold',   CURRENT_DATE - 60,  CURRENT_DATE + 30, 40, NULL, (SELECT "id" FROM "seed_owner"), '22222222-0000-4000-8000-000000000003', NULL, (SELECT "id" FROM "seed_owner")),
  ('55555555-0000-4000-8000-000000000005', 'Studio Rebrand Campaign',       'Full campaign shoot supporting the studio rebrand. Delivered and archived.',               'completed', CURRENT_DATE - 400, CURRENT_DATE - 360, 40, now() - interval '11 months', (SELECT "id" FROM "seed_owner"), '22222222-0000-4000-8000-000000000004', NULL, (SELECT "id" FROM "seed_owner")),
  ('55555555-0000-4000-8000-000000000006', 'Holiday Lookbook',              'Cancelled when the client ended the engagement mid-production.',                           'cancelled', CURRENT_DATE - 700, CURRENT_DATE - 670, 30, NULL, (SELECT "id" FROM "seed_owner"), '22222222-0000-4000-8000-000000000005', NULL, (SELECT "id" FROM "seed_owner")),
  ('55555555-0000-4000-8000-000000000007', 'Solstice Retreat - Spring Set', 'Lifestyle coverage of the spring retreat weekend. Booked, awaiting client onboarding.',    'future',    CURRENT_DATE + 40,  CURRENT_DATE + 47, 7,  NULL, (SELECT "id" FROM "seed_owner"), NULL, '44444444-0000-4000-8000-000000000004', (SELECT "id" FROM "seed_owner")),
  ('55555555-0000-4000-8000-000000000008', 'Ironwood Workshop Story',       'Proposed documentary-style shoot of the workshop floor. Pending contract signature.',      'future',    NULL, NULL, 12, NULL, (SELECT "id" FROM "seed_owner"), NULL, '44444444-0000-4000-8000-000000000003', (SELECT "id" FROM "seed_owner"));

-- ---------------------------------------------------------------- tasks

INSERT INTO "tasks" ("id", "name", "description", "status", "projectId", "startDate", "dueDate", "expectedDuration", "assigneeName", "assigneeUserId", "assigneeContactId", "isRecurring", "recurrencePattern", "recurrenceInterval", "recurrenceDayOfWeek", "recurrenceEndDate", "recurrenceCount", "recurringGroupId", "createdById", "lastModifiedById", "completedAt") VALUES
  ('66666666-0000-4000-8000-000000000001', 'Scout all four locations',      'Walk each dining room and note available light by time of day.', 'completed', '55555555-0000-4000-8000-000000000001', CURRENT_DATE - 12, CURRENT_DATE - 9, 3, (SELECT "fullName" FROM "seed_owner"),    (SELECT "id" FROM "seed_owner"), NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), now() - interval '9 days'),
  ('66666666-0000-4000-8000-000000000002', 'Confirm final dish list',       'Chef to lock the 12 hero dishes before the shoot date.',          'completed', '55555555-0000-4000-8000-000000000001', CURRENT_DATE - 10, CURRENT_DATE - 7, 3, 'Dov Steinberg',    NULL, '33333333-0000-4000-8000-000000000002', false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), now() - interval '8 days'),
  ('66666666-0000-4000-8000-000000000003', 'Shoot day - Riverside',         'Full day, food plus ambience. Bring the 90mm macro.',             'active',    '55555555-0000-4000-8000-000000000001', CURRENT_DATE,      CURRENT_DATE + 1, 1, (SELECT "fullName" FROM "seed_owner"),    (SELECT "id" FROM "seed_owner"), NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL),
  ('66666666-0000-4000-8000-000000000004', 'Cull and edit hero selects',    'Deliver 40 retouched hero frames for the menu inserts.',          'next up',   '55555555-0000-4000-8000-000000000001', CURRENT_DATE + 2,  CURRENT_DATE + 9, 7, (SELECT "fullName" FROM "seed_owner"),   (SELECT "id" FROM "seed_owner"), NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL),
  ('66666666-0000-4000-8000-000000000005', 'Client review round',           'Send the gallery link and collect consolidated feedback.',        'future',    '55555555-0000-4000-8000-000000000001', CURRENT_DATE + 10, CURRENT_DATE + 14, 4, 'Marguerite Osei', NULL, '33333333-0000-4000-8000-000000000001', false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), NULL, NULL),
  ('66666666-0000-4000-8000-000000000006', 'Weekly listing shoot',          'Standing Tuesday slot for whatever came on market that week.',    'active',    '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 30, CURRENT_DATE + 45, 1, (SELECT "fullName" FROM "seed_owner"),  (SELECT "id" FROM "seed_owner"), NULL, true, 'weekly', 1, 2, CURRENT_DATE + 45, 12, '77777777-0000-4000-8000-000000000001', (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL),
  ('66666666-0000-4000-8000-000000000007', 'Renew drone permit',            'FAA Part 107 currency plus the marina-specific clearance.',       'stuck',     '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 20, CURRENT_DATE - 3, 5, (SELECT "fullName" FROM "seed_owner"),    (SELECT "id" FROM "seed_owner"), NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL),
  ('66666666-0000-4000-8000-000000000008', 'Deliver October batch',         'Upload to the MLS-ready gallery and notify the coordinator.',     'paused',    '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 8,  CURRENT_DATE + 6, 4, 'Kwame Adjei',      NULL, '33333333-0000-4000-8000-000000000004', false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL),
  ('66666666-0000-4000-8000-000000000009', 'Book the studio space',         'Half day rental, needs the wide cyc wall.',                       'next up',   '55555555-0000-4000-8000-000000000003', CURRENT_DATE + 10, CURRENT_DATE + 13, 3, (SELECT "fullName" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), NULL, NULL),
  ('66666666-0000-4000-8000-000000000010', 'Circulate scheduling sheet',    'Fourteen 20-minute slots across the morning.',                    'future',    '55555555-0000-4000-8000-000000000003', CURRENT_DATE + 14, CURRENT_DATE + 17, 3, 'Yolanda Prescott', NULL, '33333333-0000-4000-8000-000000000003', false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), NULL, NULL),
  ('66666666-0000-4000-8000-000000000011', 'Shoot day - headshots',         NULL,                                                              'future',    '55555555-0000-4000-8000-000000000003', CURRENT_DATE + 20, CURRENT_DATE + 20, 1, (SELECT "fullName" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), NULL, NULL),
  ('66666666-0000-4000-8000-000000000012', 'Await landscaping completion',  'Client paused until the garden is planted.',                      'paused',    '55555555-0000-4000-8000-000000000004', NULL, NULL, NULL, 'Ingrid Halvorsen', NULL, '33333333-0000-4000-8000-000000000005', false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), NULL),
  ('66666666-0000-4000-8000-000000000013', 'Final archive handoff',         'Delivered full-res archive on the client drive.',                 'completed', '55555555-0000-4000-8000-000000000005', CURRENT_DATE - 370, CURRENT_DATE - 360, 10, (SELECT "fullName" FROM "seed_owner"),  (SELECT "id" FROM "seed_owner"), NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), (SELECT "id" FROM "seed_owner"), now() - interval '11 months'),
  ('66666666-0000-4000-8000-000000000014', 'Send onboarding questionnaire', 'Shot list, timings, and who is on site each day.',                'next up',   '55555555-0000-4000-8000-000000000007', CURRENT_DATE + 3, CURRENT_DATE + 7, 4, 'Rosalind Achebe',  NULL, '33333333-0000-4000-8000-000000000011', false, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT "id" FROM "seed_owner"), NULL, NULL),
  ('66666666-0000-4000-8000-000000000015', 'Monthly gear maintenance',      'Sensor clean, firmware, and battery health check.',               'active',    '55555555-0000-4000-8000-000000000002', CURRENT_DATE - 30, CURRENT_DATE + 60, 1, (SELECT "fullName" FROM "seed_owner"),  (SELECT "id" FROM "seed_owner"), NULL, true, 'monthly', 1, NULL, NULL, NULL, '77777777-0000-4000-8000-000000000002', (SELECT "id" FROM "seed_owner"), NULL, NULL);

-- Dependencies: "taskId depends on dependsOnTaskId".
INSERT INTO "task_dependencies" ("taskId", "dependsOnTaskId") VALUES
  ('66666666-0000-4000-8000-000000000003', '66666666-0000-4000-8000-000000000001'),
  ('66666666-0000-4000-8000-000000000003', '66666666-0000-4000-8000-000000000002'),
  ('66666666-0000-4000-8000-000000000004', '66666666-0000-4000-8000-000000000003'),
  ('66666666-0000-4000-8000-000000000005', '66666666-0000-4000-8000-000000000004'),
  ('66666666-0000-4000-8000-000000000006', '66666666-0000-4000-8000-000000000007'),
  ('66666666-0000-4000-8000-000000000010', '66666666-0000-4000-8000-000000000009'),
  ('66666666-0000-4000-8000-000000000011', '66666666-0000-4000-8000-000000000010');

-- ------------------------------------------------------- email messages

INSERT INTO "email_messages" ("id", "subject", "message", "clientId", "leadId", "contactId", "createdAt") VALUES
  ('88888888-0000-4000-8000-000000000001', 'Autumn menu shoot - final dish list',  E'Hi,\n\nChef locked the twelve hero dishes this morning. Riverside is yours from 7am, the other three rooms open at 11.\n\nMarguerite', '22222222-0000-4000-8000-000000000001', NULL, '33333333-0000-4000-8000-000000000001', now() - interval '9 days'),
  ('88888888-0000-4000-8000-000000000002', 'Re: October listing gallery',          E'The MLS-ready set looks great. Two of the waterfront frames came through a little warm - could we get a cooler grade on those before we publish?\n\nThanks,\nYolanda',                                  '22222222-0000-4000-8000-000000000002', NULL, '33333333-0000-4000-8000-000000000003', now() - interval '4 days'),
  ('88888888-0000-4000-8000-000000000003', 'Tidewater Brewing - intro + rate card', E'Thanks for reaching out. We are refreshing the taproom site in the new year and would want interior plus product coverage. Can you send a rate card?\n\nHal',                                            NULL, '44444444-0000-4000-8000-000000000001', '33333333-0000-4000-8000-000000000008', now() - interval '5 days');

-- ------------------------------------------------------------- invoices

INSERT INTO "invoices" ("id", "amountCents", "status", "clientId", "createdAt") VALUES
  ('99999999-0000-4000-8000-000000000001', 450000, 'paid',  '22222222-0000-4000-8000-000000000001', now() - interval '6 weeks'),
  ('99999999-0000-4000-8000-000000000002', 275000, 'open',  '22222222-0000-4000-8000-000000000002', now() - interval '11 days'),
  ('99999999-0000-4000-8000-000000000003', 180000, 'draft', '22222222-0000-4000-8000-000000000003', now() - interval '2 days');

-- ------------------------------------------------------------ contracts

INSERT INTO "contracts" ("id", "title", "clientId", "leadId", "createdAt") VALUES
  ('aaaaaaaa-0000-4000-8000-000000000001', 'Cedar & Sage - 2025 Retainer Agreement',      '22222222-0000-4000-8000-000000000001', NULL, now() - interval '13 months'),
  ('aaaaaaaa-0000-4000-8000-000000000002', 'Harborline - Q4 Listing Coverage SOW',        '22222222-0000-4000-8000-000000000002', NULL, now() - interval '7 weeks'),
  ('aaaaaaaa-0000-4000-8000-000000000003', 'Ironwood Workshop Story - Proposal v2',       NULL, '44444444-0000-4000-8000-000000000003', now() - interval '4 weeks');

-- ---------------------------------------------------------- attachments

INSERT INTO "attachments" ("id", "filename", "url", "clientId", "leadId", "createdAt") VALUES
  ('bbbbbbbb-0000-4000-8000-000000000001', 'autumn-menu-moodboard.pdf',   'https://files.example.com/dev/autumn-menu-moodboard.pdf',   '22222222-0000-4000-8000-000000000001', NULL, now() - interval '20 days'),
  ('bbbbbbbb-0000-4000-8000-000000000002', 'brennan-house-floorplan.png', 'https://files.example.com/dev/brennan-house-floorplan.png', '22222222-0000-4000-8000-000000000003', NULL, now() - interval '3 months'),
  ('bbbbbbbb-0000-4000-8000-000000000003', 'tidewater-brand-guide.pdf',   'https://files.example.com/dev/tidewater-brand-guide.pdf',   NULL, '44444444-0000-4000-8000-000000000001', now() - interval '5 days');

-- ----------------------------------------------------------- locations
-- Location.coordinates is a PostGIS geography(Point, 4326). The dev image is
-- postgis/postgis:17-3.5-alpine (see docker-compose.yml) so the extension is
-- there, but the guard below keeps this seed runnable against a stock Postgres
-- instead of failing the whole transaction. TypeORM cannot create this table on
-- its own either: LocationModule never registers the entity with forFeature.

DO $location$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
    RAISE NOTICE 'PostGIS not installed - skipping the "location" table and its 3 seed rows.';
    RETURN;
  END IF;

  EXECUTE $ddl$
    CREATE TABLE IF NOT EXISTS "location" (
      "id"               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      "name"             character varying NOT NULL,
      "state"            character varying NOT NULL,
      "nationalPark"     boolean NOT NULL,
      "nationalParkName" character varying,
      "updatedByUserId"  uuid REFERENCES "user" ("id") ON DELETE SET NULL,
      "createdAt"        timestamptz NOT NULL DEFAULT now(),
      "updatedAt"        timestamptz NOT NULL DEFAULT now(),
      "coordinates"      geography(Point, 4326) NOT NULL,
      "accuracyMeters"   real
    )
  $ddl$;

  EXECUTE $idx$
    CREATE INDEX IF NOT EXISTS "IDX_location_coordinates"
      ON "location" USING GIST ("coordinates")
  $idx$;

  EXECUTE $del$ DELETE FROM "location" WHERE "id"::text LIKE 'cccccccc-%' $del$;

  -- Coordinates are [longitude, latitude], WGS84.
  EXECUTE $ins$
    INSERT INTO "location" ("id", "name", "state", "nationalPark", "nationalParkName", "updatedByUserId", "coordinates", "accuracyMeters") VALUES
      ('cccccccc-0000-4000-8000-000000000001', 'Tunnel View',  'CA', true,  'Yosemite National Park',    (SELECT "id" FROM "seed_owner"), ST_SetSRID(ST_MakePoint(-119.6769, 37.7153), 4326)::geography, 4.5),
      ('cccccccc-0000-4000-8000-000000000002', 'Mesa Arch',    'UT', true,  'Canyonlands National Park', (SELECT "id" FROM "seed_owner"), ST_SetSRID(ST_MakePoint(-109.8686, 38.3887), 4326)::geography, 12.0),
      ('cccccccc-0000-4000-8000-000000000003', 'Cannon Beach', 'OR', false, NULL,                        (SELECT "id" FROM "seed_owner"), ST_SetSRID(ST_MakePoint(-123.9615, 45.8918), 4326)::geography, NULL)
  $ins$;
END
$location$;

COMMIT;
