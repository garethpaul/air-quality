# Canonicalize Valid Cached Geocoder Coordinates

Status: Completed

## Problem

`GeoCode.cached_data` accepts finite in-range numeric strings and returns them
as floats, but it leaves the original string-valued payload in Redis. Fresh
Mapbox results and signed-zero repairs already serialize canonical JSON numbers,
so valid cache hits can retain two storage schemas indefinitely and require
repeated coercion on every request.

## Priorities

1. P0: Rewrite valid cached numeric strings as canonical JSON numbers before
   returning them.
2. P1: Preserve signed-zero repair, corrupt-cache refresh, and cache failure
   normalization.
3. P1: Avoid writes for payloads that already use canonical numeric values.
4. P1: Add mutation-sensitive portable contracts and maintained guidance.

## Requirements

1. Valid cached latitude or longitude represented by a numeric string must be
   returned as a float and rewritten as the canonical normalized mapping.
2. Negative zero must continue to normalize to positive `0.0` in the same
   repair write.
3. Already-canonical integer or floating-point JSON numbers must not cause a
   redundant cache write.
4. Boolean, missing, nonnumeric, non-finite, overflowing, and out-of-range
   cached values must remain invalid and refresh through Mapbox as today.
5. A canonical repair write failure must remain the stable redacted
   `cache request failed` runtime error without a provider request.
6. Tests, maintained guidance, baseline contracts, and this plan must retain
   completed verification evidence.

## Implementation Units

### U1: Detect Cache Schema Drift

**File:** `geocode.py`

After existing validation and normalization, compare the accepted source value
types and normalized values with the canonical mapping. Rewrite only when the
stored payload is not already canonical.

### U2: Add Focused Regressions

**File:** `geocode_tests.py`

Cover one-coordinate and two-coordinate numeric strings, mixed signed zero,
canonical numeric cache hits without writes, repair failure normalization, and
the existing invalid-cache refresh boundary.

### U3: Protect The Contract

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require source integration, runtime tests, cache rewrite assertions, guidance,
completed status, and truthful full-gate evidence.

## Test Scenarios

- Cached `{"lat": "37.794678", "lng": -122.41143}` returns floats and is
  rewritten with numeric JSON values without calling Mapbox.
- Cached string values for both coordinates are rewritten in one operation.
- Cached `"-0.0"` values are rewritten as positive numeric zero.
- Canonical integer and float payloads return without a cache write.
- A failing repair write raises only `cache request failed` and never calls
  Mapbox.
- Existing corrupt cache cases continue to refresh from Mapbox.
- Repository and external-directory `make check` remain green.

## Scope Boundaries

- Do not change cache keys, cache lifetime, Redis configuration, Mapbox dataset
  or request behavior, search-query normalization, AQI cache identity, or
  dependencies.
- Do not change successful route schemas or public error text.
- Do not broaden accepted coordinate types or relax finite/range validation.
- Live Redis, Mapbox credentials, and provider behavior remain outside local
  validation.

## Verification

- Preserve a pre-change reproduction proving valid numeric strings remain in
  the cache after a hit.
- Run focused geocoder regressions, the complete test suite, Ruff, and Python
  compilation.
- Run repository and external-directory `make check` with explicit timeouts.
- Reject isolated mutations that remove schema detection, skip repair, rewrite
  canonical hits, weaken failure normalization or tests, remove guidance, or
  falsify plan status.
- The hostile mutations must be rejected before final review and commit.
- Audit the exact diff, generated artifacts, dependency/workflow drift,
  credential-shaped additions, conflict markers, modes, and whitespace.

## Completed Verification

- The pre-change reproduction returned float coordinates while the valid Redis
  payload remained string-valued, with no Mapbox request.
- Four focused regressions passed for canonical repair, no-write canonical
  hits, repair failure normalization, and corrupt-cache refresh behavior.
- All 21 geocoder tests passed.
- Ruff formatting and lint checks passed, all maintained Python modules
  compiled, and the complete suite passed all 91 tests.
- Repository and external-directory `make check` both passed the complete gate
  for this change, including all 91 tests and the baseline contracts.
- All eight isolated hostile mutations were rejected by focused regressions or
  the baseline checker: removed or inverted string detection, forced canonical
  rewrites, dropped repair writes, removed failure coverage, weakened source
  contracts, removed guidance, and reopened plan status.
- Live Redis, Mapbox credentials, and provider behavior remain outside local
  validation.
