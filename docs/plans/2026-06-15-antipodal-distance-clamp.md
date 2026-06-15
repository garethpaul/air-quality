# Clamp Antipodal Distance Rounding

status: planned

## Context

`AirQuality.distance` evaluates the haversine intermediate directly with
`asin(sqrt(a))`. For valid near-antipodal coordinates, floating-point rounding
can produce an intermediate slightly above the mathematical maximum, such as
`1.0000000000000004`. Python then raises `ValueError: math domain error`, so a
valid sensor row can abort nearest-reading selection.

## Requirements

- Clamp only floating-point drift outside the haversine intermediate's
  mathematical `[0, 1]` domain before the square root and inverse sine.
- Preserve existing coordinate validation, nearest-reading ordering, and
  distance units.
- Add a deterministic near-antipodal regression that fails on the current
  implementation.
- Add mutation-sensitive source, test, documentation, and completed-plan
  contracts.

## Scope Boundaries

- Do not change coordinate bounds, sensor filtering, AQI calculations, cache
  behavior, dependencies, deployment configuration, or network behavior.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.

## Implementation Units

### U1: Bound the haversine intermediate

**Files:** `air.py`, `air_tests.py`

**Approach:** Clamp the computed intermediate to `[0.0, 1.0]` immediately
before `sqrt` and `asin`. Add a regression using a valid coordinate pair whose
unclamped intermediate is greater than one because of floating-point drift.

**Verification:** The focused regression raises a math-domain error before the
source change and returns the half-earth-circumference distance afterward.

### U2: Preserve maintenance evidence

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`VISION.md`, `CHANGES.md`, this plan

**Approach:** Register the clamp, regression, guidance, and completed evidence
with the dependency-free baseline checker.

**Verification:** Isolated mutations removing the lower clamp, upper clamp,
regression, guidance, or completed evidence are rejected.

## Verification Plan

- Run the focused distance regression and complete Python test suite.
- Run Ruff formatting and linting, Python compilation, and every Make gate from
  the repository and through the absolute Makefile path externally.
- Reject isolated clamp, regression, guidance, and plan-status mutations.
- Audit the exact diff, generated artifacts, suspicious secret patterns, file
  modes, and whitespace before commit.

## Risks

- Clamping hides only representational drift at a mathematically bounded
  intermediate; existing coordinate validation remains responsible for
  rejecting invalid inputs.
