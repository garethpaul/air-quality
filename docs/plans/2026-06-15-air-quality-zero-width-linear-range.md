# Reject Zero-Width AQI Interpolation Ranges

status: planned

## Context

`AirQuality.Linear` validates booleans and non-finite values, but equal
concentration endpoints still reach the interpolation division and raise an
incidental `ZeroDivisionError`. Invalid interpolation ranges should fail at
the public helper boundary with the same deliberate `ValueError` contract as
other invalid scoring inputs.

## Requirements

- Reject equal concentration endpoints before interpolation.
- Raise `ValueError` with a stable range-specific message.
- Preserve valid interpolation, numeric-string support, boolean and
  non-finite rejection, AQI breakpoints, category behavior, and response
  shapes.
- Add focused runtime coverage and mutation-sensitive baseline contracts.

## Scope Boundaries

- Do not change route validation, sensor selection, distance calculations,
  cache behavior, dependencies, workflows, deployment, or network behavior.
- Do not reject descending ranges; the defect is limited to a zero divisor.
- Do not contact Redis, Mapbox, or the air-quality provider during tests.

## Implementation Units

### U1: Validate interpolation range width

**Files:** `air.py`, `air_tests.py`

**Approach:** After numeric normalization and finite validation, reject equal
concentration endpoints before division. Add a focused regression covering
numeric and numeric-string endpoints while preserving valid string input.

**Verification:** The regression reproduces `ZeroDivisionError` before the
fix and passes with a stable `ValueError` afterward.

### U2: Keep maintenance evidence fail closed

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`CHANGES.md`, `VISION.md`,
`docs/plans/2026-06-15-air-quality-zero-width-linear-range.md`

**Approach:** Register the runtime guard, focused regression, maintained
guidance, and completed-plan evidence in the dependency-free checker.

**Verification:** Isolated mutations removing the guard, regression,
guidance, or completed-plan evidence are rejected.

## Verification Plan

- Run the focused scoring tests, then the complete Python suite.
- Run Ruff formatting and linting, Python compilation, and `make check` from
  the repository root and through the absolute Makefile path externally.
- Reject isolated source, test, guidance, and plan-status mutations.
- Audit the exact intended diff, generated artifacts, suspicious secret
  patterns, file modes, and whitespace before committing.

## Risks

- Direct callers relying on `ZeroDivisionError` will now receive the public
  helper's deliberate `ValueError` contract.
- Live Redis, Mapbox, and provider integration remain outside this
  deterministic scoring change.
