---
title: Issue 4 HTTP Timeout
type: fix
status: active
date: 2026-06-08
origin: https://github.com/garethpaul/air-quality/issues/4
execution: code
---

# Issue 4 HTTP Timeout

## Summary

Set an explicit timeout on the outbound air-quality data fetch so the app does not wait forever on a stalled upstream HTTP request.

## Problem Frame

Issue #4 was filed from the public repository review because `air.py` calls `requests.get(url)` without a timeout. Requests defaults to no timeout, which can leave a request handler blocked indefinitely if the upstream accepts a connection and stops responding.

## Requirements

- R1. `_default_http_get` must pass a bounded timeout to `requests.get`.
- R2. Request timeout exceptions must surface as a clear runtime error instead of leaking an implementation-specific exception message.
- R3. Injected `http_get` test doubles and the existing cache/data selection behavior must continue to work.
- R4. The PR must reference `https://github.com/garethpaul/air-quality/issues/4`.

## Implementation Unit

### U1. Default Fetch Timeout

- **Goal:** Add a module-level timeout value, pass it to `requests.get`, and wrap `requests.exceptions.Timeout` with a clear application error.
- **Files:** `air.py`, `air_tests.py`
- **Test Scenarios:** Default fetcher passes the timeout argument, request timeouts are wrapped, and the existing air/geocode suite still passes.
- **Verification:** `python3 run_tests.py`, `git diff --check`, and `rg -n "HTTP_TIMEOUT|timeout=HTTP_TIMEOUT|Timed out fetching air quality data" air.py air_tests.py`.

## Risks

- The timeout values are conservative defaults. They can be tuned later if production data fetches need a longer read window.
