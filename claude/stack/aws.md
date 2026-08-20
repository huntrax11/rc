# AWS — Temporary Credentials (STS)

- **If the effective TTL of a presigned URL differs from request to request**, the
  cause is the credential, not the URL-generating code. A presign expiry is capped
  by the **remaining life of the temporary credential that signed it**, not by the
  SigV4 7-day limit. With default 1h credentials that remaining life oscillates
  between 1h and near-0. The fix is to request a longer `DurationSeconds` (STS
  accepts 900..43200); the role's `MaxSessionDuration` (default 3600) must be at
  least the requested value or STS rejects the call.

- **Credential refresh has two independent windows**: the credentials object's
  advisory window (when it decides a refresh is needed) and the credential
  fetcher's own cache window (when it drops the last STS response and actually
  calls STS again). Both default to 900s in botocore. **Widening only the advisory
  window makes the refresh fire while the fetcher returns its cached response with
  the same expiry, so nothing is re-issued** — if refreshes run but the expiry time
  never advances, this is why. Set both values together and pin the boundary with a
  test. Async clients may not accept the advisory window as a constructor argument,
  so it has to be assigned on a private attribute — which breaks silently on a
  library upgrade.

- **If one request per hour picks up tens of milliseconds of extra latency**, an
  on-demand STS refresh landed on it. Move the refresh off the request path with a
  background loop that touches the credentials on an interval shorter than the
  advisory window — outside the window a touch is one datetime comparison, so
  running it often is cheap. On shutdown, stop that loop before closing the
  clients.

- **This refresh logic must be a no-op when `AWS_WEB_IDENTITY_TOKEN_FILE` /
  `AWS_ROLE_ARN` are absent.** Local development has no long-lived credential to
  keep warm, and touching credentials there walks the provider chain into an IMDS
  timeout on every cycle.

- **Use one session per process**, shared by every service client (S3, DynamoDB,
  SES, OpenSearch Serverless, ...). Credentials are cached and refreshed per
  credential chain, not per service, so separate sessions multiply the same STS
  call by the number of services and let their refresh times drift apart.
