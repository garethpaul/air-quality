# Changes

## 2026-06-09

- Ignored non-finite upstream sensor latitude, longitude, and PM2.5 values
  before distance or AQI calculations.
- Added unit coverage for non-finite upstream sensor readings.

## 2026-06-08

1. Made the test harness reliable by having `run_tests.py` return a failing
   process status when any test fails.
2. Reworked air quality tests to run without live Redis or HTTP calls. The new
   tests protect nearest valid PM2.5 sensor selection, cache reuse, out-of-range
   AQI category handling, zero-coordinate sensors, and the no-valid-sensor
   error path.
3. Reworked geocoding tests to run without live Redis or Mapbox calls. The new
   tests protect first-result coordinate parsing, cache reuse, and the
   no-results error path.
4. Lazily initialize Redis, HTTP, and Mapbox dependencies so import-time tests
   are deterministic and missing service configuration fails with clear errors.
5. Added lint, format, test, and build commands plus CircleCI wiring so future
   changes have explicit quality gates.
6. Pinned Mapbox's AWS transitive dependencies to keep dependency installation
   deterministic and avoid long resolver backtracking in CI.
7. Added route helper tests and validation for missing, malformed, non-finite,
   and out-of-range coordinate input, empty search queries, JSON route errors,
   and import-safe Bottle startup.
8. Added `make check` as the standard local gate for lint, tests, and build
   verification.
9. Validated upstream `AIRQUALITY_DATA` payloads before reading sensor results
   so malformed provider responses fail with a controlled service error.
10. Validated Mapbox geocoder feature and center shapes before converting them
    into air-quality coordinates.
11. Added a bounded timeout to the default upstream air-quality HTTP fetch path.
12. Tightened `/s` search-query validation so missing, blank, non-string, and
    oversized values fail before cache-key construction or Mapbox lookup.
