# Classify Malformed Geocoder Payloads As Service Errors

Status: Completed

## Problem

`GeoCode.getLatLng` normalizes Mapbox request and JSON-decoding failures to the
generic geocoder service error, but structural validation runs outside that
boundary. A malformed provider payload therefore raises `ValueError`, and the
`/s` route reports a client-side `400 invalid request` even though the query was
valid and the provider response was at fault.

## Priorities

1. P0: Classify malformed Mapbox payloads and coordinates as service failures.
2. P1: Preserve a valid empty feature list as the existing no-result client
   error.
3. P1: Keep provider-controlled details out of public exceptions and route
   responses.
4. P1: Add deterministic runtime and mutation-sensitive static coverage.

## Requirements

1. Invalid provider roots, feature collections, features, centers, coordinate
   values, and coordinate bounds must raise the existing generic
   `RuntimeError("geocoder request failed")` from `getLatLng`.
2. A valid `{"features": []}` response must continue to raise `ValueError` so
   the existing no-result route behavior is unchanged.
3. Request, JSON-decoding, cache, successful geocoding, and permanent-dataset
   behavior must remain unchanged.
4. Normalized service failures must suppress the provider exception cause and
   message.

## Implementation Units

### U1: Separate No Results From Malformed Results

**File:** `geocode.py`

Use a private `ValueError` subtype for the valid no-result outcome. Normalize
all other structural validation failures from the provider payload to the
existing geocoder service error at the `getLatLng` boundary.

### U2: Add Failure Classification Regressions

**File:** `geocode_tests.py`

Cover malformed roots, features, centers, nonnumeric values, non-finite values,
overflow, booleans, and out-of-range coordinates. Assert the generic runtime
error, suppressed cause, and absence of provider details. Preserve the empty
feature-list `ValueError` regression.

### U3: Protect And Document The Boundary

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require the exception separation, normalization ordering, focused tests,
maintained guidance, and completed verification record in the dependency-free
checker.

## Test Scenarios

- A valid empty feature list remains a no-result `ValueError`.
- Malformed roots, feature collections, feature objects, and center shapes
  raise only `RuntimeError("geocoder request failed")`.
- Boolean, nonnumeric, non-finite, overflowing, and out-of-range centers use
  the same service-error boundary.
- Valid centers remain normalized, cached, and returned unchanged.
- Repository and external-directory `make check` remain green.

## Scope Boundaries

- Do not change query validation, cache keys, cache persistence, Mapbox dataset,
  coordinate normalization, Bottle response bodies, or air-quality fetching.
- Do not expose malformed provider values or exception messages.
- Do not make live Mapbox, Redis, or deployed-instance requests.

## Verification

- Preserve the pre-change reproduction showing a malformed center escaping as
  `ValueError`.
- Run focused geocoder and route tests plus the complete test suite.
- Run Ruff, Python compilation, and repository and external-directory
  `make check` with explicit timeouts.
- Reject isolated mutations that remove the no-result exception distinction,
  provider-payload normalization, focused tests, static registration,
  maintained guidance, or completed plan status.
- Audit the exact diff, generated artifacts, dependency/workflow drift,
  credential-shaped additions, conflict markers, modes, and whitespace.

## Completed Verification

- The pre-change reproduction showed a malformed Mapbox center escaping from
  `getLatLng` as `ValueError`; the completed implementation returns only the
  unchained generic geocoder service error for malformed provider payloads.
- The focused geocoder suite passed 21 tests and the route suite passed 15
  tests. The complete `python run_tests.py` suite passed all 96 tests.
- Ruff formatting and lint, Python compilation, and the dependency-free
  baseline checker passed.
- Repository and external-directory `make check` passed with explicit
  timeouts.
- Seven isolated hostile mutations were rejected: removing the private
  no-result exception, widening the no-result branch, removing malformed
  payload normalization, reversing exception order, removing a focused test,
  removing maintained guidance, and falsifying plan status.
- Exact diff, generated-artifact, dependency/workflow drift,
  credential-shaped addition, conflict-marker, file-mode, and whitespace
  audits passed.
