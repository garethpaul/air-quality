# Changes

## 2026-06-16

- Accepted signed-zero coordinates normalize to positive zero so equivalent
  requests share one cache key.
- Mapbox and cached geocoder signed-zero coordinates normalize to positive zero
  before use or cache serialization.
- Valid cached geocoder numeric strings are rewritten as canonical JSON numbers
  while canonical numeric cache hits avoid redundant Redis writes.
- Cached Mapbox results use the `mapbox.places-permanent` dataset so Redis
  storage is explicitly requested under the provider's permanent-geocoding
  terms.

## 2026-06-15

- Near-antipodal sensor distances clamp floating-point drift to the haversine
  domain instead of raising a math-domain error.
- Boolean upstream sensor values are ignored before distance and AQI calculations.
- Boolean scoring helper inputs are rejected before numeric conversion.
- Non-finite scoring helper inputs are rejected before interpolation or
  category construction.
- Zero-width AQI interpolation ranges are rejected before division.
- Descending AQI interpolation ranges are rejected before division.
- Negative AQI scores are classified as Out of Range instead of Good.
- Direct AirQuality construction rejects boolean, nonnumeric, non-finite, and out-of-range coordinates.
- Route coordinate validation rejects boolean and overflowing numeric values before AirQuality construction.
- Boolean Mapbox and cached geocoder coordinates are rejected instead of being
  normalized to numeric locations.
- Cached AQI guidance is accepted only when its 0-500 score, category, and
  caution match the canonical response.
- Overflowing cached numeric values are ignored and refreshed for both AQI
  scores and geocoder coordinates.

## 2026-06-14

- Rejected oversized upstream chunks before extending the retained response
  buffer.
- Required supplied upstream `Content-Length` values to use only ASCII decimal
  digits before response streaming.
- Added a provider-neutral small-instance deployment runbook covering required
  configuration, non-root execution, TLS proxying, bounded health probes,
  secret handling, and rollback.
- Overflowing Mapbox center values are rejected before coordinate caching.
- Required final upstream sensor responses to declare `application/json` or a
  valid `application/*+json` media type before body streaming.
- Rejected missing, malformed, comma-joined, and non-JSON media types with a
  stable local error while retaining deterministic response cleanup.
- Ignored overflowing upstream sensor latitude, longitude, and PM2.5 values
  before distance and AQI calculations instead of raising conversion errors.

## 2026-06-13

- Geocoder transport failures during Mapbox dispatch and JSON decoding now use
  a generic unchained service-error boundary while successful malformed
  payloads retain their validation-error contract.
- Rejected private, loopback, link-local, multicast, shared, reserved,
  unresolved, and mixed-address `AIRQUALITY_DATA` targets before initial and
  redirected Requests dispatch, while retaining generic errors and response
  cleanup.
- Enforced an HTTPS-only data source before default sensor requests, before
  following redirects, and on final response URLs, with generic errors and
  deterministic response cleanup.
- Added no-network direct-plaintext and redirect-downgrade regressions plus
  mutation-sensitive portable contracts.
- Cache command failures during AQI and geocode reads or writes now use a
  generic unchained service-error boundary instead of leaking Redis exception
  details through unexpected route failures.
- Added no-network regressions and portable contracts for all four cache
  command boundaries while preserving keys, TTLs, and corrupt-cache refreshes.
- Requests transport failures during connection, HTTP status validation, and
  streamed reads now use the stable service-error boundary while preserving
  exact response cleanup for every created response.
- Added focused no-network regressions and portable contracts for generic,
  unchained upstream request errors.

## 2026-06-12

- Replaced exception-derived route responses with stable public JSON errors and
  added route-level regression coverage for hidden internal details.
- Added immutable-pinned actions and Python CodeQL analysis plus fail-closed
  workflow contracts.
- Closed streamed `AIRQUALITY_DATA` responses after successful reads and every
  status, size, decoding, and JSON-validation failure path.
- Added dependency-free regression coverage for exact response cleanup.

## 2026-06-10

- Updated PM2.5 scoring to the EPA breakpoints effective May 6, 2024, restored
  valid readings below 5 µg/m³, rejected out-of-range sensor coordinates, and
  versioned cache keys so superseded scores are not reused.
- Moved the runtime baseline from Python 3.7 to `.python-version` 3.14 and a
  CircleCI Python 3.12/3.14 matrix.
- Added pinned, read-only GitHub Actions verification on Python 3.12 and 3.14.
- Upgraded Bottle, Requests, Mapbox, Redis, and Ruff to current direct pins.
- Removed redundant direct AWS SDK pins that Mapbox resolves transitively.
- Added a completed runtime modernization plan and baseline contracts for the
  selected runtime and CI matrix.
- Streamed default sensor-data responses with a 1 MiB limit, HTTP status checks,
  and controlled JSON decoding errors.
- Pinned GitHub Actions to Ubuntu 24.04 with superseded-run cancellation and
  made Make verification independent of the caller's working directory.
- Disabled checkout credential persistence and added an external-directory CI
  invocation guarded by an exact action allowlist.

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
