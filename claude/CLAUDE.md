# Global Claude Rules

## Language

- **Conversational replies to the user: Korean.** All written artifacts (code, comments, docs, commit messages, PR descriptions, file content): English.
- Write English in plain, clear language that is easy to understand for non-native speakers. Prefer short sentences, common words, and direct phrasing over complex or idiomatic expressions.

## Documentation

Three CLAUDE.md scopes exist. Keep each up to date whenever a relevant convention or decision changes:

- **Universal** (`~/.claude/CLAUDE.md`) — rules that apply regardless of employer or domain. Pure SE principles, language preferences, communication style. Includes **stack-conditional** rules ("when using protobuf...", "when writing shell...", "when using Istio...") as long as the rule itself doesn't change between workspaces.
- **Workspace** (`<workspace-root>/CLAUDE.md`, e.g. `~/Dev/<org>/CLAUDE.md`) — rules shared by multiple repos under one umbrella (typically one employer / one product family). Shared service names, internal tools, cross-repo conventions, stack choices specific to that workspace.
- **Project** (`<repo>/CLAUDE.md` or its `memory/` directory) — rules tied to one repo's specific stack, business logic, file layout, or runtime quirks.

When a stack/language guide grows beyond a few lines, split it into `~/.claude/lang/<language>.md` or `~/.claude/stack/<tool>.md` and leave a 1–3 line pointer (with the most critical inline rules) in the main file.

**When the user gives feedback, corrects a mistake, or expresses a new preference, decide proactively (without waiting to be asked):**

1. Classify the lesson into one of the three scopes above.
2. Update the matching CLAUDE.md (or memory directory for project-scope ephemerals).
3. **Strip identifying details before writing.** A rule going to a broader scope must not carry narrower-scope specifics — no repo names, env var names, service names, business terms, or file paths from the originating context. Restate the rule in scope-neutral language with abstract examples (categories of resource, generic placeholders like `<DATASET>_<BACKEND>_URL`, or "the Redis db / DynamoDB table holding X"). If you cannot abstract it cleanly, the rule belongs in a narrower scope.
4. Mention the update briefly in the response so the user can confirm placement.

This applies to both **negative feedback** (corrections, "don't do X") and **positive validation** ("yes, that approach is right — keep doing it"). Both reshape future behavior and should be captured.

Classification hints:
- Mentions a specific repo / file / business concept → **project**.
- Names a stack choice ("we use X for Y") that holds across multiple repos in a workspace but not the wider world → **workspace**.
- Could equally apply at any company in any stack → **universal**.

When unsure between two scopes, prefer the narrower one — easier to promote later than to retract from a too-broad scope.

## Security — Credentials

- Prefer **workload identity** over static API keys or long-lived credentials.
  - AWS: IAM Roles for Service Accounts (OIDC), EC2 instance profiles
  - GCP: Workload Identity Federation
  - CI/CD: OIDC-based federated credentials (e.g. GitHub Actions → AWS/GCP)
- Before implementing any credential-based integration, first evaluate whether workload identity is available for the target platform.
- Only use static API keys when workload identity is genuinely not supported; document the reason when doing so.

## Kubernetes & Istio

- Use Istio TLS origination for external HTTPS APIs — sidecar handles TLS and preserves egress observability.
- In repos with kustomize overlays, always `apply -k overlay/`, never `apply -f` a single base file.
- Full guide: `~/.claude/stack/k8s.md`.

## Model Selection

- Use the **most capable available model** for planning, architecture design, and complex decision-making tasks.
- Use the **default model** for all other work — implementation, code edits, debugging, etc.

## Service-to-service comms — prefer REST

- For service-to-service request/response, **default to REST (JSON over HTTP)**. For streaming back to a caller, prefer WebSocket.
- **Do not recommend gRPC, Thrift, or other IDL-based RPC** in plans/specs/designs. Reason: IDL-based RPC requires coordinated caller/callee deployments to keep schemas in sync, which is hard in real collaboration. REST tolerates schema drift more gracefully (additive fields, optional values).
- If the user explicitly chooses an IDL-based RPC, follow their choice — but do not propose it as an option yourself.
- When fire-and-forget is enough, use a message queue, not RPC. Do not propose reply-to/streaming patterns built on top of message queues — if request/response is needed, use REST.

