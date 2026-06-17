# Air Quality Geocoder Timeout Enforcement

status: completed

## Context

The default Mapbox session wrapper currently uses `setdefault` when adding the
five-second request timeout. That protects the SDK's present call shape, but a
future SDK call that supplies `timeout=None` or a larger value can bypass the
service's advertised upper bound and leave `/s` requests waiting indefinitely.

## Priority

Make the existing network bound fail closed before adding more provider or
search behavior. This is a narrow correction to the already-delivered timeout
boundary and does not require a new dependency or response contract.

## Requirements

- R1. Every default Mapbox session `get` call must use the service-owned
  five-second timeout, even when the caller supplies another timeout value.
- R2. Preserve request arguments, SDK session attributes, permanent-dataset
  selection, injected-geocoder behavior, cache ordering, and route errors.
- R3. Add a focused runtime regression proving `None`, oversized, and shorter
  caller-provided timeout values cannot override the service bound.
- R4. Update the portable static contract and maintained guidance without
  weakening any existing timeout, session, or injected-client assertion.
- R5. Make no live Mapbox, Redis, sensor, or deployment request and add no
  retries, credentials, dependencies, or configuration surface.

## Implementation

1. Replace the optional timeout default with an unconditional service timeout
   assignment in `_TimeoutSession.get`.
2. Exercise conflicting caller timeout values against a recording session.
3. Require the fail-closed assignment and focused test from the baseline gate.
4. Record the enforced upper bound in maintained security and change guidance.

## Verification Plan

- Run the focused geocoder tests and the complete Python suite.
- Run Ruff format/lint, Python compilation, and `make check` from the repository
  and an external directory under the pinned development environment.
- Reject isolated mutations for optional timeout injection, removed runtime
  coverage, weakened static registration, and incomplete plan evidence.
- Audit the exact diff, generated artifacts, added secret patterns, dependency
  and workflow drift, and whitespace before commit.

## Scope Boundaries

- Do not change the timeout duration or expose it as user configuration.
- Do not wrap explicitly injected geocoder clients.
- Do not alter cache keys, query validation, coordinate parsing, provider
  payload handling, route JSON, or the separate sensor-data timeout.
- Keep this pull request stacked on the existing geocoder-timeout delivery.

## Verification Completed

- Focused geocoder tests and all 105 tests passed.
- Ruff format and lint checks, shell syntax validation, Python compilation,
  and whitespace validation passed under the pinned Python 3.12 environment.
- Repository-root and external-directory `make check` each passed the complete
  Ruff, 105-test, compilation, and maintained baseline gate.
- Five isolated hostile mutations were rejected for optional or missing timeout
  enforcement, missing runtime registration, missing guidance, and incomplete
  plan status. Both timeout-source mutations also failed the focused runtime
  regression.
- No live Mapbox request was made.
