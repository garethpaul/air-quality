# Air Quality Cache Payload Validation

## Status: Completed

## Context

`AirQuality.getData()` trusted cached Redis values to be valid JSON API
payloads. A corrupt cache entry or a wrong-shaped JSON value could raise a raw
decode error or return a non-response payload instead of refreshing from the
validated upstream data source.

## Objectives

- Preserve fast returns for valid cached air-quality payloads.
- Ignore corrupt cached JSON values.
- Ignore decoded cache values that are not the expected response shape.
- Refresh and replace invalid cache entries through the existing validated
  upstream sensor path.
- Keep the dependency-free test gate covering the behavior.

## Work Completed

- Added `AirQuality.cached_data()` to decode and validate cached payloads.
- Required cached payloads to include `category`, `caution`, and `score`.
- Refreshed malformed cached entries from the configured upstream data source.
- Added unit coverage for corrupt JSON, wrong-shaped JSON, and partial payloads.
- Updated README, VISION, and CHANGES.

## Verification

- `python -m unittest air_tests.AirQualityTest.test_corrupt_cached_data_is_ignored_and_refreshed`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Apply similar corrupt-cache refresh behavior to geocoder cache entries.
- Add structured cache-repair metrics without logging raw upstream payloads.
