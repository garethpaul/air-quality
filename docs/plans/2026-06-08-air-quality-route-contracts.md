---
title: Air Quality Route Contract Hardening
type: test
status: completed
date: 2026-06-08
---

# Air Quality Route Contract Hardening

## Problem Frame

The first modernization pass made the air-quality and geocoding cores testable,
but intentionally left route-level tests and an app entrypoint refactor out of
scope. The Bottle routes still parse request query values directly and start the
server at import time, which makes route behavior harder to test and turns bad
input into uncaught exceptions.

## Scope Boundaries

- Preserve the public `/` coordinate route and `/s` search route.
- Keep response bodies simple JSON objects.
- Do not replace Bottle or change deployment configuration.
- Do not add live Redis, Mapbox, or data-feed requirements to tests.

## Implementation Units

### U1: Route Helper Tests

Files:

- Add `app_tests.py`
- Update `run_tests.py`

Approach:

- Cover coordinate parsing, empty query handling, search query trimming, and
  injectable air-quality/geocode collaborators. Coordinate parsing should reject
  missing, non-numeric, non-finite, and out-of-range values. Search parsing
  should trim and normalize request values before passing them to geocoding.

### U2: Route Helper Refactor

Files:

- Modify `app.py`

Approach:

- Move coordinate and search payload logic into pure helper functions.
- Convert missing or invalid route input to JSON error responses.
- Put Bottle startup behind `main()` and `if __name__ == "__main__"`.

## Verification

- `make lint`
- `make test`
- `make build`
- `git diff --check`
