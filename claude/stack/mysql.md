# MySQL

## Timezone

- `NOW()` / `CURRENT_TIMESTAMP` follow the session `time_zone`; `UTC_TIMESTAMP()` is always UTC. Mixing them in the same schema produces silently inconsistent data. Pick one clock source and use it for every timestamp column.
- When storing into `DATETIME(6)`, pass the same fsp to the function: `NOW(6)`, `UTC_TIMESTAMP(6)`. Without it, the function returns whole seconds and the fractional part is stored as `.000000`.
- If `UTC_TIMESTAMP(6)` is the chosen source, setting `time_zone` to `UTC` makes `NOW(6) == UTC_TIMESTAMP(6)` and eliminates accidental misuse. If the service is region-local and local time is preferred, use `NOW(6)` consistently and do not mix in `UTC_TIMESTAMP(6)`.

## DATETIME Precision

- Default to `DATETIME(6)` (microsecond precision). Without explicit `fsp`, MySQL truncates to whole seconds, which hides sub-second ordering and causes ambiguous cutoffs when comparing against application-generated timestamps (e.g. UUIDv7 millisecond fields).

## Timezone Alignment

- Three timezone settings must agree: the DB parameter group `time_zone`, the MySQL session `time_zone`, and the application container `TZ` env var. When they diverge, `NOW()` in SQL, `datetime.now()` in Python, and log timestamps each report different times for the same moment. Set all three to the same value.

## SQLAlchemy — Aware Datetimes Through a TypeDecorator

- MySQL `DATETIME` has no timezone. When SQLAlchemy reads a `DATETIME` column, the result is a naive `datetime`. Use a `TypeDecorator` that attaches the DB timezone on load and converts-then-strips on store, so Python code always works with aware datetimes while MySQL stores naive values.
- This eliminates scattered `.replace(tzinfo=...)` calls and prevents naive-vs-aware comparison bugs.

## SQLAlchemy — ON UPDATE CURRENT_TIMESTAMP

- SQLAlchemy's `Column.server_onupdate` does not emit DDL. To get MySQL's `ON UPDATE CURRENT_TIMESTAMP(6)` in the column definition, embed it in `server_default`: `server_default=text("CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)")`. Add `server_onupdate=FetchedValue()` so the ORM re-fetches the value after update.
- Prefer this DB-level mechanism over SQLAlchemy's `onupdate` parameter, which is an ORM-only hook and does not fire for Core-level queries (`insert().on_duplicate_key_update()`, `update().values()`, raw SQL).
- Ref: https://docs.sqlalchemy.org/en/20/dialects/mysql.html#rendering-on-update-current-timestamp-for-mysql-mariadb-s-explicit-defaults-for-timestamp

## Schema Changes — ALGORITHM and LOCK

- Always specify `ALGORITHM` on `ALTER TABLE`. Without it MySQL picks silently — `INSTANT` where supported, otherwise `INPLACE`, otherwise `COPY` — so an operation you expected to be metadata-only can be a full rebuild, and you find out from how long it runs rather than from an error. With it, an unsupported change fails before it starts. Add `LOCK` only for `INPLACE` and `COPY`; `ALGORITHM=INSTANT` permits only `LOCK=DEFAULT`.
- **Never decide from memory which algorithm a change uses.** The INSTANT / INPLACE / COPY classification moved between 8.0 point releases and differs again in 8.4 and 9.x. Read the Online DDL Operations tables for the exact server version, and confirm any limit or default the same way (row-version cap, statistics sampling, histogram buckets). Ref: https://dev.mysql.com/doc/refman/8.4/en/innodb-online-ddl-operations.html
- `INPLACE` does not mean safe. Adding a `FULLTEXT` or `SPATIAL` index runs in place but blocks concurrent DML, and the first `FULLTEXT` index rebuilds the table when there is no `FTS_DOC_ID` column.
- The `DATETIME(6)` rule above is not free on a table that has already grown: a precision change rebuilds the table with writes blocked. Confirm the algorithm before applying it retroactively, and treat `VARCHAR` length changes the same way — some are metadata-only and some are rebuilds.
- Adding a foreign key is `COPY` while `foreign_key_checks` is enabled, which is the default. Only with it disabled does the operation run `INPLACE`.
- Set a short `lock_wait_timeout` before DDL. Every algorithm, including `INSTANT`, needs a brief exclusive metadata lock at the start and end. If a long-running transaction holds that lock, the DDL waits and later queries against the table queue behind it. Failing fast and retrying beats an unbounded wait.

## Alembic — Expressing ALGORITHM

- Neither Alembic nor the SQLAlchemy MySQL dialect has a parameter for `ALGORITHM` or `LOCK`. Write it as `op.execute(text("ALTER TABLE ... , ALGORITHM=INSTANT"))`. This keeps the DDL inlined in the migration, which the no-application-imports rule already requires.
- `--autogenerate` always emits `op.add_column(...)`, so the clause has to be added by hand. To automate it, rewrite `AddColumnOp` into `ExecuteSQLOp` with `alembic.autogenerate.rewriter.Rewriter` in `env.py`.

## INSTANT DDL Accumulates

- Instant `ADD COLUMN` / `DROP COLUMN` add a row version to the table and there is a hard cap. Past it, instant operations are rejected and only a table rebuild clears them. Check `information_schema.INNODB_TABLES.TOTAL_ROW_VERSIONS` before planning a series of them.
- Space for an instantly dropped column is not reclaimed. The data stays in existing rows until the table is rebuilt, so instant is not free for a table that gets many of them.

## OPTIMIZE TABLE

- For InnoDB this is a full table rebuild, not an in-place tidy-up. Run it for a reason — clearing accumulated instant-DDL row versions, or reclaiming space after a large delete — never as a scheduled sweep over every table.
- InnoDB does not support per-partition optimize. `ALTER TABLE ... OPTIMIZE PARTITION` warns and rebuilds the entire table. To work on one partition use `ALTER TABLE ... REBUILD PARTITION` and `ALTER TABLE ... ANALYZE PARTITION`.

## ANALYZE TABLE

- Automatic statistics recalculation is asynchronous and triggers only after a large fraction of rows change, so it lags. Run `ANALYZE TABLE` explicitly after a bulk load, a backfill, or a large delete — a data migration that rewrites many rows should end with it.
- When cardinality estimates are wrong on a large or skewed table, raise the sampling depth for that table with `STATS_SAMPLE_PAGES` rather than changing the global setting.
- Histograms (`ANALYZE TABLE ... UPDATE HISTOGRAM ON col`) are never updated automatically. They go stale silently as data changes and must be re-run.

## Keyset Pagination on Composite Keys

- For ascending, non-null keys, default to the expanded form `a > x OR (a = x AND b > y)`, not the row constructor `(a, b) > (x, y)`; adjust for DESC or nullable columns. Row-constructor inequalities can prevent range access, causing later pages to rescan earlier rows. Recheck the docs for the version in use: https://dev.mysql.com/doc/refman/8.4/en/row-constructor-optimization.html
- Verify with EXPLAIN on representative data with a cursor well into the table; for large scans or hot paths, keep that EXPLAIN as a plan regression test.

## Production Schema Changes

- Before a schema change against a production table, measure the table first, then decide whether it needs an online schema change tool (pt-online-schema-change, gh-ost, Vitess) rather than a direct `ALTER TABLE`.
