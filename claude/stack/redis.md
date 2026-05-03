# Redis

## Lua Scripts — Prefer `register_script` over raw `EVAL`

- `register_script` returns a callable that transparently caches the script SHA and falls back to `EVAL` on `NOSCRIPT`. One SHA lookup per call instead of shipping the full Lua source every time.
- Lua scripts execute atomically (single-threaded) — they replace distributed locks for read-then-write sequences. Prefer a Lua script over a lock + multi-step pipeline when the operation fits in a single script.

## CAS (Compare-and-Swap)

- `deleteIfEqual(key, expected)` — atomically delete a key only if its current value matches. The standard lock-release primitive: prevents releasing a lock you no longer hold.
- `setIfEqual(key, expected, new, ttl)` — atomically overwrite a key only if its current value matches. Useful for ownership transfer, token rotation, and leader election.
- Both are single-key Lua scripts that work on any Redis topology (cluster-safe).

## Distributed Lock

- Acquire: `SET key owner_id PX timeout NX`. Release: `deleteIfEqual(key, owner_id)`.
- The CAS release prevents a slow holder from deleting a lock that has already been re-acquired by another process after expiry.
- Use only when mutual exclusion is genuinely needed. If the operation can tolerate occasional double-execution, an idempotent design without locks is simpler and more available.

## Buffered Counter (Write Coalescing)

- Problem: many concurrent increments on the same DB row cause row contention.
- Pattern: `HINCRBY hash field delta` accumulates in Redis; a background flush reads `HGETALL`, resets, and writes one `UPDATE ... SET col = col + delta` per field. Collapses N writes into 1 per flush interval.
- Use `ZADD` on a pending set (score = timestamp) to track which hashes need flushing. Workers `ZRANGEBYSCORE` + `ZREM` to claim work.

## Debouncing (Inactivity-Triggered Execution)

- Problem: high-frequency events (typing, read-position updates) should trigger an action only after activity stops for N seconds, not on every event.
- Pattern: sorted set as a delay queue. Each event upserts `ZADD queue score=now+delay uid` + `HSET args uid payload`. Subsequent events overwrite the score (reset the timer) and payload (latest value wins). A poller `ZRANGEBYSCORE` + `ZREM` fires when the delay expires without further upserts.
- Collapses rapid-fire events into one execution. Used for typing-clear broadcasts, read-position flush to DB, push notification batching ("N new messages").

## Write Buffering (Deferred DB Writes)

- Same sorted-set mechanism as debouncing, but the goal is absorbing write bursts rather than waiting for inactivity. Frequent updates (e.g. a read-position cursor) accumulate in Redis and flush to the DB on a delay, collapsing N writes into 1.
- Redis is the buffer, DB is the source of truth. If Redis data is lost, the DB retains a slightly stale value that self-heals on the next event.

## Rate Limiting (Fixed Window)

- Key: `ratelimit:{scope}:{epoch}` where epoch = `floor(now / window_seconds)`.
- `INCR` + `EXPIRE` (set TTL on first increment). Compare result against threshold.
- Simple and sufficient for per-user API rate limits. For sliding-window precision, use sorted sets (`ZADD` + `ZRANGEBYSCORE` + `ZCARD`), but the fixed-window approach is cheaper and adequate for most use cases.

## Key Design

- Prefix all keys with the service name (e.g. `myapp:`) to avoid collisions when sharing a Redis instance. Prefixing alone is not enough — also separate logical datasets onto different db indices (e.g. db 1 for app cache, db 2 for task queue) so `FLUSHDB`, `MONITOR`, and eviction policies apply per-dataset without cross-contamination.
- Group key formatting helpers in a dedicated module, organized by domain (auth, chat, etc.).

## Resilience

- Core application flows should work without Redis. Use Redis for best-effort operations (rate limiting, replay detection, caching) and fall through gracefully when Redis is unreachable.
- Avoid making Redis a hard dependency via distributed locks in critical paths. If a Lua CAS can replace a lock, prefer it — the script either runs or throws, with no stuck-lock failure mode.
