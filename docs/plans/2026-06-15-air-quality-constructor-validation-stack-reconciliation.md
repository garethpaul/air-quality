# Air Quality Constructor Validation Stack Reconciliation

Status: Completed

## Problem

The current remediation lineage ending at PR #33 includes the latest sensor,
cache, scoring, and AQI interpolation protections, but it does not inherit the
direct `AirQuality` constructor validation delivered independently in PR #25.
As a result, direct callers on the current stack can still construct service
objects with booleans, non-finite coordinates, or latitude/longitude values
outside geographic bounds even though HTTP and geocoder entry points reject
those values.

## Priorities

1. P0: Restore finite, bounded, non-boolean coordinate invariants at the
   reusable `AirQuality` construction boundary on the current stack.
2. P1: Preserve every newer cache, sensor, scoring, distance, and interpolation
   correction already present through PR #33.
3. P2: Reuse the behavior already validated in PR #25 without introducing a
   second coordinate policy or changing valid cache keys.

## Requirements

1. Reject boolean, nonnumeric, non-finite, overflowing, and out-of-range
   latitude and longitude values before collaborator access.
2. Accept exact geographic boundaries and valid numeric strings, normalized to
   floats.
3. Keep route errors, geocoder behavior, valid-coordinate cache keys, sensor
   selection, AQI calculations, dependencies, and workflows unchanged.
4. Preserve all current-stack tests and contracts, including non-finite
   scoring and zero-width or descending interpolation rejection.
5. Add fail-closed evidence that this integration remains present in the
   current lineage and that the plan records completed verification truthfully.

## Implementation Units

### U1: Reconcile The Constructor Invariant

**Files:** `air.py`, `air_tests.py`

Integrate the package-local coordinate normalization boundary and focused
constructor tests from the reviewed PR #25 implementation. Resolve against the
current stack rather than replacing files, and retain all newer source and test
changes.

### U2: Preserve Portable Contracts And Guidance

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`,
`docs/plans/2026-06-15-air-quality-constructor-coordinate-validation.md`, and
this plan.

Carry forward the existing constructor-validation contracts and guidance,
then require this reconciliation plan to identify the current-stack base,
preservation boundary, and completed verification.

### U3: Verify Current-Stack Compatibility

Run focused constructor tests first, followed by the complete repository and
external-directory gates. Reject mutations that remove boolean, finite, range,
or constructor integration checks, and separately prove that the current
non-finite scoring plus zero-width and descending interpolation regressions
remain green.

## Test Scenarios

- Boolean, nonnumeric, NaN, infinity, overflowing, and out-of-range values fail
  for either coordinate before cache or HTTP access.
- Boundary values and numeric strings normalize to floats and keep the existing
  cache-key format.
- Current sensor filtering, cached-score normalization, AQI category handling,
  antipodal distance, and interpolation guards remain unchanged.
- Repository-root and external-directory full gates pass on the supported
  Python runtime matrix.
- The exact branch diff contains only the reconciled invariant, its existing
  evidence, and this integration plan; no generated artifacts or secrets are
  introduced.

## Scope Boundaries

- Do not merge or close PR #25 or any current stacked PR.
- Do not retarget existing pull requests or rewrite branch history.
- Do not change route payloads, cache format, provider behavior, dependencies,
  workflows, or deployment configuration.
- Live Redis, Mapbox, and sensor-provider integration remain outside this
  deterministic reconciliation.

## Assumptions

- PR #25 at `35881343ba155428aafa41374f01267df80c1bb8` is the reviewed source
  implementation for this invariant; the current branch still requires its own
  complete validation because its descendant set differs.
- The current integration base is PR #33 head
  `4f56e528394ec731ceb06eb679efa8c45009444b`.

## Verification Completed

- The pre-integration probe reproduced acceptance of boolean, NaN, out-of-range
  latitude, and out-of-range longitude constructor inputs on PR #33.
- `test_constructor_rejects_invalid_coordinates` and
  `test_constructor_normalizes_boundary_coordinates_and_numeric_strings`
  passed with the current `test_scoring_helpers_reject_nonfinite_values`,
  `test_linear_rejects_zero_width_concentration_range`, and
  `test_linear_rejects_descending_concentration_range` regressions after
  reconciliation.
- Repository-root `make check` passed Ruff, all 78 tests, Python compilation,
  and the portable baseline once this completed plan evidence was present.
- The complete `make check` gate also passed from `/tmp` through the absolute
  Makefile path.
- Four isolated hostile mutations were rejected for constructor integration,
  boolean rejection, preservation of the descending-range guard, and completed
  reconciliation-plan evidence.
- Final audits and hosted exact-head state are recorded by the shipping
  evidence for this branch.
