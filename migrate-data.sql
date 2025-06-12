-- ====================================================================
-- SCRIPT: Migrate Dialog Data and Update Foreign Keys (LARGE SCALE)
-- ====================================================================
-- DESCRIPTION:
-- This script safely handles the migration of data from "Dialog_Old"
-- to a new partitioned "Dialog" table, specifically designed for
-- tables with millions of rows (e.g., 100M+).
--
-- METHOD (Designed for minimal downtime):
-- 1. DROPS all foreign key constraints from child tables that point to
--    "Dialog_Old". This is done first to prevent errors and locks.
-- 2. Migrates data in small, manageable batches using a LOOP. Each
--    batch is its own transaction to minimize lock time and resource usage.
-- 3. RE-CREATES the foreign key constraints as 'NOT VALID' after the
--    data migration is complete. This is a fast, metadata-only change.
-- 4. VALIDATES the constraints in a final, automated step. This step is
--    resource-intensive and will lock tables.
--
-- WARNING:
-- During Step 2 (the data migration loop), your database will operate
-- without foreign key integrity between the child tables and the Dialog
-- table. This is a necessary trade-off for a migration of this scale.
-- ====================================================================

DO $$
BEGIN
    RAISE INFO 'Starting LARGE SCALE Dialog data migration script...';
END;
$$;


-- ====================================================================
-- STEP 1: DROP ALL FOREIGN KEY CONSTRAINTS
-- ====================================================================
RAISE INFO 'STEP 1: Dropping foreign key constraints pointing to Dialog_Old...';
BEGIN;
    ALTER TABLE public."Attachment" DROP CONSTRAINT IF EXISTS "FK_Attachment_Dialog_DialogId";
    ALTER TABLE public."DialogActivity" DROP CONSTRAINT IF EXISTS "FK_DialogActivity_Dialog_DialogId";
    ALTER TABLE public."DialogApiAction" DROP CONSTRAINT IF EXISTS "FK_DialogApiAction_Dialog_DialogId";
    ALTER TABLE public."DialogContent" DROP CONSTRAINT IF EXISTS "FK_DialogContent_Dialog_DialogId";
    ALTER TABLE public."DialogEndUserContext" DROP CONSTRAINT IF EXISTS "FK_DialogEndUserContext_Dialog_DialogId";
    ALTER TABLE public."DialogGuiAction" DROP CONSTRAINT IF EXISTS "FK_DialogGuiAction_Dialog_DialogId";
    ALTER TABLE public."DialogSearchTag" DROP CONSTRAINT IF EXISTS "FK_DialogSearchTag_Dialog_DialogId";
    ALTER TABLE public."DialogSeenLog" DROP CONSTRAINT IF EXISTS "FK_DialogSeenLog_Dialog_DialogId";
    ALTER TABLE public."DialogServiceOwnerContext" DROP CONSTRAINT IF EXISTS "FK_DialogServiceOwnerContext_Dialog_DialogId";
    ALTER TABLE public."DialogTransmission" DROP CONSTRAINT IF EXISTS "FK_DialogTransmission_Dialog_DialogId";
COMMIT;
RAISE INFO 'All relevant foreign keys have been dropped.';


-- ====================================================================
-- STEP 2: DATA MIGRATION IN BATCHES
-- ====================================================================
RAISE INFO 'STEP 2: Starting batched data migration from Dialog_Old to Dialog...';
DO $$
DECLARE
    batch_size INT := 50000; -- Tune batch size based on your server's capacity
    rows_migrated INT;
    total_rows_migrated BIGINT := 0;
    last_id uuid := '00000000-0000-0000-0000-000000000000'; -- Start with the lowest possible UUID
    current_batch_last_id uuid;
BEGIN
    LOOP
        -- Find the last ID from the rows to be inserted in this batch
        SELECT "Id" INTO current_batch_last_id FROM public."Dialog_Old" WHERE "Id" > last_id ORDER BY "Id" ASC LIMIT 1 OFFSET (batch_size - 1);

        -- If no more rows, we are done with this batch size.
        IF current_batch_last_id IS NULL THEN
            -- Handle the final, smaller batch
            INSERT INTO public."Dialog"
            SELECT * FROM public."Dialog_Old" WHERE "Id" > last_id;
            GET DIAGNOSTICS rows_migrated = ROW_COUNT;
            total_rows_migrated := total_rows_migrated + rows_migrated;
            RAISE INFO 'Migrated final batch of % rows. Total migrated: %', rows_migrated, total_rows_migrated;
            EXIT; -- Exit the loop
        END IF;

        -- Insert a full batch of rows up to and including the found last ID
        INSERT INTO public."Dialog"
        SELECT * FROM public."Dialog_Old" WHERE "Id" > last_id AND "Id" <= current_batch_last_id;

        GET DIAGNOSTICS rows_migrated = ROW_COUNT;
        total_rows_migrated := total_rows_migrated + rows_migrated;

        RAISE INFO 'Migrated batch of % rows. Total migrated: %. Last ID in batch: %', rows_migrated, total_rows_migrated, current_batch_last_id;

        -- Set the starting point for the next batch
        last_id := current_batch_last_id;

        -- Small delay to yield resources if needed
        -- PERFORM pg_sleep(0.1);

    END LOOP;
    RAISE INFO 'Finished migrating all data.';
