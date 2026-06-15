# Air Quality Cache Guidance Consistency

status: planned

## Context

`AirQuality.cached_data()` validates the cached response shape and normalizes an
integer AQI score, but it still accepts scores above the service's maximum 500
and trusts cached `category` and `caution` strings independently of that score.
A stale or corrupted Redis entry can therefore return contradictory public
health guidance without using the validated upstream refresh path.

## Requirements

- Treat cached AQI scores outside the canonical 0-500 range as cache misses.
- Treat cached category or caution text that does not exactly match the
  canonical guidance for the validated score as a cache miss.
- Preserve valid cache hits, response shapes, cache keys, current EPA score
  calculation, upstream validation, and normalized cache transport errors.
- Add focused refresh tests and mutation-sensitive static contracts for the
  score ceiling and both semantic guidance fields.

## Scope Boundaries

- Do not change AQI breakpoint calculations, category wording, cache versions,
  Redis configuration, dependencies, route contracts, or deployment behavior.
- Do not contact Redis, Mapbox, or the air-quality data provider during tests.
- Do not repair mismatched entries in place; use the existing validated
  upstream refresh and cache replacement flow.

## Implementation Units

### U1: Enforce canonical cached guidance

**Files:** `air.py`, `air_tests.py`

**Approach:** Extend the existing cache validator after numeric normalization
to enforce the service's score ceiling and compare the complete cached payload
with the canonical category/caution response derived from that score. Exercise
out-of-range scores and independently mismatched category and caution values,
while retaining a positive valid-cache-hit assertion.

**Execution note:** Test-first using the existing corrupt-cache refresh table.

**Verification:** Focused cache refresh and valid-hit tests demonstrate that
invalid entries fetch and replace upstream data while canonical entries avoid
the upstream client.

### U2: Keep the baseline fail closed and documented

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`CHANGES.md`, `docs/plans/2026-06-15-air-quality-cache-guidance-consistency.md`

**Approach:** Register the new runtime cases and completed-plan evidence in the
dependency-free checker, and document that cached health guidance is validated
semantically rather than only by shape.

**Verification:** Isolated mutations to the score ceiling, category check,
caution check, regression fixtures, documentation, and plan completion are
rejected by the focused checker or full gate.

## Verification Plan

- Run the focused cached-data refresh and valid-hit tests.
- Run every standard Make gate from the repository root and the complete check
  through the absolute Makefile path from an external directory.
- Run isolated hostile mutations for the score ceiling, both semantic fields,
  regression cases, documentation, and completed-plan evidence.
- Audit the exact intended diff, generated artifacts, suspicious secret
  patterns, and whitespace before committing.
