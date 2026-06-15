# Reject Non-Finite AQI Scoring Inputs

status: completed

## Context

`AirQuality.AQIPM25` explicitly rejects non-finite concentrations, but the
public `Linear` and `AQICategory` helpers still depend on incidental failures
from `round()` or `int()`. Depending on the helper and value, `NaN` and
infinity can raise different exception types after partial scoring work.

Every public scoring boundary should reject non-finite numeric input before
interpolation or category construction.

## Requirements

- Reject `NaN`, positive infinity, and negative infinity at every `Linear`
  argument position.
- Reject non-finite `AQICategory` scores before category selection or integer
  response normalization.
- Raise `ValueError` for these invalid scoring inputs.
- Preserve boolean rejection, finite numeric values, numeric strings, PM2.5
  breakpoints, category thresholds, cache behavior, and response shapes.
- Add focused runtime coverage and mutation-sensitive baseline contracts.

## Scope Boundaries

- Do not change route validation, distance calculations, cache keys,
  dependencies, workflows, deployment configuration, or network behavior.
- Do not change the existing finite negative or above-500 `Out of Range`
  category behavior.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.

## Implementation Units

### U1: Validate scoring-helper finiteness

**Files:** `air.py`, `air_tests.py`

**Approach:** Normalize the five `Linear` arguments to floats, reject any
non-finite normalized value, and calculate with the normalized tuple. Add an
explicit finite check after `AQICategory` score conversion. Extend the focused
helper table to cover all non-finite values and every interpolation position.

**Verification:** The focused tests fail against the current inconsistent
behavior and pass with uniform `ValueError` rejection while existing valid
numeric-string and category tests remain green.

### U2: Keep maintenance evidence fail closed

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`CHANGES.md`, `VISION.md`,
`docs/plans/2026-06-15-air-quality-nonfinite-scoring-inputs.md`

**Approach:** Register the finite-value predicates, focused regression,
maintained guidance, and completed-plan evidence in the dependency-free
checker.

**Verification:** Isolated mutations that remove either runtime predicate,
the test matrix, guidance, or completed-plan evidence are rejected.

## Verification Plan

- Run the focused scoring-helper tests first, then the complete Python suite.
- Run Ruff formatting and linting, Python compilation, and `make check` from
  the repository root and through the absolute Makefile path externally.
- Reject isolated source, test, guidance, and plan-status mutations.
- Audit the exact intended diff, generated artifacts, suspicious secret
  patterns, file modes, and whitespace before committing.

## Risks

- Direct callers that relied on incidental `OverflowError` or late conversion
  failures will now receive a deliberate `ValueError` at the helper boundary.
- Live Redis, Mapbox, and sensor-provider integration remain outside this
  deterministic scoring change.

## Work Completed

- Normalized all five `Linear` arguments and rejected any non-finite value
  before interpolation.
- Rejected non-finite `AQICategory` scores before category selection and
  integer response normalization.
- Added `test_scoring_helpers_reject_nonfinite_values`, a table-driven
  regression across every interpolation position, `AQICategory`, `NaN`,
  positive infinity, and negative infinity.
- Added fail-closed source, test, guidance, and plan contracts to the baseline
  checker and synchronized maintained documentation.

## Verification Completed

- The focused non-finite, boolean, and negative-category tests passed.
- `python3 run_tests.py` and `make test` passed all 74 tests.
- Ruff formatting, Ruff linting, and Python compilation passed.
- Repository-root `make check` passed Ruff, all 74 tests, Python compilation,
  and the dependency-free baseline checker.
- Six isolated hostile mutations covering both finite predicates, the focused
  regression, maintained guidance, plan status, and mutation evidence were
  rejected.
- The external-directory gate passed the same full check through the absolute
  Makefile path.
- Exact nine-path, generated-artifact, file-mode, whitespace, conflict-marker,
  and suspicious-secret audits passed before commit.
