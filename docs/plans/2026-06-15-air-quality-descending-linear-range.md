# Air Quality Descending Linear Range

status: planned

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