## Binary Serialization IDL (protobuf, Thrift, etc.)

- **Never fabricate or guess** IDL files (`.proto`, `.thrift`, etc.).
- Binary formats serialize by **field number**, not field name. A wrong number silently corrupts data at the wire level with no compile-time or runtime error.
- When adding a cross-repo RPC integration, **ask the user** where the canonical IDL lives and how they want to consume it (direct copy, git submodule, published package, etc.). Do not assume an approach.

## Python

- When typing a Pydantic field, prefer the matching native type (`HttpUrl`, `EmailStr`, etc.) over generic `str` / `int`. Validation, intent, and OpenAPI schemas come free.
- Alembic migrations must not import application code. A migration is a historical record and has to keep producing the same DDL after the app moves on.
- Full guide: `~/.claude/lang/python.md`.

## MySQL

- Use `DATETIME(6)`, pick one clock source (`NOW(6)` or `UTC_TIMESTAMP(6)`) consistently, and handle naive↔aware conversion in a SQLAlchemy TypeDecorator.
- Full guide: `~/.claude/stack/mysql.md`.

## Redis

- Prefer Lua scripts (`register_script`) over distributed locks for atomic read-then-write. Lua CAS replaces locks with no stuck-lock failure mode.
- Core flows must work without Redis — use it for best-effort operations (rate limiting, replay detection, caching) and fall through on failure.
- Full guide: `~/.claude/stack/redis.md`.

## Shell Script Compatibility

- Write shell snippets compatible with both **macOS (BSD)** and **Linux (GNU)**.
- Avoid GNU-only flags (e.g. `xargs -r`, `sed -i ''` vs `sed -i`, `date -d`); use portable alternatives.

## Decision Making

- When information is insufficient or multiple valid approaches exist, **do not guess or assume**. Present concrete options with pros/cons and let the user choose before proceeding.

## Code Style Preferences

- Prefer **minimal diffs** — change only what is necessary.
- Prefer **good defaults** over excessive parameterization. Do not expose configuration for things that have an obvious right answer.

## Design — Explicit over Implicit

When presenting or choosing between design options, lead with the explicit, well-bounded option even when it costs a bit more infra or runtime. Offer pragmatic shortcuts only as lower-tier fallbacks.

- **Avoid stringly-typed / name-convention contracts.** If a downstream component needs to dispatch or filter, use native declarative metadata (resource tags, dedicated fields, typed attributes) rather than parsing names or other fields by regex.
- **Respect a field's semantic purpose.** Don't overload human-facing fields (e.g. `AlarmDescription`, commit messages, log messages) to carry machine-readable metadata.
- **Clean module boundaries beat accumulated branches.** A generic module acquiring specialized branches (e.g. a notifier Lambda gaining k8s-specific enrichment) is worse than splitting into two well-scoped modules, even at the cost of extra infra. If the generic module must host a specialized branch, make the contract explicit (e.g. typed tags) and name the dispatch registry so future additions are obvious.
- **Small network or infra cost is acceptable** to preserve explicitness. An extra API call (e.g. `ListTagsForResource`) or a second Lambda is cheaper than ambiguous contracts that future readers have to reverse-engineer.

## Branching

- Git-flow variant: `main` ← `develop` ← `feature/*`, with `develop` optional for smaller repos. `deploy/YYMM` branches for staged rollouts.
- Full guide: `~/.claude/stack/git.md`.

## Commits

### Authorization

Local commits do not need explicit confirmation — go ahead and commit when you have logically complete changes. Only **push** and **PR creation/update** (anything that affects shared remote state) require explicit user approval. Other shared-state actions (force-push, branch deletion on remote, merging PRs, etc.) still require approval as well.

### Splitting

Split commits by logical concern. When a single file spans multiple concerns, divide its hunks across the matching commits — use `git add -p`, or stage one version of the file, commit, then re-edit and commit again when `-p` granularity isn't enough.

Plan the commit boundaries first (what are the distinct concerns?), then figure out which hunk of each file belongs to which commit. Don't let file boundaries dictate commit boundaries.

### Messages

Commit messages carry only forward-facing context that future maintainers cannot reconstruct from code or tools. Draft each sentence as if answering "does a maintainer six months from now need this, and can they get it elsewhere?"

