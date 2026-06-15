# Air Quality Boolean Geocoder Coordinates

status: planned

## Context

`GeoCode` normalizes cached and upstream center values with `float()`. Python
therefore accepts JSON booleans as `1.0` and `0.0`, allowing malformed
geocoder data to become a valid-looking location and enter the cache.

## Requirements

- Reject boolean longitude and latitude values from cached geocoder entries.
- Reject boolean longitude and latitude values from upstream Mapbox centers.
- Preserve valid numeric and numeric-string coordinates, coordinate bounds,
  cache keys, cache transport errors, and public route behavior.
- Add focused regressions and mutation-sensitive static contracts for both
  cached and upstream boolean values.

## Scope Boundaries

- Do not change query parsing, Redis configuration, Mapbox integration,
  coordinate bounds, dependencies, route responses, or deployment behavior.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.
- Treat malformed cached coordinates as cache misses; preserve the existing
  upstream validation error for malformed Mapbox centers.

## Implementation Units

### U1: Reject boolean geocoder coordinates

**Files:** `geocode.py`, `geocode_tests.py`

**Approach:** Add explicit boolean guards before numeric conversion in the
cached-coordinate and upstream-center validation paths. Extend the existing
corrupt-cache refresh and malformed-center tests with longitude and latitude
boolean cases while preserving positive numeric-string coverage.

**Execution note:** Test-first using the existing table-driven regressions.

**Verification:** Focused geocoder tests prove cached booleans refresh through
the validated upstream path and upstream booleans fail before caching.

### U2: Keep the portable baseline fail closed

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`CHANGES.md`, `docs/plans/2026-06-15-air-quality-boolean-geocoder-coordinates.md`

**Approach:** Register source guards, both regression tables, maintained
guidance, and completed-plan evidence in the dependency-free checker.

**Verification:** Isolated mutations that remove either runtime guard, either
regression family, documentation, or completed-plan status are rejected.

## Verification Plan

- Run focused cached and upstream boolean-coordinate tests.
- Run the full test suite and every standard Make gate from the repository
  root and through the absolute Makefile path from an external directory.
- Run isolated hostile mutations for both guards, both regression families,
  documentation, and completed-plan evidence.
- Audit the exact intended diff, generated artifacts, suspicious secret
  patterns, and whitespace before committing.
