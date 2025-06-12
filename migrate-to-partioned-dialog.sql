-- ====================================================================
-- SCRIPT TO MIGRATE DIALOG TABLE TO A TWO-LEVEL PARTITIONED STRUCTURE
-- ====================================================================
-- This script should be run once during a planned maintenance window.
-- It renames the existing Dialog table, creates the new partitioned
-- structure, and sets up pg_partman for automatic management.
--
-- NOTE: A data migration step from Dialog_Old to the new Dialog table
-- is required after this script is run.
-- ====================================================================

BEGIN;

-- STEP 1: RENAME THE EXISTING DIALOG TABLE
-- This preserves the old data for migration.
ALTER TABLE public."Dialog" RENAME TO "Dialog_Old";

-- STEP 2: CREATE THE NEW PARTITIONED PARENT TABLE
-- This table is the main entry point but will hold no data itself.
-- NOTE: The new column "ContentUpdatedAt" is added. Assume it will be populated.
-- The Primary Key is updated to include all partition key columns.
CREATE TABLE public."Dialog" (
    "Id" uuid NOT NULL,
    "Revision" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    "ContentUpdatedAt" timestamp with time zone NOT NULL, -- The new column
    "Deleted" boolean NOT NULL,
    "DeletedAt" timestamp with time zone,
    "Org" character varying(255) NOT NULL,
    "ServiceResource" character varying(255) NOT NULL,
    "ServiceResourceType" character varying(255) NOT NULL,
    "Party" character varying(255) NOT NULL,
    "Progress" integer,
    "ExtendedStatus" character varying(255),
    "ExternalReference" character varying(255),
    "VisibleFrom" timestamp with time zone,
    "DueAt" timestamp with time zone,
    "ExpiresAt" timestamp with time zone,
    "StatusId" integer NOT NULL,
    "PrecedingProcess" character varying(255),
    "Process" character varying(255),
    "IdempotentKey" character varying(36),
    "IsApiOnly" boolean NOT NULL,
    PRIMARY KEY ("Id", "ContentUpdatedAt", "Party")
) PARTITION BY RANGE ("ContentUpdatedAt");

-- STEP 3: CREATE THE PG_PARTMAN TEMPLATE TABLE FOR SUB-PARTITIONING
-- This defines the structure of the HASH sub-partitions.
CREATE TABLE public.dialog_template (
    "Id" uuid NOT NULL,
    "Revision" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL,
    "ContentUpdatedAt" timestamp with time zone NOT NULL,
    "Deleted" boolean NOT NULL,
    "DeletedAt" timestamp with time zone,
    "Org" character varying(255) NOT NULL,
    "ServiceResource" character varying(255) NOT NULL,
    "ServiceResourceType" character varying(255) NOT NULL,
    "Party" character varying(255) NOT NULL,
    "Progress" integer,
    "ExtendedStatus" character varying(255),
    "ExternalReference" character varying(255),
    "VisibleFrom" timestamp with time zone,
    "DueAt" timestamp with time zone,
    "ExpiresAt" timestamp with time zone,
    "StatusId" integer NOT NULL,
    "PrecedingProcess" character varying(255),
    "Process" character varying(255),
    "IdempotentKey" character varying(36),
    "IsApiOnly" boolean NOT NULL,
    PRIMARY KEY ("Id", "ContentUpdatedAt", "Party")
) PARTITION BY HASH ("Party");

-- STEP 4: CREATE THE HASH SUB-PARTITIONS ON THE TEMPLATE
-- This loop creates 64 sub-partitions for the template table.
DO $$
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format(
            'CREATE TABLE public.dialog_template_p%s PARTITION OF public.dialog_template FOR VALUES WITH (MODULUS 64, REMAINDER %s);',
            i, i
        );
    END LOOP;
END;
$$;

-- STEP 5: CONFIGURE PG_PARTMAN TO MANAGE THE 'Dialog' TABLE
-- This call automates the creation of new monthly partitions using the template.
-- It will immediately create partitions for the current month and the next 4 months.
SELECT partman.create_parent(
    p_parent_table := 'public.Dialog',
    p_control := 'ContentUpdatedAt',
    p_type := 'native',
    p_interval := '1 month',
    p_premake := 4,
    p_template_table := 'public.dialog_template'
);

-- STEP 6: CREATE INDEXES ON THE NEW PARTITIONED TABLE
-- These indexes will be automatically created on all new and existing partitions.
-- Composite index for the primary query pattern
CREATE INDEX ON public."Dialog" ("Party", "ContentUpdatedAt" DESC);
-- Global index for fast direct lookups by DialogId
CREATE INDEX ON public."Dialog" ("Id");
-- Re-create other important indexes from the old table
CREATE INDEX ON public."Dialog" ("StatusId");
CREATE INDEX ON public."Dialog" ("Org");
-- Add other indexes as needed...

COMMIT;

-- ====================================================================
-- POST-SCRIPT ACTIONS:
-- 1. DATA MIGRATION: You must now migrate data from "Dialog_Old" to the
--    new partitioned "Dialog" table. This can be done in batches to
--    avoid long transactions.
--
-- 2. FOREIGN KEYS: After data migration, update all tables that had a
--    foreign key to "Dialog_Old" to now point to the new "Dialog" table.
--    This may require dropping and re-creating the constraints.
-- ====================================================================
