# Negative AQI Category Classification

status: completed

## Context

`AirQuality.AQICategory` classifies every numeric value less than or equal to
50 as `Good`. That includes negative scores, even though the established AQI
domain starts at zero and scores above 500 already return `Out of Range`.

This helper is public and is also reused to validate cached guidance. A
negative score should never produce a healthy-looking category response.

## Requirements

- Classify finite negative AQI scores as `Out of Range` with `None` caution.
- Preserve the helper's existing integer-normalized `score` field.
- Preserve all existing 0-500 category thresholds and guidance text.
- Preserve the existing above-500 `Out of Range` behavior.
- Preserve boolean rejection and representative numeric-string support.
- Add focused runtime coverage and mutation-sensitive baseline contracts.

## Scope Boundaries

- Do not change AQI interpolation, PM2.5 breakpoints, cache keys, route
  behavior, dependencies, deployment configuration, or network behavior.
- Do not change non-finite input behavior in this focused correction.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.

## Implementation Units

### U1: Correct the lower AQI category boundary

**Files:** `air.py`, `air_tests.py`

**Approach:** Require a non-negative score for the `Good` branch so negative
finite values reach the existing `Out of Range` fallback. Add a focused
regression alongside the current above-500 category test and retain coverage
for zero, category thresholds, boolean rejection, and numeric strings.

**Verification:** The negative-score regression fails before the source change
and passes afterward while the existing scoring and cached-guidance suites
remain unchanged.

### U2: Keep maintenance evidence fail closed

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`CHANGES.md`, `docs/plans/2026-06-15-negative-aqi-category.md`

**Approach:** Register the corrected lower-bound predicate, focused regression,
guidance, and completed-plan evidence in the dependency-free checker.

**Verification:** Isolated mutations that remove the lower bound, regression,
guidance, or completed-plan evidence are rejected.

## Verification Plan

- Run the focused category tests first, then the complete Python test suite.
- Run Ruff formatting and linting, Python compilation, and every Make gate from
  the repository root and through the absolute Makefile path externally.
- Reject isolated lower-bound, regression, guidance, and plan-status mutations.
- Audit the exact intended diff, generated artifacts, suspicious secret
  patterns, file modes, and whitespace before committing.

## Risks

- Callers that incorrectly relied on negative scores being labeled `Good` will
  now receive the repository's existing `Out of Range` category.
- Non-finite helper inputs remain outside this narrow change and retain their
  current behavior.

## Work Completed

- Required the `Good` branch to start at zero so negative finite scores reach
  the existing `Out of Range` fallback.
- Added `test_category_handles_negative_out_of_range_score` for negative
  integer and fractional inputs while preserving integer score normalization.
- Added fail-closed source, regression, guidance, and plan contracts to the
  dependency-free checker and synchronized maintenance documentation.

## Verification Completed

- The focused category and scoring-helper tests passed.
- `python run_tests.py` passed all 72 tests.
- Ruff formatting, Ruff linting, and Python compilation passed.
- Five isolated hostile mutations covering the lower bound, regression,
  guidance, plan status, and completed evidence were rejected in initialized
  temporary repositories.
- `make check` passed from the repository root and through the absolute
  Makefile path from an external working directory.
- No live Redis, Mapbox, or sensor-provider request was made.
- The exact diff, generated-artifact, file-mode, whitespace, and
  suspicious-secret audits passed before commit.
