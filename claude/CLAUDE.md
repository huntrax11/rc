# Global Claude Rules

## Language

- All output must be in **English** — documentation, comments, commit messages, and file content.
- Write in plain, clear English that is easy to understand for non-native speakers. Prefer short sentences, common words, and direct phrasing over complex or idiomatic expressions.

## Documentation

- Keep `CLAUDE.md` in each project up to date whenever a convention or architecture decision changes.
- Keep this file (`~/.claude/CLAUDE.md`) up to date with rules that apply across all projects.

## Security — Credentials

- Prefer **workload identity** over static API keys or long-lived credentials.
  - AWS: IAM Roles for Service Accounts (OIDC), EC2 instance profiles
  - GCP: Workload Identity Federation
  - CI/CD: OIDC-based federated credentials (e.g. GitHub Actions → AWS/GCP)
- Before implementing any credential-based integration, first evaluate whether workload identity is available for the target platform.
- Only use static API keys when workload identity is genuinely not supported; document the reason when doing so.

## Istio — External API Access

- When integrating with any external HTTPS API, use **TLS origination** so the sidecar handles TLS instead of the app.
  - App sends plain HTTP → sidecar upgrades to HTTPS toward the external host.
  - This keeps egress traffic visible to Istio (metrics, tracing, access logs). If the app opens TLS directly, the sidecar sees an opaque stream and observability is lost.
  - Requires a `ServiceEntry` (port 80, `HTTP`) + `DestinationRule` (`trafficPolicy.tls.mode: SIMPLE`).
- Refer to the Istio config reference: `https://istio.io/v1.27/docs/reference/config/`

## Model Selection

- Use **Opus** (`/model opus`) for planning, architecture design, and complex decision-making tasks.
- Use the **default model** for all other work (implementation, code edits, debugging, etc.).

## Binary Serialization IDL (protobuf, Thrift, etc.)

- **Never fabricate or guess** IDL files (`.proto`, `.thrift`, etc.).
- Binary formats serialize by **field number**, not field name. A wrong number silently corrupts data at the wire level with no compile-time or runtime error.
- When adding a cross-repo RPC integration, **ask the user** where the canonical IDL lives and how they want to consume it (direct copy, git submodule, published package, etc.). Do not assume an approach.

## Shell Script Compatibility

- Write shell snippets compatible with both **macOS (BSD)** and **Linux (GNU)**.
- Avoid GNU-only flags (e.g. `xargs -r`, `sed -i ''` vs `sed -i`, `date -d`); use portable alternatives.

## Decision Making

- When information is insufficient or multiple valid approaches exist, **do not guess or assume**. Present concrete options with pros/cons and let the user choose before proceeding.

## Code Style Preferences

- Prefer **minimal diffs** — change only what is necessary.
- Prefer **good defaults** over excessive parameterization. Do not expose configuration for things that have an obvious right answer.

## Working Style

- **Verify code before answering** — Do not speculate or assume based on general patterns. When asked "how does X work?" or "should we do X?", read the relevant code first. If unsure, check — don't guess.
- **Minimize diff by reusing existing code** — When refactoring, modify components/types/helpers in-place rather than deleting and rewriting. Before deleting code, ask: "can I reuse this by changing only the input?"
- **Derive deployment order from actual changes** — Don't default to generic rules like "backend first." Trace the actual dependency: which side is the caller? Which change is additive vs destructive? A side that stops calling an endpoint can deploy before the endpoint is removed.
