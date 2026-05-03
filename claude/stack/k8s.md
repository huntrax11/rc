# Kubernetes & Istio

## Kustomize Overlays

- Never `kubectl apply -f` a single base file in a repo that uses kustomize overlays. Always `apply -k overlay/` so overlay patches (hostnames, env-specific secrets, etc.) are preserved. Applying a base manifest directly bypasses overlay-specific values and corrupts environment state.

## Istio — External API Access

- When integrating with any external HTTPS API, use **TLS origination** so the sidecar handles TLS instead of the app.
  - App sends plain HTTP → sidecar upgrades to HTTPS toward the external host.
  - This keeps egress traffic visible to Istio (metrics, tracing, access logs). If the app opens TLS directly, the sidecar sees an opaque stream and observability is lost.
  - Requires a `ServiceEntry` (port 80, `HTTP`) + `DestinationRule` (`trafficPolicy.tls.mode: SIMPLE`).
- Refer to the Istio config reference: `https://istio.io/v1.27/docs/reference/config/`
