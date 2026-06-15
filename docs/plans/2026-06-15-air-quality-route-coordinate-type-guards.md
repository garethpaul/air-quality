# Air Quality Route Coordinate Type Guards

Status: Planned

## Problem

`app.parse_coordinate` is the reusable validation boundary for route and search
coordinate inputs, but its conversion behavior is weaker than the
`AirQuality` constructor it feeds. Direct boolean inputs are accepted as
`1.0` or `0.0`, and numeric objects beyond the platform float range can raise
`OverflowError` instead of the helper's documented `ValueError`. Direct
callers and tests using the helper can therefore observe inconsistent types or
bypass the intended numeric-input contract.

## Priorities

1. P0: Reject boolean route-helper coordinates before numeric conversion.
2. P0: Normalize overflowing numeric inputs to the same stable `ValueError`
   used for other nonnumeric values.
3. P1: Preserve valid strings, numeric values, geographic boundaries, and
   route-level 400 responses.
4. P1: Add mutation-sensitive tests and portable contracts so both guards
   cannot regress independently.

## Requirements

1. `parse_coordinate` must reject `True` and `False` for either coordinate.
2. Oversized numeric objects that cannot convert to a finite float must raise
   `ValueError`, not leak `OverflowError`.
3. Valid numeric strings and numeric boundary values must continue to
   normalize to floats.
4. Invalid inputs must fail before an `AirQuality` collaborator is created.
5. The HTTP handlers must retain their existing generic `400` response for
   validation failures and must not expose exception details.
6. Tests, documentation, the baseline checker, and this plan must preserve the
   completed behavior and verification evidence.

## Implementation Units

### U1: Harden The Route Helper

**File:** `app.py`

Reject booleans before conversion and include `OverflowError` in the narrow
numeric-conversion failure boundary. Keep all finite and geographic range
checks unchanged.

### U2: Add Focused Regression Coverage

**File:** `app_tests.py`

Cover booleans and oversized integers on both axes, prove stable `ValueError`
messages, and prove invalid values do not construct the injected air-quality
collaborator. Preserve valid boundary and numeric-string controls.

### U3: Preserve Contracts And Guidance

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require the source guards, both focused failure classes, collaborator
non-invocation, maintained guidance, completed plan status, and truthful
verification evidence.

## Test Scenarios

- `True` and `False` fail for latitude and longitude.
- An integer beyond the platform float range fails for latitude and longitude.
- Exact latitude and longitude boundaries still normalize successfully.
- Valid numeric strings still normalize successfully.
- The injected `AirQuality` factory is not called for rejected inputs.
- Route validation errors remain generic JSON `400` responses.
- The complete repository gate remains green from both repository and external
  working directories.

## Scope Boundaries

- Do not change cache keys, geocoder behavior, nearest-reading selection, AQI
  calculation, dependencies, workflows, or deployment behavior.
- Do not broaden exception handling beyond numeric conversion.
- Do not change successful route payloads or public error text.
- Live Redis, upstream data, and provider behavior remain outside local
  validation.

## Verification

- Run focused helper and route tests before the complete suite.
- Run repository and external-directory `make check` using the pinned project
  environment.
- Reject isolated mutations that remove the boolean guard, remove
  `OverflowError` normalization, weaken focused tests, or falsify completion
  evidence.
- Audit the exact diff, generated artifacts, dependency/workflow drift,
  credential-shaped additions, and whitespace before commit.
