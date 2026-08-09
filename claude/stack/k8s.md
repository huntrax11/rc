# Kubernetes & Istio

## Kustomize Overlays

- Never `kubectl apply -f` a single base file in a repo that uses kustomize overlays. Always `apply -k overlay/` so overlay patches (hostnames, env-specific secrets, etc.) are preserved. Applying a base manifest directly bypasses overlay-specific values and corrupts environment state.

## DNS — ndots & Egress Fan-out

- Default `ndots:5` turns every external FQDN lookup into 4 search-suffix NXDOMAINs + 1 real query (~5x amplification). Set `ndots: "2"` in pod `dnsConfig.options`: `svc` / `svc.ns` still search-complete, ≥2-dot FQDNs resolve in one query. Never `ndots:1` — 1-dot names (`svc.ns`) then hit public DNS first, and a namespace colliding with a real TLD (`.dev`, `.app`) lets a registered public domain silently beat the in-cluster service.
- Istio multiplies the waste: Envoy re-resolves every `resolution: DNS` ServiceEntry host from every meshed pod on each record-TTL expiry, independent of app traffic. NXDOMAIN volume/node ≈ #SE hosts × #meshed pods × (1/TTL) × #suffix misses (×2 if A+AAAA) — every factor is a lever: scope ServiceEntries (`exportTo`, `Sidecar`), lower ndots, or `resolution: NONE` per-host (below). Non-fixes: `meshConfig.dnsRefreshRate` (applies only to TTL-less responses) and DNS proxying / `ISTIO_META_DNS_CAPTURE` (capture excludes uid 1337 = Envoy's own lookups — tried, abandoned).
- Mesh-wide ndots rollout: custom injection template + `defaultTemplates: [sidecar, <tmpl>]`. **`defaultTemplates` replaces the implicit `[sidecar]` — dropping `sidecar` strips the proxy from every pod.** Templates only reach injected pods; pin `dnsConfig` directly on gateways, `inject: "false"` pods, and off-mesh addons.
- Cost symptom: on EKS Auto Mode, CoreDNS (AWS-managed, log config untouchable) journals the **NXDOMAIN denials specifically** — the host journal is nearly pure suffix-miss waste, and ndots:2 eliminates (not shrinks) those lines for ≥2-dot hosts. The journal bills twice: log-shipper ingestion cost AND any host agent that (re)reads it. Measured: ~230 journal entries/s/node, tens of GB/quarter ingested, ~27x lower after ndots:2. Unexplained journal or log-cost growth ⇒ suspect DNS amplification.
- Residuals: hosts with fewer dots than ndots (1-dot apexes) still search-expand; for ServiceEntry hosts, `resolution: NONE` removes Envoy's periodic re-resolution (app still resolves; routing unchanged) at the cost of Envoy client-side LB / outlier detection — fine for CDN-fronted APIs. Avoid trailing-dot hosts (`example.com.`): the dot enters the routing match and breaks `:80` TLS-origination host matching (200→301).

## In-cluster Routing

- For calls between services in the same cluster, use in-cluster Service DNS (`svc` / `svc.ns`), not the public ingress URL. The external round trip (hairpin) adds latency, egress dependencies, and edge-auth overhead, and short names still search-complete after lowering ndots.

## Istio — External API Access

- When integrating with any external HTTPS API, use **TLS origination** so the sidecar handles TLS instead of the app.
  - App sends plain HTTP → sidecar upgrades to HTTPS toward the external host.
  - This keeps egress traffic visible to Istio (metrics, tracing, access logs). If the app opens TLS directly, the sidecar sees an opaque stream and observability is lost.
  - Requires a `ServiceEntry` (port 80, `HTTP`) + `DestinationRule` (`trafficPolicy.tls.mode: SIMPLE`).
- Refer to the Istio config reference for the version matching the running mesh, e.g. `https://istio.io/v1.29/docs/reference/config/`.
