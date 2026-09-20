# Database validation suite

This directory contains a standalone PostgreSQL validation harness for the
project database. It is intentionally separate from the Flask prototype because
the repository does not define a general test runner.

## Safety model

- The runner creates fresh disposable local PostgreSQL databases named
  `jousaali_db_validation_<timestamp>_<suffix>`.
- Create/drop operations are guarded by that disposable name prefix and reject
  production-looking names.
- It applies `jousaali_skript.sql` from zero, runs assertions, and drops the
  disposable databases unless `--keep-db` is provided.
- It refuses non-local PostgreSQL targets unless `--allow-nonlocal` is passed.
- It verifies the admin connection identity, rejects unsafe database-name
  samples, and checks that no `jousaali_db_validation_%` databases remain after
  cleanup.
- It does not read the Flask `.env` file and does not use the application
  `DB_NAME`, so the normal demo database is not touched.
- The schema script may create prototype roles named `jousaali_rakendus` and
  `jousaali_vaatleja`; if those roles did not exist before the test run, the
  runner attempts to drop them during cleanup.

## Run

From the repository root:

```bash
.venv/bin/python tests/database/run_database_validation.py
```

If your local admin database is not reachable through the default
`dbname=postgres` connection string:

```bash
DB_VALIDATION_ADMIN_DSN="dbname=postgres host=localhost user=<user>" \
  .venv/bin/python tests/database/run_database_validation.py
```

To inspect the generated databases after a run:

```bash
.venv/bin/python tests/database/run_database_validation.py --keep-db
```

## Coverage

The suite verifies:

- fresh schema creation from `jousaali_skript.sql`
- generated SQL consistency between `jousaali_skript.sql` and
  `tools/sql_ddl.py`
- submission SQL synchronization between `jousaali_skript.sql` and
  `submission_files/skript.sql`
- static generated-SQL scans for unresolved placeholders, local-only paths,
  inline password assignments, destructive DDL/DML, and disabled triggers
- deterministic schema creation across two fresh databases
- table, view, function, trigger, sequence, domain, and index existence
- catalog health checks for disabled triggers, invalid indexes, unlogged tables,
  unexpected schemas, duplicate names, identifier truncation risk, status-code
  constraint coverage, sequence ownership, and sequence alignment after seed data
- expected table column names, order, key types, domains, and nullability
- primary keys, foreign keys, orphan scans, and FK delete/update behavior
- unique constraints, partial unique indexes, NOT NULL, CHECK constraints, and domains
- defaults, sequence behavior, timestamp defaults, and valid string handling
- trigger metadata, trigger behavior, and PostgreSQL function workflows for
  planning, opening, registration, waitlist promotion, cancellation, and attendance
- view structure, view row-count equivalence, and seeded demo data correctness
- seed idempotency for `rakendus/test_data.sql`, including rerun counts for demo
  people, sessions, registrations, and attendance
- disposable existing-data integrity scans
- query-plan smoke checks for critical application lookup patterns
- transaction commit, rollback, savepoint recovery, and function side-effect rollback
- prototype role permissions, application-role workflow execution, `PUBLIC`
  function grants, observer write/execute blocking, broad public grants, and
  RLS/multi-tenancy applicability
- Flask SQL integration checks for referenced relations/functions and suspicious
  f-string SQL around database calls
- advanced-feature detection for RLS, tenancy keys, JSON/JSONB, materialized
  views, generated columns, partitioning, exclusion/deferrable constraints,
  partial/expression indexes, domains, PostGIS, and full-text-style GIN indexes
- compatibility lints such as reserved keyword names and pgTAP availability
