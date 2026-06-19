# Air Quality Boolean Sensor Values

status: completed

## Context

`AirQuality.nearest_reading` converts upstream latitude, longitude, and PM2.5
fields with `float()`. Python therefore accepts JSON booleans as `1.0` and
`0.0`, allowing malformed provider rows to participate in distance and AQI
selection.

## Requirements

- Ignore sensor rows whose `Lat`, `Lon`, or `PM2_5Value` field is boolean.
- Preserve valid numeric and numeric-string readings, including zero values.
- Preserve finite/range checks, nearest-sensor selection, cache behavior, AQI
  scoring, stable route errors, and provider transport boundaries.
- Add direct regressions and mutation-sensitive static contracts for all three
  boolean fields.

## Scope Boundaries

- Do not change geocoder validation, route inputs, cache formats, dependencies,
  provider URLs, HTTP behavior, AQI breakpoints, or deployment configuration.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.
- Continue ignoring malformed sensor rows and selecting the nearest remaining
  valid reading.

## Implementation Units

### U1: Reject boolean sensor fields

**Files:** `air.py`, `air_tests.py`

**Approach:** Add an explicit boolean guard before numeric conversion in
`nearest_reading`. Extend the malformed-reading regression with boolean
latitude, longitude, and PM2.5 rows plus one valid fallback reading.

**Verification:** `test_boolean_sensor_values_are_ignored` proves each malformed
row is ignored and the valid fallback is selected and cached.

### U2: Keep the portable baseline fail closed

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `VISION.md`,
`AGENTS.md`, `CHANGES.md`,
`docs/plans/2026-06-15-air-quality-boolean-sensor-values.md`

**Approach:** Register the runtime guard, all three regression values,
maintained guidance, and completed-plan evidence in the dependency-free
checker.

**Verification:** Isolated mutations that remove the runtime guard, weaken any
field regression, remove guidance, or regress completed-plan evidence fail.

## Verification Plan

- Run the focused boolean-sensor regression and the complete unittest suite.
- Run every standard Make gate from the repository root and through the
  absolute Makefile path from an external directory.
- Run isolated hostile mutations for the guard, all three field cases,
  documentation, and completed-plan evidence.
- Audit the exact intended diff, generated artifacts, suspicious secret
  patterns, file modes, and whitespace before committing.

## Work Completed

- Added a pre-conversion guard that ignores upstream sensor rows containing
  boolean latitude, longitude, or PM2.5 values.
- Added `test_boolean_sensor_values_are_ignored` with three malformed exact-hit
  rows and one valid fallback reading.
- Registered source, test, guidance, and completed-plan contracts in the
  dependency-free baseline checker and maintained repository guidance.

## Verification Completed

- `python run_tests.py` passed all 70 tests.
- Ruff formatting, Ruff lint, and Python compilation passed.
- The focused `test_boolean_sensor_values_are_ignored` regression passed.
- `make check` passed from the repository root and through the absolute
  Makefile path from an external directory.
- Six isolated hostile mutations covering the runtime guard, latitude case,
  longitude case, PM2.5 case, guidance, and plan evidence were rejected.
- No live Redis, Mapbox, or sensor-provider request was made.
- The exact diff, generated-artifact, file-mode, whitespace, and
  suspicious-secret audits are completed before commit.
