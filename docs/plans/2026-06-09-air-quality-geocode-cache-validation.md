# Air Quality Geocode Cache Validation

## Status: Completed

## Context

Fresh Mapbox geocoder responses were validated before caching, but cached
geocode values were loaded directly. Corrupt JSON, missing coordinate keys,
non-finite values, or out-of-range coordinates could crash search handling or
feed invalid coordinates into the air-quality lookup.

## Objectives

- Preserve cache hits for valid cached geocode coordinates.
- Ignore malformed cached geocode payloads and refresh from Mapbox.
- Validate cached lat/lng values for numeric, finite, and coordinate-bound
  requirements.
- Cover corrupt geocode cache refresh behavior in unit tests.

## Work Completed

- Added `GeoCode.cached_data` to parse and validate cached coordinate payloads.
- Refreshed malformed cached geocode entries from the configured geocoder.
- Added unit coverage for invalid cached JSON, shapes, non-finite values, and
  out-of-range coordinates.
- Updated README, SECURITY, VISION, and CHANGES.

## Verification

- `python geocode_tests.py`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
