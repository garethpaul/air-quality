# Air Quality Non-Finite Sensor Values

## Status: Completed

## Context

Coordinate route inputs already reject NaN and infinity, but upstream
`AIRQUALITY_DATA` readings could still include non-finite latitude, longitude,
or PM2.5 values. Those values can break distance calculations or poison AQI
conversion.

## Objectives

- Preserve nearest valid PM2.5 sensor selection.
- Ignore malformed and non-finite upstream sensor readings.
- Avoid distance math errors from infinite coordinates.
- Keep route behavior unchanged when a later valid reading is available.

## Work Completed

- Added finite-value checks for parsed PM2.5, latitude, and longitude readings.
- Added a unit test that verifies non-finite sensor rows are skipped.
- Updated README, VISION, and CHANGES.

## Verification

- `python -m unittest air_tests.AirQualityTest.test_nonfinite_sensor_values_are_ignored`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Record skipped-reading counts for diagnostics without exposing raw upstream
  payloads.
- Add provider schema documentation for expected `AIRQUALITY_DATA` rows.
