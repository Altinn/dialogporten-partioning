-- Setup partitioning for Dialog and related tables
-- Requires pg_partman extension

CREATE EXTENSION IF NOT EXISTS pg_partman;

-- Indexes for efficient filtering and lookups
CREATE INDEX IF NOT EXISTS idx_dialog_party_updatedat
    ON public."Dialog" ("Party", "ContentUpdatedAt" DESC);

CREATE INDEX IF NOT EXISTS idx_dialog_id
    ON public."Dialog" ("Id");

-- Template for Dialog
CREATE TABLE IF NOT EXISTS public.dialog_template (LIKE public."Dialog" INCLUDING ALL)
    PARTITION BY HASH ("Party");

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('CREATE TABLE IF NOT EXISTS public.dialog_template_p%s PARTITION OF public.dialog_template FOR VALUES WITH (MODULUS 64, REMAINDER %s);', i, i);
    END LOOP;
END$$;

-- Convert Dialog into a range partitioned table
ALTER TABLE public."Dialog"
    PARTITION BY RANGE ("ContentUpdatedAt");

-- Register Dialog with partman using the template
SELECT partman.create_parent('public."Dialog"', 'ContentUpdatedAt', 'native', '1 month', p_template_table := 'public.dialog_template');

-- Child tables directly referencing Dialog
DO $$
DECLARE
    tbl text;
    template text;
    i integer;
    tables text[] := ARRAY[
        'Attachment',
        'DialogActivity',
        'DialogApiAction',
        'DialogContent',
        'DialogEndUserContext',
        'DialogGuiAction',
        'DialogSearchTag',
        'DialogSeenLog',
        'DialogServiceOwnerContext',
        'DialogTransmission',
        'Actor',
        'AttachmentUrl',
        'DialogApiActionEndpoint',
        'DialogServiceOwnerLabel',
        'DialogTransmissionContent',
        'LabelAssignmentLog',
        'LocalizationSet',
        'Localization'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        -- Ensure columns for co-located partitioning
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'Party') THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN "Party" varchar(255);', tbl);
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'ContentUpdatedAt') THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN "ContentUpdatedAt" timestamptz;', tbl);
        END IF;

        -- Indexes on the partition keys
        EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_party_updatedat ON public."%s" ("Party", "ContentUpdatedAt" DESC);', lower(tbl), tbl);
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'Id') THEN
            EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_id ON public."%s" ("Id");', lower(tbl), tbl);
        END IF;

        template := 'public.' || lower(tbl) || '_template';
        EXECUTE format('CREATE TABLE IF NOT EXISTS %s (LIKE public."%s" INCLUDING ALL) PARTITION BY HASH ("Party");', template, tbl);
        FOR i IN 0..63 LOOP
            EXECUTE format('CREATE TABLE IF NOT EXISTS %s_p%s PARTITION OF %s FOR VALUES WITH (MODULUS 64, REMAINDER %s);', template, i, template, i);
        END LOOP;
        EXECUTE format('ALTER TABLE public."%s" PARTITION BY RANGE ("ContentUpdatedAt");', tbl);
        EXECUTE format('SELECT partman.create_parent(''public."%s"'', ''ContentUpdatedAt'', ''native'', ''1 month'', p_template_table := ''%s'');', tbl, template);
    END LOOP;
END$$;

