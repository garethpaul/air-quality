# Air Quality Constructor Coordinate Validation

Status: Planned

## Problem

HTTP and geocoder entry points validate coordinates before constructing
`AirQuality`, but the reusable class itself converts constructor arguments with
`float()` and accepts booleans, non-finite values, and coordinates outside
geographic bounds. Direct callers can therefore create invalid cache keys such
as `a_q_2_nan_0.0` or run nearest-sensor calculations from impossible
locations.

## Priorities

1. P0: Make `AirQuality` enforce finite, bounded, non-boolean coordinates at
   its own public construction boundary.
2. P1: Preserve valid numeric strings and numeric latitude/longitude values so
   existing direct callers remain compatible.
3. P2: Keep route-level validation and stable HTTP error behavior unchanged.

## Requirements

1. Reject boolean latitude and longitude values before numeric conversion.
2. Reject nonnumeric, non-finite, and out-of-range constructor coordinates.
3. Accept boundary coordinates and valid numeric strings after normalization.
4. Raise stable `ValueError` failures before cache access, HTTP access, or
   nearest-reading selection.
5. Add focused tests and mutation-sensitive portable contracts for both
   coordinate axes and every validation class.
6. Synchronize maintained documentation and record truthful completed
   verification without claiming live Redis or provider coverage.

## Implementation Units

### U1: Constructor Invariant

**File:** `air.py`

Add one package-local coordinate normalization helper and use it for both
constructor fields. Keep the accepted latitude range at `-90..90` and
longitude range at `-180..180`, matching the route and geocoder boundaries.

### U2: Regression Coverage

**File:** `air_tests.py`

Cover boolean, nonnumeric, NaN, infinity, and out-of-range values for both
axes. Include boundary and numeric-string positive controls and prove invalid
construction performs no collaborator work.

### U3: Contracts And Guidance

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require the constructor helper, integration, focused cases, maintained
guidance, completed status, and verification evidence.

## Test Scenarios

- `True` and `False` are rejected for either coordinate.
- Nonnumeric strings are rejected for either coordinate.
- Positive or negative infinity and NaN are rejected for either coordinate.
- Latitude outside `-90..90` and longitude outside `-180..180` are rejected.
- Exact geographic boundaries and valid numeric strings normalize to floats.
- Existing route, search, cache, upstream-response, and AQI tests remain green.

## Scope Boundaries

- Do not change route error payloads or HTTP status codes.
- Do not change cache key format for valid coordinates.
- Do not change sensor selection, AQI calculation, cache lifetime, transport,
  dependency, workflow, or deployment behavior.
- Live Redis and provider integration remain outside local validation.

## Verification

- Focused constructor tests for all negative and positive controls.
- Full `make check` from the repository and an external working directory.
- Isolated hostile mutations for boolean, finite, range, axis, test,
  documentation, and plan-completion contracts.
- Exact diff, whitespace, generated-artifact, conflict-marker, dependency and
  workflow drift, and credential-shaped addition audits.
