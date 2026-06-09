# Air Quality Search Query Validation

## Status: Completed

## Context

The `/s` route trimmed search text before calling Mapbox, but
`search_payload()` also accepted arbitrary non-string values by coercing them
with `str()`. That made the helper more permissive than the route contract and
left very large query strings free to flow into cache keys and upstream
geocoding requests.

## Objectives

- Preserve the existing trimmed text behavior for normal search requests.
- Reject missing, blank, non-string, and oversized query values before Mapbox
  is called.
- Keep the validation covered by dependency-free unit tests.
- Document the query length contract alongside the existing route guarantees.

## Work Completed

- Added `SEARCH_QUERY_MAX_LENGTH` and `parse_search_query()` in `app.py`.
- Updated `/s` payload handling to validate the query before geocoding.
- Replaced the old non-string coercion test with rejection coverage for
  missing, blank, non-string, and too-long values.
- Added documentation notes in `README.md`, `VISION.md`, and `CHANGES.md`.

## Verification

- `python run_tests.py`
- `make check`
- `git diff --check`
