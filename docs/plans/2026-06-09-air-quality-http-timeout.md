# Air Quality HTTP Timeout

## Status: Completed

## Context

The default `requests.get` wrapper for `AIRQUALITY_DATA` did not set a timeout.
If the configured upstream endpoint stalled, route handling could block on an
unbounded network call.

## Objectives

- Preserve the injectable `http_get` test seam.
- Add a bounded timeout to the default HTTP fetch path.
- Cover the timeout without requiring live network access.
- Keep `make check` as the verification gate.

## Work Completed

- Added `REQUEST_TIMEOUT_SECONDS = 10`.
- Passed the timeout to default `requests.get` calls.
- Added a unit test that stubs `requests` and verifies the timeout argument.
- Updated README, VISION, and CHANGES.

## Verification

- `python run_tests.py`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Make the timeout configurable through environment with validation.
- Surface upstream timeout errors as a dedicated route error.
