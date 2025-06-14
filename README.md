# Partitioning Setup

This repository includes a SQL script for enabling two-level partitioning using [`pg_partman`](https://github.com/pgpartman/pg_partman).

## Running the script

Run the following command against your database:

```sh
psql -f scripts/setup_partitioning.sql
```

The script installs `pg_partman`, converts `Dialog` and related tables to a
monthly range partitioning scheme with 64 hash sub-partitions, adds indexes for
efficient lookups, backfills partition keys through the entire table hierarchy,
and generates partitions for all months already present in the `Dialog` table.
