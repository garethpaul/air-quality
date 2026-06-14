# Air Quality Overflowing Geocoder Center Values

Status: Completed

## Problem

Mapbox center values are converted with `float`, but values larger than the
runtime float range raise `OverflowError`. That exception bypasses the existing
numeric-validation boundary and can escape the stable invalid-request path.

## Requirements

1. Normalize overflowing longitude and latitude center values to the existing
   numeric `ValueError` contract.
2. Prove both center positions reject oversized JSON integers.
3. Preserve valid numeric strings, finite/range checks, cache behavior, and
   geocoder transport error normalization.
4. Add source, test, documentation, and completed-plan contracts.

## Scope Boundaries

- Do not change query parsing, Mapbox credentials, cache keys, sensor reading
  selection, route status codes, or upstream HTTP behavior.
- Do not claim live Mapbox, Redis, or deployed-service verification.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- `python3 -m unittest geocode_tests` passed all 12 geocoder tests, including
  `test_overflowing_geocoder_center_values_raise_value_error` for oversized
  longitude and latitude values.
- Repository-root and external-working-directory `make check` both passed Ruff
  formatting/lint, all 65 tests, bytecode compilation, and source,
  documentation, and completed-plan contracts.
- Six hostile mutations were rejected for removing the overflow guard, test
  identity, either coordinate-position case, documentation, or completed plan
  status.
- No live Mapbox, Redis, or deployed-service execution is claimed.
