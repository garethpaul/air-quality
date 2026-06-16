# Air Quality Signed-Zero Coordinate Normalization

Status: Planned

## Problem

IEEE-754 signed zero values compare equal and identify the same geographic
coordinate, but their string forms differ. `AirQuality(-0.0, -0.0)` therefore
produces `a_q_2_-0.0_-0.0`, while `AirQuality(0.0, 0.0)` produces
`a_q_2_0.0_0.0`. Equivalent requests can occupy separate cache entries and
return inconsistent cache reuse depending on how callers spell zero.

## Priorities

1. P0: Canonicalize every accepted signed-zero coordinate to positive `0.0`.
2. P1: Preserve validation and exact values for all nonzero coordinates.
3. P1: Prove direct constructors and route helpers share one canonical cache
   identity for zero.
4. P1: Add mutation-sensitive tests and portable contracts for the invariant.

## Requirements

1. `_normalize_coordinate` must return positive `0.0` for numeric and textual
   positive or negative zero.
2. Nonzero numeric strings, numeric values, geographic boundaries, and all
   existing invalid-input failures must remain unchanged.
3. Equivalent positive-zero and negative-zero `AirQuality` instances must
   produce the same cache key.
4. Route-level coordinate parsing must feed canonical zero values into the
   `AirQuality` collaborator.
5. Tests, maintained guidance, the baseline checker, and this plan must
   preserve the completed behavior and verification evidence.

## Implementation Units

### U1: Canonical Coordinate Identity

**Files:** `air.py`, `app.py`

Normalize accepted zero coordinates after finite and range validation. Reuse a
small package-local zero canonicalization helper at the constructor and route
boundaries so both direct and HTTP-mediated callers produce the same values.

### U2: Regression Coverage

**Files:** `air_tests.py`, `app_tests.py`

Cover numeric and textual signed zero on both axes, assert positive-zero sign
bits, prove cache-key equality, and prove route collaborators receive
canonical zero values. Retain nonzero and boundary controls.

### U3: Contracts And Guidance

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require the shared helper, both integrations, focused tests, canonical cache
identity, maintained guidance, completed plan status, and truthful verification
evidence.

## Test Scenarios

- `0.0`, `-0.0`, `"0"`, `"-0"`, `"0.0"`, and `"-0.0"` normalize to
  positive `0.0` for latitude and longitude.
- Positive-zero and negative-zero instances produce identical cache keys.
- Route helpers pass positive zero to the injected `AirQuality` factory.
- Nonzero numeric strings and exact geographic boundaries remain unchanged.
- Existing invalid coordinate, sensor, cache, transport, AQI, and route tests
  remain green.
- Repository and external-directory `make check` remain green.

## Scope Boundaries

- Do not change cache-key versioning or formatting for nonzero coordinates.
- Do not change geocoder payloads, nearest-reading selection, AQI calculation,
  cache lifetime, dependencies, workflows, or deployment behavior.
- Do not change successful route schemas or public error text.
- Live Redis, configured upstream data, and provider behavior remain outside
  local validation.

## Verification

- Reproduce distinct positive-zero and negative-zero cache keys before the
  change.
- Run focused constructor, cache-key, and route-helper regressions.
- Run repository and external-directory `make check`.
- Reject isolated mutations that remove zero canonicalization from either
  boundary, weaken cache-key equality or sign assertions, remove guidance, or
  falsify completion evidence.
- Audit the exact diff, generated artifacts, dependency/workflow drift,
  credential-shaped additions, conflict markers, and whitespace before commit.