END;
$$;


-- ====================================================================
-- STEP 3: RE-CREATE FOREIGN KEY CONSTRAINTS (as NOT VALID)
-- ====================================================================
RAISE INFO 'STEP 3: Re-creating foreign key constraints as NOT VALID...';
BEGIN;
    ALTER TABLE public."Attachment" ADD CONSTRAINT "FK_Attachment_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogActivity" ADD CONSTRAINT "FK_DialogActivity_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogApiAction" ADD CONSTRAINT "FK_DialogApiAction_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogContent" ADD CONSTRAINT "FK_DialogContent_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogEndUserContext" ADD CONSTRAINT "FK_DialogEndUserContext_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE SET NULL NOT VALID;
    ALTER TABLE public."DialogGuiAction" ADD CONSTRAINT "FK_DialogGuiAction_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogSearchTag" ADD CONSTRAINT "FK_DialogSearchTag_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogSeenLog" ADD CONSTRAINT "FK_DialogSeenLog_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogServiceOwnerContext" ADD CONSTRAINT "FK_DialogServiceOwnerContext_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
    ALTER TABLE public."DialogTransmission" ADD CONSTRAINT "FK_DialogTransmission_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE NOT VALID;
COMMIT;
RAISE INFO 'All foreign key constraints have been re-created as NOT VALID.';


-- ====================================================================
-- STEP 4: VALIDATE CONSTRAINTS
--
-- !! IMPORTANT !!
-- This step is resource-intensive and will lock tables. It is STRONGLY
-- recommended to run this during a low-traffic maintenance window.
-- ====================================================================
RAISE INFO 'STEP 4: Beginning validation of all new constraints. This may take a long time.';
BEGIN;
    RAISE INFO 'Validating constraint on "Attachment"...';
    ALTER TABLE public."Attachment" VALIDATE CONSTRAINT "FK_Attachment_Dialog_DialogId";
    RAISE INFO 'Constraint on "Attachment" validated.';

    RAISE INFO 'Validating constraint on "DialogActivity"...';
    ALTER TABLE public."DialogActivity" VALIDATE CONSTRAINT "FK_DialogActivity_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogActivity" validated.';

    RAISE INFO 'Validating constraint on "DialogApiAction"...';
    ALTER TABLE public."DialogApiAction" VALIDATE CONSTRAINT "FK_DialogApiAction_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogApiAction" validated.';

    RAISE INFO 'Validating constraint on "DialogContent"...';
    ALTER TABLE public."DialogContent" VALIDATE CONSTRAINT "FK_DialogContent_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogContent" validated.';

    RAISE INFO 'Validating constraint on "DialogEndUserContext"...';
    ALTER TABLE public."DialogEndUserContext" VALIDATE CONSTRAINT "FK_DialogEndUserContext_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogEndUserContext" validated.';

    RAISE INFO 'Validating constraint on "DialogGuiAction"...';
    ALTER TABLE public."DialogGuiAction" VALIDATE CONSTRAINT "FK_DialogGuiAction_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogGuiAction" validated.';

    RAISE INFO 'Validating constraint on "DialogSearchTag"...';
    ALTER TABLE public."DialogSearchTag" VALIDATE CONSTRAINT "FK_DialogSearchTag_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogSearchTag" validated.';

    RAISE INFO 'Validating constraint on "DialogSeenLog"...';
    ALTER TABLE public."DialogSeenLog" VALIDATE CONSTRAINT "FK_DialogSeenLog_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogSeenLog" validated.';

    RAISE INFO 'Validating constraint on "DialogServiceOwnerContext"...';
    ALTER TABLE public."DialogServiceOwnerContext" VALIDATE CONSTRAINT "FK_DialogServiceOwnerContext_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogServiceOwnerContext" validated.';

    RAISE INFO 'Validating constraint on "DialogTransmission"...';
    ALTER TABLE public."DialogTransmission" VALIDATE CONSTRAINT "FK_DialogTransmission_Dialog_DialogId";
    RAISE INFO 'Constraint on "DialogTransmission" validated.';
COMMIT;
RAISE INFO 'All constraints have been successfully validated.';


-- ====================================================================
-- POST-SCRIPT ACTIONS:
-- 1. CLEANUP: Once all constraints are validated and you have verified
--    the application, you can safely drop the old table.
--
--    DROP TABLE public."Dialog_Old";
-- ====================================================================
DO $$
BEGIN
    RAISE INFO 'Migration script finished successfully!';
END;
$$;