**Drop**:
- Mechanics the code already shows (what function/pattern was used, behavior of a specific call).
- Self-defense rationale ("X rather than Y keeps it explicit/extensible"). The decision is visible in the diff; the justification is not load-bearing.
- Before/after numbers or diff recaps derivable from `git diff`, `git blame`, `kubectl top`, `terraform plan`, etc.
- Process narrative that doesn't match the actual diff. The commit message describes the transition from the previous commit to this one — not the working-session steps that led here. If a file was never committed before, it is an addition, not a rename/split/migration.

**Keep**:
- Forward-facing capacity envelopes, thresholds, or limits relevant to future changes.
- Safety nets or dependencies this change relies on (so a reader knows what must not be removed).
- Extension / dispatch points (so a reader knows where to plug in new behavior).

Prefer terse. Every sentence should carry a decision-relevant fact. Body should fit within ~12 lines — if a change cannot be summarized that tight after stripping, the commit is doing too many things; split it instead of padding the message.

## Working Style

- **Verify code before answering** — Do not speculate or assume based on general patterns. When asked "how does X work?" or "should we do X?", read the relevant code first. If unsure, check — don't guess.
- **Search for best practices before designing general, non-business-specific implementations.** If the task is something commonly solved (e.g. "EKS pod restart alarm", "Postgres connection pooling", "S3 lifecycle rule for logs"), do a quick web search or check official docs for the established pattern *before* designing from scratch. Ground the design in what the community / vendor already converged on, then adapt. Only skip this step when the problem is genuinely project-specific (custom business logic, internal APIs, unique constraints). Over-engineering from first principles when a standard pattern exists wastes time and tends to hit rediscovered limitations (API constraints, known edge cases) the standard pattern already avoids.
- **Minimize diff by reusing existing code** — When refactoring, modify components/types/helpers in-place rather than deleting and rewriting. Before deleting code, ask: "can I reuse this by changing only the input?"
- **Derive deployment order from actual changes** — Don't default to generic rules like "backend first." Trace the actual dependency: which side is the caller? Which change is additive vs destructive? A side that stops calling an endpoint can deploy before the endpoint is removed.
- **Distinguish discussion from instruction.** When the user asks "어떻게 생각해?" / "what do you think?" / presents options, they want a reasoned opinion and collaborative decision — not immediate implementation. Give your preference with reasoning and wait for their decision. Treat instructions ("do X") and discussions ("should we do X?") differently.
- **Proactive production-readiness in infrastructure code.** When building infra/framework-level code, think through lifecycle (graceful shutdown, startup ordering), concurrency (in-flight tracking, fire-and-forget safety), and error recovery upfront rather than leaving them for later passes. The user values these being considered without being asked.
- **User-facing copy requires explicit review.** Any string an end user will see (push notification titles/bodies, UI text, email content, error messages shown to users, etc.) must be reviewed and approved before implementation. When a plan includes user-facing copy, mark it as draft/placeholder and get explicit approval before committing.
- **Stay in the repo matching the task context.** If the conversation is framed around repo A, make changes in repo A. If the fix genuinely lives in a different repo (sibling, submodule, or monorepo package), surface that explicitly and confirm before switching context. Don't silently start editing another repo.
- **Do not broaden search scope beyond what the user points to.** When the user gives specific paths or reference files, confine Glob/Grep/Read to those. Do not launch broad exploratory searches across sibling repos or parent directories — the user knows what's relevant and points to it on purpose.
- **Separate env vars per logical dataset, even when pointing to the same backing store.** Each distinct dataset (different lifecycle, access pattern, or owning subsystem) should get its own connection-string env var, even if all of them currently resolve to the same instance / db / bucket. Forward optionality is the reason: when scaling later requires splitting one dataset onto its own instance (different host, different db, sharded cluster, separate bucket, etc.), the change is a single URL value swap with zero code or client-wiring changes. Sharing one env var across datasets locks in a future migration that touches code, deployment, and possibly data copying. Cost of upfront separation is one extra env var; benefit is a clean scale-out path. Applies to Redis, S3, Postgres, Kafka, and any other shared-infra backing store.
- **Verify original semantics before reusing existing config/env vars.** When an existing env var, config key, or constant looks like it fits a new use case, check what it was originally designed for (read callers, docs, default values, naming context). If the semantic differs — even if the type matches — introduce a new config rather than silently repurposing. Repurposing a value with different intended semantics (e.g. a token TTL reused as a connection record TTL) causes subtle bugs when the default or override value is wrong for the new context. When in doubt, ask the user.
- **Confirm before sharing storage namespaces.** Reusing an existing storage namespace (Redis db index, DynamoDB table, S3 bucket prefix, Postgres schema, Kafka topic, etc.) for a new logical dataset is a non-trivial operational decision — debug isolation (`MONITOR`/`FLUSHDB` scope), eviction/retention policy coupling, future capacity reservations. Even when key prefixes don't collide, present it as an explicit choice (reuse vs new namespace) and wait for user decision. Also, before claiming a "free" slot (e.g. unused Redis db index), ask whether any are reserved for upcoming work — don't assume unused means available.
- **Filter tool outputs before they land in main context.** kubectl/AWS CLI/grep/jq results dumped in full consume context disproportionate to their signal. Pipe through `-o jsonpath`, `--query`, `jq`, `grep -A/B`, `head`, or `awk` to extract only the fields you need. For exploratory work where filters aren't obvious up front (reading many files, chasing a code flow, analyzing long logs), delegate to a subagent — its context window is separate and its report lands in main context pre-summarized. Rule of thumb: if you find yourself scanning >1KB of tool output for a single fact, you should have either filtered upstream or delegated.
- **Verify sub-agent claims before acting on them.** Sub-agents can hallucinate (asserting a feature exists in a release when it doesn't, reporting a fix was applied when the commit doesn't show it). Before committing to a sub-agent's conclusion, spot-check its load-bearing claims against authoritative sources — git log, actual code, live system state. This is especially important when the sub-agent's report arrives verbatim into your main context; the confident tone doesn't indicate accuracy.
- **DB migration commands require explicit approval, even in auto mode.** Never run `alembic upgrade/downgrade`, `drizzle-kit migrate`, or any equivalent that mutates a database schema without explicit user permission. Generating migration files (`alembic revision --autogenerate`, `drizzle-kit generate`) is fine; applying them is not. If a workflow step (e.g. autogenerate) fails because the DB is not up to date, report the blocker and let the user decide when to run the migration.
- **Never assume any environment's database is empty.** Dev, staging, and production databases all may contain data. When a migration changes column types, encryption schemes, or serialization formats, always include data conversion logic — don't skip it based on assumptions about the environment. If unsure whether data exists, ask.
- **Cluster-modifying commands require explicit approval, even in auto mode.** Editing a K8s manifest (or any infra-as-code file) does NOT imply permission to apply it. Pause and confirm before `kubectl apply/delete/edit/patch/rollout restart`, `terraform apply`, `helm install/upgrade`, or any command that mutates a shared cluster/environment. Auto mode does not lift this bar — shared infra outranks autonomy.
- **Evaluate automated LLM code review comments critically, not reflexively.** LLM reviewer bots have structural biases: they are prompted to find improvements (quota bias), they are stateless across rounds (may contradict earlier accepted decisions), and they are non-deterministic (same code, different runs, different nits). Each round, easy wins get consumed and the bot digs into increasingly marginal suggestions. For every suggestion, ask: (1) does this address a real problem or a hypothetical one, (2) does the value outweigh the cost of another review round and merge delay, (3) does it contradict an earlier accepted decision (cardinality / scope / design choice), (4) is this the round where we should stop iterating. Default to pushing back on marginal suggestions and recommending merge when remaining comments are nits; do not treat "sounds plausible" as "should apply".

## Documentation & Reporting

- **Separate observations from inferences.** In reports and technical documentation, clearly label what was directly observed (metrics, logs, test results) vs what is inferred or hypothesized. Never write an inference as if it were a confirmed fact.
- **Use precise technical terms.** In multi-component systems, don't attribute a property of one component/path to another just because they're adjacent. When unsure of the exact term, describe the mechanism rather than reaching for a close-but-wrong label.
- **Commit to a recommendation.** After presenting a recommendation with reasoning, don't reverse it just because the user pushes back. Re-examine the reasoning — if it still holds, defend it. Only change when new information genuinely shifts the analysis, and state what changed.
- **Plan/design documents: requirements over implementation.** Focus on context (why), requirements (what), references (where to look), and open questions. Do not fill plans with implementation details (specific resource blocks, full manifests, code snippets, step-by-step procedures) — those belong in the code.
