# Air Quality Geocoder Request Timeout

status: planned

## Context

The default Mapbox geocoder client calls its `requests.Session.get` method
without a timeout. A slow or stalled provider can therefore hold `/s` requests
open indefinitely even though the separate air-quality data download already
has a bounded timeout.

## Priority

Bound the remaining public-route network call before extending search behavior.
The route already converts geocoder transport failures to its generic service
error, so this can be fixed without changing response bodies or provider
failure classification.

## Requirements

- R1. Apply a five-second timeout to requests made by the default Mapbox
  geocoder client.
- R2. Preserve the SDK session's access-token parameters, headers, adapters,
  cache wrapper, and other attributes.
- R3. Do not alter explicitly injected geocoder clients used by tests or
  callers.
- R4. Preserve permanent-dataset selection, cache ordering, generic provider
  errors, and the no-result client-error path.
- R5. Focused tests, the maintained baseline, guidance, and completed plan
  evidence must be mutation-sensitive.
- R6. Do not add retries, logging, credentials, dependencies, provider calls,
  or configuration surface.

## Implementation Units

### U1. Default SDK session boundary

**File:** `geocode.py`

Wrap only the session owned by the default `Geocoder` instance. Delegate every
attribute to the original session and supply the timeout only when its `get`
call does not already provide one.

### U2. Focused and maintained tests

**Files:** `geocode_tests.py`, `scripts/check-baseline.sh`

Prove the default client sends the timeout while preserving delegated session
state, and prove an explicitly injected geocoder remains untouched. Require
the source and test contract from the portable gate.

### U3. Maintained guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

Record the bounded Mapbox transport without changing the existing Redis,
Mapbox dataset, or generic route-error model.

## Test Scenarios

- The default client delegates its request with `timeout=5.0`.
- Existing session parameters and headers remain visible through the wrapper.
- An injected geocoder receives no wrapper or signature change.
- Default-client construction still selects `mapbox.places-permanent` before
  caching the validated coordinates.
- Removing the timeout, delegation, focused assertions, guidance, or completed
  evidence fails the portable gate.

## Scope Boundaries

- Do not replace the archived Mapbox SDK or change access-token handling.
- Do not add retries or make live Mapbox, Redis, sensor, or deployment calls.
- Do not change query validation, cache keys, coordinate parsing, route JSON,
  the air-quality data timeout, or dependencies.

## Verification

- Run focused geocoder tests, the full Python suite, Ruff format/lint, Python
  compilation, all Make aliases, and the absolute Makefile externally.
- Reject isolated mutations for timeout injection, session delegation,
  injected-client preservation, test registration, guidance, and plan status.
- Audit the exact diff, generated artifacts, changed lines for credentials,
  dependency/workflow drift, and whitespace before commit.

## Verification Completed

Pending implementation and validation.
