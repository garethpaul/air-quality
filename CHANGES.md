# Changes

## 2026-06-10

- Moved the runtime baseline from Python 3.7 to `.python-version` 3.14 and a
  CircleCI Python 3.12/3.14 matrix.
- Upgraded Bottle, Requests, Mapbox, Redis, and Ruff to current direct pins.
- Removed redundant direct AWS SDK pins that Mapbox resolves transitively.
- Added a completed runtime modernization plan and baseline contracts for the
  selected runtime and CI matrix.

## 2026-06-09

- Validated cached air-quality response field types and finite non-negative
  integer scores before returning cache hits.
- Normalized cached air-quality hits to the public response fields.
- Added unit coverage for cached score validation and field stripping.
- Added `scripts/check-baseline.sh` and wired it into `make check` so required
  files, Make targets, completed plans, README notes, and local metadata
  hygiene are checked before pushing.
- Ignored corrupt or malformed cached geocode payloads and refreshed them from
  validated Mapbox responses.
- Added unit coverage for corrupt geocode cache refresh behavior.
- Ignored corrupt or malformed cached air-quality payloads and refreshed them
  from validated upstream readings.
- Added unit coverage for corrupt cache refresh behavior.
- Rejected non-finite and out-of-range geocoder center coordinates before
  caching search results.
- Added unit coverage for malformed geocoder coordinate values.
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