-- Backfill Party and ContentUpdatedAt for all descendants
DO $$
BEGIN
    -- Attachment direct
    UPDATE public."Attachment" a
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE a."DialogId" = d."Id"
      AND (a."Party" IS NULL OR a."ContentUpdatedAt" IS NULL);

    -- Attachment via Transmission
    UPDATE public."Attachment" a
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogTransmission" t
    JOIN public."Dialog" d ON t."DialogId" = d."Id"
    WHERE a."TransmissionId" = t."Id"
      AND (a."Party" IS NULL OR a."ContentUpdatedAt" IS NULL);

    -- DialogActivity direct
    UPDATE public."DialogActivity" da
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE da."DialogId" = d."Id"
      AND (da."Party" IS NULL OR da."ContentUpdatedAt" IS NULL);

    -- DialogActivity via Transmission
    UPDATE public."DialogActivity" da
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogTransmission" t
    JOIN public."Dialog" d ON t."DialogId" = d."Id"
    WHERE da."TransmissionId" = t."Id"
      AND (da."Party" IS NULL OR da."ContentUpdatedAt" IS NULL);

    -- DialogApiAction
    UPDATE public."DialogApiAction" a
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE a."DialogId" = d."Id"
      AND (a."Party" IS NULL OR a."ContentUpdatedAt" IS NULL);

    -- DialogApiActionEndpoint
    UPDATE public."DialogApiActionEndpoint" e
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogApiAction" a
    JOIN public."Dialog" d ON a."DialogId" = d."Id"
    WHERE e."ActionId" = a."Id"
      AND (e."Party" IS NULL OR e."ContentUpdatedAt" IS NULL);

    -- DialogContent
    UPDATE public."DialogContent" c
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE c."DialogId" = d."Id"
      AND (c."Party" IS NULL OR c."ContentUpdatedAt" IS NULL);

    -- DialogEndUserContext
    UPDATE public."DialogEndUserContext" c
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE c."DialogId" = d."Id"
      AND (c."Party" IS NULL OR c."ContentUpdatedAt" IS NULL);

    -- DialogGuiAction
    UPDATE public."DialogGuiAction" g
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE g."DialogId" = d."Id"
      AND (g."Party" IS NULL OR g."ContentUpdatedAt" IS NULL);

    -- DialogSearchTag
    UPDATE public."DialogSearchTag" s
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE s."DialogId" = d."Id"
      AND (s."Party" IS NULL OR s."ContentUpdatedAt" IS NULL);

    -- DialogSeenLog
    UPDATE public."DialogSeenLog" sl
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE sl."DialogId" = d."Id"
      AND (sl."Party" IS NULL OR sl."ContentUpdatedAt" IS NULL);

    -- DialogServiceOwnerContext
    UPDATE public."DialogServiceOwnerContext" soc
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE soc."DialogId" = d."Id"
      AND (soc."Party" IS NULL OR soc."ContentUpdatedAt" IS NULL);

    -- DialogServiceOwnerLabel
    UPDATE public."DialogServiceOwnerLabel" sol
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogServiceOwnerContext" soc
    JOIN public."Dialog" d ON soc."DialogId" = d."Id"
    WHERE sol."DialogServiceOwnerContextId" = soc."DialogId"
      AND (sol."Party" IS NULL OR sol."ContentUpdatedAt" IS NULL);

    -- DialogTransmission
    UPDATE public."DialogTransmission" t
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Dialog" d
    WHERE t."DialogId" = d."Id"
      AND (t."Party" IS NULL OR t."ContentUpdatedAt" IS NULL);

    -- DialogTransmissionContent
    UPDATE public."DialogTransmissionContent" tc
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogTransmission" t
    JOIN public."Dialog" d ON t."DialogId" = d."Id"
    WHERE tc."TransmissionId" = t."Id"
      AND (tc."Party" IS NULL OR tc."ContentUpdatedAt" IS NULL);

    -- LabelAssignmentLog
    UPDATE public."LabelAssignmentLog" l
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogEndUserContext" c
    JOIN public."Dialog" d ON c."DialogId" = d."Id"
    WHERE l."ContextId" = c."Id"
      AND (l."Party" IS NULL OR l."ContentUpdatedAt" IS NULL);

    -- Actor via Activity
    UPDATE public."Actor" a
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogActivity" da
    JOIN public."Dialog" d ON da."DialogId" = d."Id"
    WHERE a."ActivityId" = da."Id"
      AND (a."Party" IS NULL OR a."ContentUpdatedAt" IS NULL);

    -- Actor via Transmission
    UPDATE public."Actor" a
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogTransmission" t
    JOIN public."Dialog" d ON t."DialogId" = d."Id"
    WHERE a."TransmissionId" = t."Id"
      AND (a."Party" IS NULL OR a."ContentUpdatedAt" IS NULL);

    -- Actor via SeenLog
    UPDATE public."Actor" a
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogSeenLog" sl
    JOIN public."Dialog" d ON sl."DialogId" = d."Id"
    WHERE a."DialogSeenLogId" = sl."Id"
      AND (a."Party" IS NULL OR a."ContentUpdatedAt" IS NULL);

    -- Actor via LabelAssignmentLog
    UPDATE public."Actor" a
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."LabelAssignmentLog" l
    JOIN public."DialogEndUserContext" c ON l."ContextId" = c."Id"
    JOIN public."Dialog" d ON c."DialogId" = d."Id"
    WHERE a."LabelAssignmentLogId" = l."Id"
      AND (a."Party" IS NULL OR a."ContentUpdatedAt" IS NULL);

    -- AttachmentUrl via Attachment
    UPDATE public."AttachmentUrl" u
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Attachment" a
    JOIN public."Dialog" d ON a."DialogId" = d."Id"
    WHERE u."AttachmentId" = a."Id"
      AND (u."Party" IS NULL OR u."ContentUpdatedAt" IS NULL);

    UPDATE public."AttachmentUrl" u
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Attachment" a
    JOIN public."DialogTransmission" t ON a."TransmissionId" = t."Id"
    JOIN public."Dialog" d ON t."DialogId" = d."Id"
    WHERE u."AttachmentId" = a."Id"
      AND (u."Party" IS NULL OR u."ContentUpdatedAt" IS NULL);

    -- LocalizationSet via various parents
    UPDATE public."LocalizationSet" ls
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogActivity" da
    JOIN public."Dialog" d ON da."DialogId" = d."Id"
    WHERE ls."ActivityId" = da."Id"
      AND (ls."Party" IS NULL OR ls."ContentUpdatedAt" IS NULL);

    UPDATE public."LocalizationSet" ls
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Attachment" a
    JOIN public."Dialog" d ON a."DialogId" = d."Id"
    WHERE ls."AttachmentId" = a."Id"
      AND (ls."Party" IS NULL OR ls."ContentUpdatedAt" IS NULL);

    UPDATE public."LocalizationSet" ls
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."Attachment" a
    JOIN public."DialogTransmission" t ON a."TransmissionId" = t."Id"
    JOIN public."Dialog" d ON t."DialogId" = d."Id"
    WHERE ls."AttachmentId" = a."Id"
      AND (ls."Party" IS NULL OR ls."ContentUpdatedAt" IS NULL);

    UPDATE public."LocalizationSet" ls
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogContent" dc
    JOIN public."Dialog" d ON dc."DialogId" = d."Id"
    WHERE ls."DialogContentId" = dc."Id"
      AND (ls."Party" IS NULL OR ls."ContentUpdatedAt" IS NULL);

    UPDATE public."LocalizationSet" ls
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogGuiAction" ga
    JOIN public."Dialog" d ON ga."DialogId" = d."Id"
    WHERE ls."DialogGuiActionPrompt_GuiActionId" = ga."Id"
      AND (ls."Party" IS NULL OR ls."ContentUpdatedAt" IS NULL);

    UPDATE public."LocalizationSet" ls
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogGuiAction" ga
    JOIN public."Dialog" d ON ga."DialogId" = d."Id"
    WHERE ls."GuiActionId" = ga."Id"
      AND (ls."Party" IS NULL OR ls."ContentUpdatedAt" IS NULL);

    UPDATE public."LocalizationSet" ls
    SET "Party" = d."Party", "ContentUpdatedAt" = d."ContentUpdatedAt"
    FROM public."DialogTransmissionContent" tc
    JOIN public."DialogTransmission" t ON tc."TransmissionId" = t."Id"
    JOIN public."Dialog" d ON t."DialogId" = d."Id"
    WHERE ls."TransmissionContentId" = tc."Id"
      AND (ls."Party" IS NULL OR ls."ContentUpdatedAt" IS NULL);

    -- Localization from LocalizationSet
    UPDATE public."Localization" l
    SET "Party" = ls."Party", "ContentUpdatedAt" = ls."ContentUpdatedAt"
    FROM public."LocalizationSet" ls
    WHERE l."LocalizationSetId" = ls."Id"
      AND (l."Party" IS NULL OR l."ContentUpdatedAt" IS NULL);

