-- ====================================================================
-- PostgreSQL Per-Table AUTOVACUUM Tuning Script 
--
-- This script enables autovacuum and applies a comprehensive, tiered
-- tuning strategy to all tables that previously had autovacuum disabled.
--
-- Key Improvements:
--  1. Explicitly sets 'autovacuum_enabled = true' for all tables.
--  2. Adds vacuum settings (scale factor, threshold) to all tiers
--     to actively combat table bloat.
--  3. Consolidates all parameters into a single ALTER TABLE command
--     per table for clarity and efficiency.
-- ====================================================================

-- ====================================================================
-- Tier 1: Critical Churn Tables (Aggressive VACUUM & ANALYZE)
--
-- Goal: Prevent bloat and keep stats fresh in queue-like tables with
-- millions of updates/deletes.
-- ====================================================================

-- Justification: These tables function as high-speed queues. An aggressive
-- vacuum strategy (low scale factor, moderate threshold) is essential.
-- Analyze is also made more frequent than the default.
DO $$
DECLARE
    t_name TEXT;
    tables_to_tune TEXT[] := ARRAY[
        'MassTransitOutboxMessage',
        'MassTransitOutboxState'
    ];
BEGIN
    FOREACH t_name IN ARRAY tables_to_tune
    LOOP
        EXECUTE format('ALTER TABLE %I SET (
            autovacuum_enabled = true,
            autovacuum_vacuum_scale_factor = 0.01,
            autovacuum_vacuum_threshold = 1000,
            autovacuum_analyze_scale_factor = 0.05,
            autovacuum_analyze_threshold = 1000
        )', t_name);
    END LOOP;
END $$;

-- ====================================================================
-- Tier 2: Extremely Large Tables (Aggressive ANALYZE, Responsive VACUUM)
--
-- Goal: Keep planner statistics fresh and prevent catastrophic bloat
-- for tables with hundreds of millions to billions of rows.
-- ====================================================================

-- Justification:
-- ANALYZE: A tiny scale factor (0.1%) is critical for the query planner.
-- VACUUM: The default 20% scale factor would mean waiting for hundreds of
-- millions of dead rows. A lower scale factor (1%) and a high fixed
-- threshold prevents this, ensuring bloat is managed proactively.

DO $$
DECLARE
    t_name TEXT;
    tables_to_tune TEXT[] := ARRAY[
        'Actor',
        'Attachment',
        'AttachmentUrl',
        'DialogGuiAction',
        'DialogApiAction',
        'DialogApiActionEndpoint',
        'DialogContent',
        'DialogActivity',
        'DialogTransmission',
        'DialogTransmissionContent',
        'DialogEndUserContext',
        'Dialog',
        'Localization',
        'LocalizationSet'
    ];
BEGIN
    FOREACH t_name IN ARRAY tables_to_tune
    LOOP
        EXECUTE format('ALTER TABLE %I SET (
            autovacuum_enabled = true,
            autovacuum_vacuum_scale_factor = 0.01,
            autovacuum_vacuum_threshold = 10000,
            autovacuum_analyze_scale_factor = 0.001
        )', t_name);
    END LOOP;
END $$;

-- ====================================================================
-- Tier 3: Large Append-Mostly Tables (Responsive ANALYZE & VACUUM)
--
-- Goal: Ensure timely statistics updates and bloat management for
-- tables with millions of rows.
-- ====================================================================

-- Justification: A uniform scale factor for both ANALYZE (2%) and
-- VACUUM (5%) makes autovacuum more responsive than the defaults without
-- being overly aggressive. A fixed threshold of 5000 rows provides a
-- failsafe against large, sudden delete operations.
DO $$
DECLARE
    t_name TEXT;
    tables_to_tune TEXT[] := ARRAY[
        'DialogSeenLog',
        'DialogSearchTag',
        'ActorName',
        'DialogServiceOwnerContext'
    ];
BEGIN
    FOREACH t_name IN ARRAY tables_to_tune
    LOOP
        EXECUTE format('ALTER TABLE %I SET (
            autovacuum_enabled = true,
            autovacuum_vacuum_scale_factor = 0.05,
            autovacuum_vacuum_threshold = 5000,
            autovacuum_analyze_scale_factor = 0.02,
            autovacuum_analyze_threshold = 5000
        )', t_name);
    END LOOP;
END $$;


-- ====================================================================
-- After applying these settings, it is wise to run a manual ANALYZE
-- on the tables one last time to ensure the planner has fresh
-- stats immediately.
--
-- Example:
-- 
-- ANALYZE VERBOSE public."Localization";
-- ANALYZE VERBOSE public."LocalizationSet";
-- ANALYZE VERBOSE public."Dialog";
-- ANALYZE VERBOSE public."DialogSearchTag";
-- ANALYZE VERBOSE public."DialogApiActionEndpoint";
-- ANALYZE VERBOSE public."DialogApiAction";
-- ANALYZE VERBOSE public."DialogContent";
-- ANALYZE VERBOSE public."Attachment";
-- ANALYZE VERBOSE public."AttachmentUrl";
-- ANALYZE VERBOSE public."Actor";
-- ANALYZE VERBOSE public."DialogActivity";
-- ANALYZE VERBOSE public."DialogGuiAction";
-- ANALYZE VERBOSE public."DialogTransmissionContent";
-- ANALYZE VERBOSE public."DialogEndUserContext";
-- ANALYZE VERBOSE public."DialogTransmission";
-- ANALYZE VERBOSE public."MassTransitOutboxMessage";
-- ANALYZE VERBOSE public."MassTransitOutboxState";
--
-- Then, monitor the output of the following query over the next few days
-- to confirm that 'last_autovacuum' and 'last_autoanalyze' are updating:
--
--   SELECT relname, last_autovacuum, last_autoanalyze, n_live_tup, n_dead_tup
--   FROM pg_stat_user_tables
--   WHERE relname IN ('Dialog', 'Localization', 'MassTransitOutboxMessage');
-- 
-- 
-- This displays current auto_* settings for all tables
-- 
-- SELECT
--     n.nspname AS schema_name,
--     c.relname AS table_name,
--     MAX(CASE WHEN kv.key = 'autovacuum_enabled' THEN kv.value ELSE NULL END) AS autovacuum_enabled,
--     MAX(CASE WHEN kv.key = 'autovacuum_vacuum_threshold' THEN kv.value ELSE NULL END) AS vacuum_threshold,
--     MAX(CASE WHEN kv.key = 'autovacuum_vacuum_scale_factor' THEN kv.value ELSE NULL END) AS vacuum_scale_factor,
--     MAX(CASE WHEN kv.key = 'autovacuum_analyze_threshold' THEN kv.value ELSE NULL END) AS analyze_threshold,
--     MAX(CASE WHEN kv.key = 'autovacuum_analyze_scale_factor' THEN kv.value ELSE NULL END) AS analyze_scale_factor
-- FROM pg_class c
-- JOIN pg_namespace n ON n.oid = c.relnamespace
-- LEFT JOIN LATERAL (
--     SELECT
--         split_part(opt, '=', 1) AS key,
--         split_part(opt, '=', 2) AS value
--     FROM unnest(c.reloptions) AS opt
-- ) kv ON TRUE
-- WHERE c.relkind = 'r' -- regular table
--   AND n.nspname NOT IN ('pg_catalog', 'information_schema')
-- GROUP BY n.nspname, c.relname
-- ORDER BY n.nspname, c.relname;
-- ====================================================================
