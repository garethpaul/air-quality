# Overflowing Cached Numeric Values

status: planned

## Context

Fresh sensor readings and Mapbox centers already handle integers too large for
Python's `float()` conversion. The corresponding Redis cache validators do not:
an oversized AQI score or cached latitude/longitude raises `OverflowError`
instead of treating the entry as corrupt and refreshing it from the configured
upstream.

## Requirements

- Treat overflowing cached AQI scores as cache misses.
- Treat overflowing cached geocoder coordinates as cache misses.
- Preserve valid cache hits, finite/range checks, public response shapes, cache
  keys, upstream error normalization, and credential boundaries.
- Add focused refresh tests and mutation-sensitive static contracts for both
  cache paths.

## Scope Boundaries

- Do not change route contracts, AQI calculations, coordinate bounds, Redis
  configuration, Mapbox configuration, dependencies, or deployment behavior.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.

## Verification Plan

- Run the focused AQI and geocoder cache-refresh tests.
- Run every standard Make gate from the repository root and the complete check
  through the absolute Makefile path from an external directory.
- Run isolated hostile mutations against both exception guards, tests,
  documentation, and completed plan evidence.
- Audit the intended diff, secrets, generated artifacts, and whitespace before
  committing.
