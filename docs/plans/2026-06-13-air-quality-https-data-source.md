# Air Quality HTTPS Data Source

Status: Planned

## Context

The default `AIRQUALITY_DATA` client accepts any Requests-compatible URL and
follows redirects. A plaintext configured URL, or an HTTPS endpoint that
redirects to HTTP, can therefore transport sensor data without TLS.

## Requirements

- Require an absolute HTTPS URL before the default client starts a request.
- Recheck the final response URL after redirects and reject a downgrade to
  plaintext HTTP before status or body processing.
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
URL before `requests.get`, then validate the created response's final URL
before status and body processing. Close a created response through the
existing `finally` path on downgrade rejection.

### U2: Prove The Security Boundary

**Files:** `air_tests.py`

Use Requests fakes to prove plaintext configuration is rejected without a
network call, an HTTPS-to-HTTP redirect is rejected with exact cleanup, and a
final HTTPS URL continues through the existing bounded JSON path.

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

## Verification Plan

- Run focused default-client tests and the complete local `make check` gate.
- Run `make check` from an external working directory.
- Run Ruff, Python compilation, workflow parsing, and `git diff --check`.
- Reject isolated mutations removing or reordering either HTTPS check,
  exposing URL details, omitting response cleanup, removing tests or guidance,
  and leaving stale plan status.
- Inspect the exact delta for generated artifacts and credential-like content.
