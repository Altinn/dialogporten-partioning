-- ====================================================================
-- SCRIPT TO MIGRATE DIALOG TABLE TO A TWO-LEVEL PARTITIONED STRUCTURE
-- ====================================================================
--
-- WARNING! This script _will_ fail unless max_locks_per_transaction is
-- increased to accomodate for creating all the partitions. This cannot be
-- done without a server restart. See postgresql.conf and set
-- max_locks_per_transaction = 10000
-- ====================================================================

BEGIN;

-- STEP 1: RENAME THE EXISTING DIALOG TABLE AND ITS PRIMARY KEY
ALTER TABLE public."Dialog" RENAME TO "Dialog_Old";
ALTER INDEX public."PK_Dialog" RENAME TO "PK_Dialog_Old";


-- STEP 2: CREATE THE NEW TOP-LEVEL PARENT TABLE
-- This table is partitioned by RANGE but holds no data itself.
CREATE TABLE public."Dialog" (
    LIKE public."Dialog_Old" INCLUDING DEFAULTS
) PARTITION BY RANGE ("ContentUpdatedAt");

-- Redefine the primary key to include all partition keys from both levels.
ALTER TABLE public."Dialog" ADD PRIMARY KEY ("Id", "ContentUpdatedAt", "Party");


-- STEP 3: CREATE THE PARTITION MANAGEMENT FUNCTION
-- This function creates a monthly partition and its 64 hash sub-partitions.
-- It is idempotent and can be run safely multiple times.
CREATE OR REPLACE FUNCTION public.make_dialog_month(p_year int, p_month int)
RETURNS void AS $$
DECLARE
    monthly_partition_name text;
    monthly_from_date date;
    monthly_to_date date;
BEGIN
    monthly_from_date := make_date(p_year, p_month, 1);
    monthly_to_date := monthly_from_date + interval '1 month';
    monthly_partition_name := 'dialog_p' || to_char(monthly_from_date, 'YYYY_MM');

    -- Create the monthly range partition if it doesn't exist.
    -- This table will be the parent for the hash sub-partitions.
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS public.%I PARTITION OF public."Dialog" FOR VALUES FROM (%L) TO (%L) PARTITION BY HASH ("Party");',
        monthly_partition_name, monthly_from_date, monthly_to_date
    );

    -- Create the 64 hash sub-partitions for this month if they don't exist.
    FOR i IN 0..63 LOOP
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS public.%I_p%s PARTITION OF public.%I FOR VALUES WITH (MODULUS 64, REMAINDER %s);',
            monthly_partition_name, i, monthly_partition_name, i
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- STEP 4: MANUALLY CREATE HISTORICAL AND RECENT PARTITIONS
-- This section creates all necessary partitions from the start date up to a few
-- months into the future. pg_cron will take over management from this point.

-- Create YEARLY partitions from 2000 to 2019
DO $$
DECLARE
    yearly_partition_name text;
    yearly_from_date date;
    yearly_to_date date;
BEGIN
    FOR year_val IN 2000..2019 LOOP
        yearly_from_date := make_date(year_val, 1, 1);
        yearly_to_date := make_date(year_val + 1, 1, 1);
        yearly_partition_name := 'dialog_y' || year_val;

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS public.%I PARTITION OF public."Dialog" FOR VALUES FROM (%L) TO (%L) PARTITION BY HASH ("Party");',
            yearly_partition_name, yearly_from_date, yearly_to_date
        );

        -- Create 64 hash sub-partitions for the yearly partition
        FOR i IN 0..63 LOOP
            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS public.%I_p%s PARTITION OF public.%I FOR VALUES WITH (MODULUS 64, REMAINDER %s);',
                yearly_partition_name, i, yearly_partition_name, i
            );
        END LOOP;
    END LOOP;
END;
$$;


-- Create MONTHLY partitions from Jan 2020 up to 4 months in the future by calling the new function
DO $$
DECLARE
    d date;
    start_date date := '2020-01-01';
    end_date date := (date_trunc('month', now()) + interval '4 months')::date;
BEGIN
    FOR d IN SELECT generate_series(start_date, end_date, '1 month'::interval) LOOP
        PERFORM public.make_dialog_month(EXTRACT(YEAR FROM d)::int, EXTRACT(MONTH FROM d)::int);
    END LOOP;
END;
$$;


-- STEP 5: CREATE INDEXES ON THE NEW PARTITIONED TABLE
-- These indexes will be automatically created on all new and existing partitions.
CREATE INDEX ON public."Dialog" ("Party", "ContentUpdatedAt" DESC);
CREATE INDEX ON public."Dialog" ("Id");


COMMIT;

-- ====================================================================
--
-- POST-SCRIPT ACTIONS:
-- 1. DATA MIGRATION: You must now migrate data from "Dialog_Old" to the
--    new partitioned "Dialog" table.
--
-- 2. FOREIGN KEYS: After migration, update foreign keys to point to the
--    new "Dialog" table.
--
-- 3. SCHEDULE FUTURE PARTITION CREATION WITH PG_CRON:
--    To ensure partitions are always available for new data, schedule a
--    job to run the make_dialog_month function.
--
--    Example: Schedule a job to run on the 1st of every month at 2 AM
--    to create partitions for the current month and the next four months.
--
--    SELECT cron.schedule(
--        'monthly-partition-maintenance',
--        '0 2 1 * *', -- Cron syntax for 2 AM on the 1st day of every month
--        $$
--        DO $do$
--        DECLARE
--          d date;
--        BEGIN
--          -- Loop from the current month to 4 months ahead
--          FOR d IN SELECT generate_series(date_trunc('month', now())::date, (date_trunc('month', now()) + interval '4 months')::date, '1 month'::interval) LOOP
--            PERFORM public.make_dialog_month(EXTRACT(YEAR FROM d)::int, EXTRACT(MONTH FROM d)::int);
--          END LOOP;
--        END;
--        $do$;
--        $$
--    );
-- ====================================================================
