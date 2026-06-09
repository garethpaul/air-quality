# Air Quality Cache Score Validation

## Status: Completed

## Context

Cached air-quality payload validation checked that decoded Redis values were
JSON objects with `category`, `caution`, and `score` keys. It did not validate
field types or score values, so a cache entry with a string, boolean,
non-finite, fractional, or negative score could bypass the upstream validation
path and be returned to API callers.

## Objectives

- Preserve fast cache hits for valid air-quality responses.
- Require cached `category` and `caution` values to be strings.
- Require cached `score` values to be finite non-negative integers.
- Return only the public response fields from cached payloads.
- Refresh malformed cached values from the configured upstream data source.

## Work Completed

- Added field type and finite score validation to `AirQuality.cached_data`.
- Normalized valid cached scores to integers.
- Stripped unexpected cached fields before returning cache hits.
- Expanded cache tests to cover invalid score values and field types.
- Added a cache-hit normalization test that does not require a data source.
- Updated README, VISION, and CHANGES.

## Verification

- `python -m unittest air_tests.AirQualityTest.test_corrupt_cached_data_is_ignored_and_refreshed`
- `python -m unittest air_tests.AirQualityTest.test_valid_cached_data_is_normalized_without_fetching`
- `make check`
- `git diff --check`
