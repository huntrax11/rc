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
