# AQI Half-Up Integer Rounding

status: planned

## Problem

EPA AQI guidance requires the interpolated index to be rounded to the nearest
integer. Python's built-in `round()` uses ties-to-even, so an exact interpolation
of `0.5` currently returns `0` instead of the expected upward integer `1`.
Although the current PM2.5 tenths and breakpoint ratios do not produce an exact
half tie, `Linear` is a public scoring helper and future breakpoint changes must
not silently inherit banker rounding.

Primary references:

- EPA, Technical Assistance Document for Reporting the Daily AQI:
  https://nepis.epa.gov/Exe/ZyPURL.cgi?Dockey=P100W5UG.TXT
- EPA AQS current AQI breakpoints:
  https://aqs.epa.gov/aqsweb/documents/codetables/aqi_breakpoints.html

## Scope

- Round nonnegative interpolated AQI values to the nearest integer with exact
  half ties rounded upward.
- Preserve PM2.5 concentration truncation, current breakpoint lookup, scoring
  input validation, categories, cache versioning, routes, and dependencies.
- Add focused regressions for below-half, exact-half, and above-half values.
- Add mutation-sensitive static coverage for the rounding primitive and
  completed verification evidence.
- Stack the successor pull request on terminal-green PR #43 without merging or
  closing either pull request.

## Implementation Units

### U1: Make AQI tie handling explicit

Replace the implicit ties-to-even call with an explicit nonnegative half-up
integer calculation at the final interpolation boundary. Keep the existing
normalization and range validation unchanged.

Test scenarios:

- `0.49` rounds to `0`.
- `0.5` rounds to `1`.
- `1.5` rounds to `2` instead of Python's ties-to-even result.
- Existing PM2.5 breakpoint and helper tests remain unchanged and green.

### U2: Preserve the scoring contract

Extend `air_tests.py`, `scripts/check-baseline.sh`, and maintained guidance with
the named half-up AQI boundary. The static gate must reject reintroducing
`round(a)`, removing the focused test, removing guidance, or reopening the plan.

## Validation

- Prove the pre-change helper returns the wrong exact-half result.
- Run focused scoring tests, Ruff format/lint, the complete suite, compilation,
  and repository/external-directory `make check` gates with explicit timeouts.
- Run isolated hostile mutations for banker rounding, downward tie handling,
  missing test coverage, missing guidance, and incomplete plan evidence.
- Audit exact paths, generated artifacts, credentials, conflict markers,
  binaries, large files, file modes, dependency/workflow drift, and whitespace.

## Risks

- The current PM2.5 breakpoint table has no exact half-tie at accepted tenths,
  so the immediate route output should remain unchanged.
- The public interpolation helper will intentionally differ at exact half ties.
- No live sensor feed, Redis instance, Mapbox request, reverse proxy, or hosted
  deployment is exercised locally.
