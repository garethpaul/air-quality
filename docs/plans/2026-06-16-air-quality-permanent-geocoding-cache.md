# Permanent Mapbox Geocoding Cache

## Status: Completed

## Problem

`GeoCode` always reads and writes geocoding results through Redis, but its
default Mapbox client uses the SDK's `mapbox.places` dataset. Mapbox documents
that temporary geocoding results must not be cached, while permanent results
may be stored. The pinned Mapbox Python SDK 0.18.1 defaults to
`mapbox.places` and selects the cacheable v5 endpoint only when constructed as
`Geocoder(name="mapbox.places-permanent")`.

This is a P1 compliance boundary: the application's behavior requires stored
results, so the provider request must explicitly declare permanent geocoding.

## External Grounding

- Mapbox Geocoding API storage rules:
  https://docs.mapbox.com/api/search/geocoding/#storing-geocoding-results
- Mapbox Python SDK 0.18.1 package source: `Geocoder.__init__` defaults `name`
  to `mapbox.places`, and `forward` places that dataset in the v5 request URL.

## Requirements

- Construct the default Mapbox client with the exact
  `mapbox.places-permanent` dataset before any forward geocoding request.
- Preserve injected geocoder collaborators and all existing query, response,
  coordinate, cache-validation, and signed-zero behavior.
- Prove offline that a cache miss uses the permanent client, forwards the
  validated query once, and stores only the validated first-feature center.
- Keep provider credentials and response details out of public errors.
- Document that deployments need Mapbox permanent-geocoding entitlement and
  that this can carry provider billing implications.
- Protect the endpoint, constructor ordering, tests, guidance, and completed
  verification evidence with mutation-sensitive baseline contracts.

## Scope Boundaries

- Do not migrate the archived client from Mapbox Geocoding v5 to v6.
- Do not make the dataset configurable; an operator-selected temporary dataset
  would reintroduce noncompliant cache writes.
- Do not change Redis key format, cache lifetime, result selection, or public
  route payloads.
- Do not exercise live Mapbox credentials or create billable requests.
- Do not merge or close stacked pull requests without explicit authorization.

## Technical Design

- Add one named dataset constant in `geocode.py` and pass it to the lazy
  default `Geocoder` constructor.
- Extend `geocode_tests.py` with a fake `mapbox` module that records constructor
  arguments and returns the existing fake response shape. Keep this test fully
  offline and assert the validated result is written to Redis after the
  permanent client handles the query.
- Register exact constructor, call-order, test, documentation, and plan
  contracts in `scripts/check-baseline.sh`.
- Update `README.md`, `SECURITY.md`, and `CHANGES.md` with the permanent-storage
  prerequisite and operational risk.

## Implementation Units

### Permanent default geocoder

- **Files:** `geocode.py`
- Select `mapbox.places-permanent` for the lazily constructed SDK client while
  leaving injected test and application collaborators unchanged.

### Offline behavioral regression

- **Files:** `geocode_tests.py`
- Prove exact constructor arguments, one forward request, validated result
  shape, and post-validation cache publication without importing the real SDK.

### Contracts and operator guidance

- **Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`,
  `CHANGES.md`, this plan
- Require the implementation and executable regression, explain provider
  entitlement/billing, and record completed evidence.

## Verification Completed

- The focused permanent-dataset regression and all 18 geocoder tests passed.
- Ruff format/lint, Python compilation, and all 88 repository tests passed.
- The repository-root and external-directory `make check` commands passed.
- Six isolated hostile mutations were rejected for dataset fallback,
  constructor argument removal, request-before-client ordering, missing cache
  expectations, weakened guidance, and reopened plan status.
- Exact diff, generated-artifact, untracked-file, dependency/workflow drift,
  mode, credential-pattern, conflict-marker, and whitespace audits remain part
  of final validation.
- No live Mapbox request was made, so provider entitlement and billable
  behavior remain deployment prerequisites rather than local test claims.

## Risks

- Existing Mapbox accounts without permanent-geocoding entitlement will fail
  at the provider boundary instead of continuing noncompliant cache writes.
- Permanent geocoding can have different commercial terms or billing from the
  temporary endpoint; deployment owners must confirm entitlement before use.
- The pinned Mapbox Python SDK is archived and remains on Geocoding v5; a v6
  migration is a separate compatibility project.

## Assumptions

- Redis-backed storage remains a required product behavior.
- The provider account used in deployed environments is authorized for
  permanent geocoding before this stacked PR is released.
