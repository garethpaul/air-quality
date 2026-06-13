# Air Quality Cache Transport Errors

Status: Completed

## Context

Both the AQI and geocoding paths call Redis before and after upstream work.
Corrupt cache payloads are already ignored safely, but Redis command failures
currently escape as dependency-specific exceptions. Those exceptions bypass
the routes' established `RuntimeError` handling and can produce an unstable
500 response instead of the generic JSON 503 service boundary.

## Requirements

- **R1:** Convert cache read failures in both `AirQuality` and `GeoCode` into a
  stable local `RuntimeError` without chained Redis details.
- **R2:** Convert AQI `setex` and geocode `set` failures into the same stable
  local error after successful upstream parsing.
- **R3:** Preserve corrupt-cache refresh behavior, valid-cache reuse, cache key
  formats, AQI TTL, upstream request behavior, and returned payloads.
- **R4:** Keep `/` and `/s` on the existing generic JSON 503 contract without
  exposing Redis URLs, exception text, or dependency types.
- **R5:** Add no-network regression coverage and fail-closed portable contracts
  for every cache read and write boundary.
- **R6:** Record completed focused, full, external-directory, mutation, and
  hosted verification evidence before marking this plan complete.

## Implementation Units

### U1: Normalize Cache Commands

**Files:** `air.py`, `geocode.py`

Wrap cache reads and writes at the service boundary. Raise one generic,
unchained `RuntimeError` for command failures while leaving payload validation
and cache construction behavior unchanged.

### U2: Exercise Read And Write Failures

**Files:** `air_tests.py`, `geocode_tests.py`, `app_tests.py`

Use dependency-free failing cache clients to prove AQI and geocode read/write
failures are normalized, upstream work is not started after read failure, and
provider-controlled details are absent. Preserve route-level generic 503
coverage for both entry points.

### U3: Preserve The Durable Contract

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `CHANGES.md`,
`docs/plans/2026-06-13-air-quality-cache-transport-errors.md`

Require the cache command boundary, regression test names, completed plan, and
operational guidance. Record actual verification after execution.

## Test Scenarios

- AQI and geocode cache read failures become generic unchained
  `RuntimeError`s and do not start upstream work.
- AQI and geocode cache write failures become the same generic error after
  otherwise valid upstream processing.
- Dependency exception messages containing Redis URLs or secret-like values do
  not appear in normalized errors or route JSON.
- Existing valid-cache, corrupt-cache, upstream, AQI, geocoder, and route tests
  remain green.
- Hostile mutations removing any read/write boundary, restoring chaining, or
  removing regression/documentation/plan contracts fail verification.

## Scope Boundaries

- Do not retry Redis commands or bypass a failed cache to call upstream
  providers.
- Do not change cache keys, TTLs, serialization, provider requests, or public
  response schemas.
- Do not add logging of Redis URLs, exception text, cached values, or provider
  payloads.
- Do not claim live Redis, Mapbox, or sensor-provider validation without
  deployment credentials.

## Verification

- Six focused no-network tests passed for AQI and geocode cache read/write
  failures and missing-cache configuration, including exact generic messages,
  suppressed exception chaining, provider-detail redaction, and upstream
  sequencing.
- The full 42-test suite passed with existing valid-cache, corrupt-cache,
  upstream transport, AQI, geocoder, query, and route behavior unchanged.
- Ruff formatting and linting, Python bytecode compilation, repository-root and
  external-directory baseline checks, `git diff --check`, and nine hostile
  contract mutations passed.
- Live Redis, Mapbox, and sensor-provider validation was not run because this
  change has no deployment credentials and the regression suite uses injected
  no-network dependencies.
