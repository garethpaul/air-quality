# Air Quality Geocoder Signed-Zero Normalization

Status: Planned

## Problem

The air-quality constructor and route boundaries canonicalize signed-zero
coordinates, but the geocoder boundary does not. A fresh Mapbox center such as
`[-0.0, -0.0]` and an otherwise valid Redis geocode entry containing `-0.0`
both retain negative sign bits. Equivalent geographic locations can therefore
be serialized differently in the geocode cache even though downstream AQI
cache keys eventually normalize them.

## Priorities

1. P0: Canonicalize accepted zero-valued Mapbox and cached geocoder coordinates
   to positive `0.0`.
2. P1: Preserve all nonzero coordinate values and existing invalid-coordinate
   rejection behavior.
3. P1: Prove fresh and cached geocoder paths return the same canonical payload.
4. P1: Add mutation-sensitive portable contracts and maintained guidance.

## Requirements

1. `GeoCode.parse_first_feature_center` must return positive `0.0` for numeric
   and textual positive or negative zero in either coordinate position.
2. `GeoCode.cached_data` must normalize valid cached signed-zero coordinates to
   positive `0.0` without accepting any currently invalid cache payload.
3. Fresh geocoder results must be serialized to Redis only after
   canonicalization.
4. Nonzero numeric strings, geographic boundaries, transport errors, cache
   failures, and corrupt-cache refresh behavior must remain unchanged.
5. Tests, maintained guidance, the baseline checker, and this plan must retain
   the completed behavior and truthful verification evidence.

## Implementation Units

### U1: Shared Coordinate Canonicalization

**Files:** `geocode.py`, `air.py`

Reuse the existing package-local zero canonicalization helper at both geocoder
normalization boundaries. Keep finite-number and geographic-range validation
ahead of canonicalization so no rejected input becomes valid.

### U2: Fresh And Cached Regression Coverage

**Files:** `geocode_tests.py`

Cover numeric and textual signed zero for fresh Mapbox centers, valid Redis
payloads, positive sign bits, canonical cache serialization, and nonzero and
boundary controls.

### U3: Portable Contracts And Guidance

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require both integrations, focused tests, positive-zero assertions, maintained
guidance, completed status, and verification evidence.

## Test Scenarios

- Fresh centers containing `0.0`, `-0.0`, `"0"`, `"-0"`, `"0.0"`, and
  `"-0.0"` return positive-zero latitude and longitude.
- Valid cached payloads containing positive or negative signed zero return the
  same canonical mapping without a provider request.
- Fresh signed-zero results are cached as positive zero.
- Nonzero numeric strings and exact geographic boundaries retain their values.
- Existing boolean, nonnumeric, non-finite, overflowing, and out-of-range
  values remain rejected or refreshed as currently documented.
- Repository and external-directory `make check` remain green.

## Scope Boundaries

- Do not change geocode cache keys, cache lifetime, Redis configuration, Mapbox
  requests, query parsing, AQI cache identity, or dependencies.
- Do not change successful route schemas or public error text.
- Do not broaden accepted coordinate types or relax finite/range validation.
- Live Redis, Mapbox credentials, and provider behavior remain outside local
  validation.

## Assumptions

- Signed zero has no distinct geographic meaning and should share one
  serialized geocoder identity.
- Reusing the existing helper is preferable to introducing a second numeric
  normalization abstraction.

## Verification

- Preserve the pre-change reproduction showing negative sign bits from fresh
  and cached geocoder inputs.
- Run focused geocoder regressions, then the complete test suite.
- Run repository and external-directory `make check`.
- Reject isolated mutations that remove either integration, weaken sign or
  cache-serialization assertions, remove guidance, or falsify plan status.
- Audit the exact diff, generated artifacts, dependency/workflow drift,
  credential-shaped additions, conflict markers, and whitespace before commit.
