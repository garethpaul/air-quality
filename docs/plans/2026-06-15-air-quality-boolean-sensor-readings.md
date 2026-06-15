# Air Quality Boolean Sensor Readings

status: in progress

## Context

`AirQuality.nearest_reading` normalizes upstream `PM2_5Value`, `Lat`, and
`Lon` fields with `float()`. Python therefore accepts JSON booleans as `1.0`
and `0.0`, allowing malformed provider data to participate in nearest-sensor
selection and produce a cacheable AQI response. Cached AQI values and Mapbox
coordinates already reject this bool-as-number edge case.

## Priorities

1. **P0: Reject boolean upstream sensor fields.** Prevent malformed PM2.5 and
   coordinate values from affecting sensor selection or cache writes.
2. **P1 follow-up: Harden direct `AirQuality` construction.** Review whether
   non-route callers need the same coordinate type, finite-value, and bounds
   guarantees as `app.air_quality_payload`.
3. **P2 follow-up: Review strict result schemas.** Decide separately whether
   provider and cache objects should reject unknown fields instead of ignoring
   them for forward compatibility.

This plan implements only P0.

## Requirements

- Ignore upstream readings whose PM2.5, latitude, or longitude value is a
  boolean before numeric conversion.
- Preserve valid integers, floats, numeric strings, zero values, finite and
  coordinate-range checks, nearest-reading selection, AQI calculation, cache
  keys, and route behavior.
- Add focused regressions that prove each boolean field is skipped in favor of
  the nearest valid reading and cannot become cached output.
- Add mutation-sensitive source, fixture, documentation, and completed-plan
  contracts to the dependency-free baseline checker.

## Scope Boundaries

- Do not change route parsing, Redis behavior, provider URLs, response
  streaming, AQI breakpoints, dependencies, deployment configuration, or
  public response shapes.
- Do not reject ordinary numeric strings or integer zero values.
- Do not contact Redis, Mapbox, or the live air-quality provider during tests.

## Implementation Units

### U1: Reject boolean sensor fields before conversion

**Files:** `air.py`, `air_tests.py`

**Approach:** Add an explicit boolean-field guard in `nearest_reading` before
the existing `float()` conversions. Extend the nearest-valid-sensor regression
coverage with independent boolean PM2.5, latitude, and longitude readings
placed closer than a valid fallback so accepting any mutation changes the
observable result.

**Execution note:** Test-first using the existing table-driven invalid-reading
coverage and synthetic in-memory cache/provider helpers.

**Verification:** Focused tests prove all three malformed readings are skipped,
the valid fallback is selected, and the normalized fallback response is the
only value written to cache.

### U2: Keep the portable baseline and guidance fail closed

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `AGENTS.md`,
`CHANGES.md`, `docs/plans/2026-06-15-air-quality-boolean-sensor-readings.md`

**Approach:** Register the runtime guard, all three regression fixtures,
maintained guidance, and completed-plan evidence in the dependency-free
checker. Document boolean sensor rejection alongside existing non-finite and
overflowing sensor handling.

**Verification:** Isolated mutations to the runtime guard, each field fixture,
documentation, and plan completion are rejected by the focused checker or full
gate.

## Verification Plan

- Run focused nearest-reading and cache-write regressions.
- Run the full test suite and every standard Make gate from the repository
  root and through the absolute Makefile path from an external directory.
- Run isolated hostile mutations for the guard, all three fixtures,
  documentation, and completed-plan evidence.
- Audit the exact intended diff, generated artifacts, conflict markers,
  suspicious secret patterns, and whitespace before committing.

## Work Completed

Pending implementation.

## Verification Completed

Pending implementation and validation.
