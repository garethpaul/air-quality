# Air Quality Boolean Scoring Inputs

status: completed

## Context

Python booleans are integers, so the public scoring helpers currently accept
`True` and `False` as numeric values. `AQIPM25(True)` returns an AQI score,
`AQICategory(True)` returns a valid-looking response, and `Linear(..., True)`
interpolates a score. This contradicts the repository's boolean rejection at
route, geocoder, cache, and upstream sensor boundaries.

## Requirements

- Reject boolean concentration values before `AQIPM25` numeric conversion.
- Reject boolean interpolation values before `Linear` numeric conversion.
- Reject boolean AQI values before `AQICategory` numeric conversion.
- Preserve valid integers, floats, numeric strings, current EPA breakpoints,
  category guidance, route behavior, caching, and public response shapes.
- Add focused regressions and mutation-sensitive baseline contracts for all
  three scoring entry points.

## Scope Boundaries

- Do not change dependencies, deployment configuration, network behavior,
  cache keys, coordinate validation, AQI breakpoints, or category thresholds.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.
- Do not broaden this change into general scoring-helper API redesign.

## Implementation Units

### U1: Reject boolean scoring values

**Files:** `air.py`, `air_tests.py`

**Approach:** Add explicit pre-conversion boolean guards to `AQIPM25`,
`Linear`, and `AQICategory`. Extend focused table-driven tests to prove each
helper rejects both boolean values while representative numeric strings retain
their existing results.

**Verification:** The focused scoring tests fail before the guards and pass
afterward without changing the EPA breakpoint or category suites.

### U2: Keep the portable baseline fail closed

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`CHANGES.md`, `docs/plans/2026-06-15-air-quality-boolean-scoring-inputs.md`

**Approach:** Register source guards, focused regressions, maintained guidance,
and completed-plan evidence in the dependency-free checker.

**Verification:** Isolated mutations that remove each guard, the regression,
guidance, or completed-plan evidence are rejected.

## Verification Plan

- Run the focused scoring-helper tests first, then the full Python suite.
- Run Ruff formatting and linting, Python compilation, and every Make gate from
  the repository root and through the absolute Makefile path externally.
- Run isolated hostile mutations for each runtime guard, regression coverage,
  guidance, and plan completion evidence.
- Audit the exact intended diff, generated artifacts, suspicious secret
  patterns, and whitespace before committing.

## Work Completed

- Added pre-conversion boolean guards to `AQIPM25`, all five numeric `Linear`
  arguments, and `AQICategory`.
- Added `test_scoring_helpers_reject_boolean_values` across both boolean values
  and all seven scoring input positions while preserving numeric strings.
- Registered source, test, guidance, and completed-plan contracts in the
  dependency-free baseline checker and maintained repository guidance.

## Verification Completed

- `python run_tests.py` passed all 71 tests.
- Ruff formatting, Ruff lint, and Python compilation passed.
- The focused `test_scoring_helpers_reject_boolean_values` regression passed.
- `make check` passed from the repository root and through the absolute
  Makefile path from an external directory.
- Seven isolated hostile mutations covering each runtime guard, the focused
  regression, guidance, plan status, and completion evidence were rejected.
- No live Redis, Mapbox, or sensor-provider request was made.
- The exact diff, generated-artifact, file-mode, whitespace, and
  suspicious-secret audits passed before commit.