END$$;
-- Create partitions for all months present in Dialog
DO $$
DECLARE
    start_date date;
    end_date date;
    current date;
    tbl text;
    tables text[] := ARRAY['Dialog',
        'Attachment',
        'DialogActivity',
        'DialogApiAction',
        'DialogContent',
        'DialogEndUserContext',
        'DialogGuiAction',
        'DialogSearchTag',
        'DialogSeenLog',
        'DialogServiceOwnerContext',
        'DialogTransmission',
        'Actor',
        'AttachmentUrl',
        'DialogApiActionEndpoint',
        'DialogServiceOwnerLabel',
        'DialogTransmissionContent',
        'LabelAssignmentLog',
        'LocalizationSet',
        'Localization'
    ];
BEGIN
    SELECT date_trunc('month', min("ContentUpdatedAt"))::date INTO start_date FROM public."Dialog";
    SELECT date_trunc('month', max("ContentUpdatedAt"))::date INTO end_date FROM public."Dialog";
    current := start_date;
    WHILE current <= end_date LOOP
        FOREACH tbl IN ARRAY tables LOOP
            EXECUTE format('SELECT partman.create_partition_time(''public."%s"'', %L);', tbl, current);
        END LOOP;
        current := current + INTERVAL '1 month';
    END LOOP;
END$$;
