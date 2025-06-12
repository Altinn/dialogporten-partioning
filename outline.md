### **Strategy Outline: Phased Partitioning & Clustering**

This document outlines a strategy to ensure high performance and scalability for the `Dialog` table and its related queries. It targets the most critical bottlenecks: slow lookups on the `Dialog` table and inefficient `JOIN`s to its direct children.

#### **1. Architectural Strategy**

* **Partition `Dialog` Table:** The `Dialog` table will be partitioned using the two-level scheme: first by `RANGE(ContentUpdatedAt)`, then sub-partitioned by `HASH("Party")`. This provides both query performance and a foundation for data lifecycle management.

* **Cluster Child Tables:** Large child and grandchild tables in the transactional hierarchy (e.g., `DialogActivity`, `Actor`) will **not** be partitioned at this stage. Instead, they will be physically clustered (`pg_repack`) by their parent's foreign key (e.g., `DialogId`, `ActivityId`) to optimize `JOIN`s.

* **Shared Reference Tables:** Shared lookup tables (e.g., `ActorName`) will remain as standard, non-partitioned tables.

#### **2. Implementation Examples**

**a. Define the Partitioned `Dialog` Table:**

```sql
-- The new table structure with a two-level partitioning definition.
-- The primary key must include all partition key columns.
CREATE TABLE "Dialog" (
    "Id" uuid NOT NULL,
    "ContentUpdatedAt" timestamptz NOT NULL,
    "Party" varchar(255) NOT NULL,
    -- ... other columns
    PRIMARY KEY ("Id", "ContentUpdatedAt", "Party")
) PARTITION BY RANGE ("ContentUpdatedAt");
```

**b. Automate Partition Creation with `pg_partman`:**
This requires a template table that defines the sub-partition structure.

```sql
-- Step 1: Create a template table that defines the second partition level.
CREATE TABLE public.dialog_template (
    "Id" uuid NOT NULL,
    "ContentUpdatedAt" timestamptz NOT NULL,
    "Party" varchar(255) NOT NULL,
    -- ... other columns
    PRIMARY KEY ("Id", "ContentUpdatedAt", "Party")
) PARTITION BY HASH ("Party");

-- Step 2: Create the hash sub-partitions on the template table.
-- pg_partman will copy this structure for each new time-slice partition.
CREATE TABLE public.dialog_template_p0 PARTITION OF public.dialog_template FOR VALUES WITH (MODULUS 64, REMAINDER 0);
-- ... and so on for all 64 sub-partitions.

-- Step 3: Configure pg_partman to use the template.
SELECT partman.create_parent(
    p_parent_table := 'public.Dialog',
    p_control := 'ContentUpdatedAt',
    p_type := 'native',
    p_interval := '1 month',
    p_premake := 4,
    p_template_table := 'public.dialog_template'
);
```

**c. Define Indexes:**

```sql
-- Composite index on the partition keys for efficient filtering and sorting.
CREATE INDEX ON "Dialog" ("Party", "ContentUpdatedAt" DESC);

-- Global index for fast direct lookups by DialogId.
CREATE INDEX ON "Dialog" ("Id");
```

#### **3. Performance Impact**

* **`Dialog` Lookups:** Will be extremely fast due to partition pruning.

* **`JOIN`s:** Will be significantly faster. Instead of random I/O across a massive child table, the join will become a fast sequential scan on a specific, physically sorted section of that table.

* **Overall:** This phase solves the most critical performance issues and will result in a dramatic improvement over the current system.

### **Future: A Theoretical Path for Extreme Future Scale**

While partitioning of dialog will solve the immediate performance issues and likely suffice for many years, it's worth understanding the theoretical "ultimate" architecture for extreme, multi-decade scale. This next phase represents a **significant increase in complexity** and should only be considered a distant future possibility if the child tables grow to an unmanageable size where clustering is no longer sufficient.

#### **1. Architectural Strategy (future)**

* **Co-locate Transactional Hierarchy:** All tables in the transactional hierarchy (`Dialog`, `DialogActivity`, `Actor`, etc.) would be partitioned using the identical two-level scheme.

* **Denormalization:** This would require the extreme step of denormalizing the `ContentUpdatedAt` and `Party` columns down to every table in the hierarchy to be used as their partition keys.

#### **2. Justification (future)**

* **Partition-Wise Joins:** The key benefit is enabling Partition-Wise Joins. The database would no longer join a small `Dialog` partition against a massive child table. Instead, it would join small, corresponding sub-partitions (e.g., `Dialog_2025_06_p17` with `Activity_2025_06_p17`). This is the most efficient way to perform `JOIN`s at extreme scale.

* **Manageable Maintenance:** `pg_repack` and `VACUUM` jobs would always run on tiny sub-partitions across the entire hierarchy, keeping them fast and non-disruptive forever.

#### **3. Implementation (future)**

* **Schema Changes:** The child tables would need to be altered to include the denormalized `Party` and `ContentUpdatedAt` columns.

* **Migration:** A live, online migration (e.g., using logical replication) would be required to move data from the monolithic child tables into the new co-partitioned structure with minimal downtime.

### **General Considerations**

#### **Query Pattern Constraints**

* **Mandatory `Party` Filter:** To be performant, all queries against the `Dialog` hierarchy must include a filter on `Party`. Queries without this filter will be slow as they cannot use hash partition pruning.

* **Time-Range for Alternate Sorts:** Queries sorting by a column other than `ContentUpdatedAt` (e.g., `CreatedAt`) should be required to include a time-range filter on `ContentUpdatedAt` to enable time-based partition pruning and prevent scans across all historical data.

#### **Entity Framework Integration**

* **Manual Migrations:** All schema changes for any partitioned table must be handled with manually written SQL inside an empty EF migration. The script must alter the parent table, the `pg_partman` template, and all existing partitions to ensure consistency.

* **Example: Adding a New Column with `migrationBuilder.Sql()`**

  ```csharp
  // Inside the Up() method of a new, empty EF Migration file.
  
  // Step 1: Alter the parent table
  migrationBuilder.Sql(@"ALTER TABLE ""Dialog"" ADD COLUMN ""NewColumn"" text NULL;");
  
  // Step 2: Alter the pg_partman template table for future partitions
  migrationBuilder.Sql(@"ALTER TABLE public.dialog_template ADD COLUMN ""NewColumn"" text NULL;");
  
  // Step 3: Loop through all existing partitions to apply the change.
  migrationBuilder.Sql(@"
      DO $$
      DECLARE
          partition_name text;
      BEGIN
          FOR partition_name IN
              SELECT child.relname
              FROM pg_inherits
              JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
              JOIN pg_class child ON pg_inherits.inhrelid = child.oid
              WHERE parent.relname = 'dialog_template' OR parent.relname = 'Dialog'
          LOOP
              EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS ""NewColumn"" text NULL;', partition_name);
          END LOOP;
      END;
      $$;
  ");
  ```
