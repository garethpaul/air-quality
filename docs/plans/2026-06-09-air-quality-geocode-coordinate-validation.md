# Air Quality Geocode Coordinate Validation

## Status: Completed

## Context

Geocoder response validation already checked that the first feature had a
two-value numeric `center`, but finite and coordinate-range validation happened
later in route helpers. That left malformed geocoder coordinates able to enter
the geocode cache before the air-quality route rejected them.

## Objectives

- Preserve first-feature Mapbox center parsing.
- Reject non-finite geocoder longitude or latitude values.
- Reject geocoder centers outside valid coordinate bounds.
- Avoid caching invalid coordinates from upstream geocoder responses.

## Work Completed

- Added finite checks for parsed geocoder latitude and longitude values.
- Added latitude and longitude bounds checks in `GeoCode.parse_first_feature_center`.
- Added unit coverage for non-finite and out-of-range geocoder centers.
- Updated README, VISION, and CHANGES.

## Verification

- `python -m unittest geocode_tests.GeoCodeTest.test_center_must_be_finite_and_in_coordinate_bounds`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Add provider schema documentation for expected Mapbox feature fields.
- Consider cache-versioning if future geocoder payload fields are added.
