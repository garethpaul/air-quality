# Air Quality Descending Linear Range

status: completed

## Problem

`AirQuality.Linear` rejects non-numeric, non-finite, and zero-width
concentration ranges, but still accepts a descending range where `Conchigh` is
less than `Conclow`. That malformed public-helper input produces a plausible
number from an inverted denominator instead of failing with a stable validation
error.

## Requirements

- Reject descending normalized concentration ranges before interpolation.
- Preserve the existing zero-width error, valid ascending interpolation,
  numeric-string support, and production EPA breakpoints.
- Add focused numeric and numeric-string regressions.
- Add mutation-sensitive baseline coverage for the source guard, stable error,
  focused tests, maintained guidance, and completed plan evidence.
- Run repository-root and external-directory `make check` with explicit
  timeouts and audit only intended paths.
- Keep the pull request stacked on the zero-width range fix and do not merge or
  close the stack without explicit authorization.

## Verification

- Reproduce the pre-fix descending-range acceptance with a focused test.
- Run adjacent boolean, non-finite, zero-width, and valid interpolation tests.
- Run the complete canonical gate from repository and external directories.
- Reject isolated hostile mutations for the source guard and evidence.
- Audit generated artifacts, file modes, whitespace, conflict markers, and
  added credential-like values.

## Work Completed

- Added an explicit normalized `Conchigh < Conclow` guard with a stable
  ascending-range validation error.
- Added numeric and numeric-string regressions while retaining the existing
  valid ascending interpolation control.
- Added source, test, documentation, and completed-plan baseline contracts and
  synchronized maintainer guidance.

## Verification Completed

- `test_linear_rejects_descending_concentration_range` passed with adjacent
  boolean, non-finite, zero-width, and valid interpolation coverage.
- The complete suite passed with 76 tests.
- Repository-root and external-directory `make check` passed Ruff formatting
  and lint, all tests, Python compilation, and the baseline checker.
- Isolated hostile mutations were rejected for the source guard, stable error,
  focused test, numeric-string case, documentation, and completed plan.
- Exact intended-path, generated-artifact, mode, whitespace, conflict-marker,
  and credential-like value audits passed.
