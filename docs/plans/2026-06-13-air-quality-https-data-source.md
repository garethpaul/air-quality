# Air Quality HTTPS Data Source

Status: Completed

## Context

The default `AIRQUALITY_DATA` client accepts any Requests-compatible URL and
follows redirects. A plaintext configured URL, or an HTTPS endpoint that
redirects to HTTP, can therefore transport sensor data without TLS.

## Requirements

- Require an absolute HTTPS URL before the default client starts a request.
- Validate every redirect target before Requests follows it, then recheck the
  final response URL before status or body processing.
- Return stable local `RuntimeError` messages without exposing configured or
  redirected URLs.
- Preserve timeout, streaming, response-size, response-close, JSON, payload,
  cache, AQI, Redis, and Mapbox behavior.
- Keep injected `http_get` clients available for deterministic unit tests.
- Add no-network tests and mutation-sensitive portable contracts for direct
  plaintext rejection, redirect downgrade rejection, ordering, cleanup, and
  completed verification evidence.

## Implementation Units

### U1: Validate Default Transport URLs

**Files:** `air.py`

Add a small URL validator based on the standard library. Validate the supplied
URL before `requests.get`, install a response hook that rejects plaintext
redirect targets before the next request, then validate the final URL before
status and body processing. Close rejected redirect responses and retain the
existing `finally` cleanup for returned responses.

### U2: Prove The Security Boundary

**Files:** `air_tests.py`

Use Requests fakes to prove plaintext configuration is rejected without a
network call, an HTTPS-to-HTTP redirect target is rejected before following
with exact cleanup, a downgraded final URL is rejected defensively, and a final
HTTPS URL continues through the existing bounded JSON path.

### U3: Preserve The Durable Contract

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `CHANGES.md`,
`docs/plans/2026-06-13-air-quality-https-data-source.md`

Require both validation sites, their ordering, generic messages, regression
tests, documentation, and completed verification evidence.

## Scope Boundaries

- Do not change the configured endpoint host, add retries, or alter timeout and
  response-size limits.
- Do not implement a general network allowlist or private-address SSRF policy
  in this unit.
- Do not change Redis, Mapbox, Bottle route, or injected-client behavior.
- Do not claim live provider behavior without deployment credentials.

## Verification Completed

- Focused direct-plaintext, malformed-URL, allowed relative-HTTPS redirect,
  pre-follow redirect-target, and final-URL downgrade tests passed without
  network access.
- Local and external-directory `make check` passed Ruff formatting/lint, all
  unit tests, Python compilation, and the portable baseline checker.
- Twelve isolated hostile mutations were rejected for missing or late pre-request
  validation, missing or late post-redirect validation, URL-detail exposure,
  missing cleanup, missing regression coverage or guidance, and stale plan
  status.
- Workflow YAML parsing, exact-delta artifact and secret-pattern scans, and
  `git diff --check` passed.
- Plan-aware security, correctness, reliability, testing, maintainability, and
  adversarial review reported no remaining actionable findings after adding
  pre-follow redirect enforcement and positive HTTPS redirect coverage.
- Live Redis, Mapbox, and `AIRQUALITY_DATA` integrations were not exercised
  without deployment credentials; all new transport tests are no-network.
