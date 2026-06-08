---
title: Air Quality Engineering Bar Modernization
type: test
status: completed
date: 2026-06-08
---

# Air Quality Engineering Bar Modernization

## Summary

Modernize the small Bottle air-quality service enough that future changes can be tested, linted, and built without live Redis, Mapbox, or air-quality feed dependencies. The work keeps the existing public routes and AQI behavior intact while making the service code injectable and the quality gates explicit.

---

## Problem Frame

The repository currently depends on external services during import and tests, which makes local and CI verification fragile. The highest-leverage engineering-bar lift is to isolate those dependencies behind late initialization and test doubles, then wire deterministic tests into a repeatable quality gate.

---

## Requirements

- R1. Unit tests must run without a live Redis instance, Mapbox credentials, or a reachable `AIRQUALITY_DATA` endpoint.
- R2. Air-quality lookup must preserve nearest valid PM2.5 sensor selection, skip incomplete or invalid readings, ignore PM2.5 values below 5, and cache successful category responses.
- R3. Geocoding lookup must preserve first Mapbox feature coordinate parsing, cache successful query responses, and raise a clear error when no results are returned.
- R4. Missing runtime configuration must fail at the point an uncached external dependency is needed, not at module import time.
- R5. The test runner must return a non-zero process status when the unittest suite fails.
- R6. The repository must expose repeatable lint, test, and build commands for local development and CI.
- R7. CI must install runtime and development dependencies, then run the same lint, test, and build gates used locally.
- R8. Documentation must describe setup, runtime configuration, and the quality gates expected before pushing.

---

## Key Technical Decisions

- **Inject external boundaries in constructors:** `AirQuality` and `GeoCode` should accept cache, HTTP, and geocoder collaborators so tests can exercise behavior without network services.
- **Lazy runtime dependency loading:** Redis, Requests, and Mapbox clients should be initialized only when an uncached code path needs them, keeping imports and unit tests deterministic.
- **Use stdlib unittest with lightweight fakes:** The repository is small enough that `unittest`, `JsonResponse`, and an in-memory cache provide adequate coverage without introducing pytest or heavier mocking dependencies.
- **Keep dependency modernization conservative:** Pin a minimal development toolchain and only add runtime transitive pins required to make installation deterministic, avoiding a broad framework migration in the same change.
- **Make Makefile targets the source of CI truth:** CircleCI should call `make lint`, `make test`, and `make build` so local and remote verification do not drift.

---

## Scope Boundaries

- The public `/` and `/s` route shapes stay unchanged.
- AQI breakpoint math and category text stay unchanged except for making out-of-range caution handling explicit.
- This pass does not migrate Bottle, Mapbox, Redis, or Requests to newer major versions.
- This pass does not add an application factory or request-level route tests.

---

## Implementation Units

### U1. Deterministic AirQuality Core Tests

- **Goal:** Make air-quality behavior testable without Redis or HTTP while preserving PM2.5 selection and category semantics.
- **Files:** `air.py`, `air_tests.py`, `test_helpers.py`
- **Patterns:** Constructor injection for cache and HTTP boundaries; lazy Redis initialization for production paths.
- **Test Scenarios:**
  - `air_tests.py` verifies nearest valid sensor selection, cache reuse, and single HTTP fetch.
  - `air_tests.py` verifies no valid sensor raises `ValueError`.
  - `air_tests.py` verifies zero coordinates are accepted as valid sensor coordinates.
  - `air_tests.py` verifies out-of-range AQI category responses include a caution and score.
- **Verification:** `make test`

### U2. Deterministic GeoCode Tests

- **Goal:** Make geocoding behavior testable without Redis or Mapbox while preserving first-feature coordinate parsing.
- **Files:** `geocode.py`, `geocode_tests.py`, `test_helpers.py`
- **Patterns:** Constructor injection for cache and geocoder boundaries; lazy Mapbox client initialization for production paths.
- **Test Scenarios:**
  - `geocode_tests.py` verifies first Mapbox feature center is converted to `{lat, lng}`.
  - `geocode_tests.py` verifies cached calls do not invoke the fake geocoder again.
  - `geocode_tests.py` verifies an empty feature list raises `ValueError`.
- **Verification:** `make test`

### U3. Quality Gate Harness

- **Goal:** Make local and CI checks explicit and fail-fast.
- **Files:** `run_tests.py`, `Makefile`, `requirements-dev.txt`, `pyproject.toml`, `.circleci/config.yml`
- **Patterns:** `run_tests.py` builds the unittest suite and exits according to result status; Make targets wrap formatter, linter, tests, and compile build checks.
- **Test Scenarios:**
  - `make test` exits zero for the current passing suite.
  - A failing unittest would make `run_tests.py` exit non-zero.
  - `make lint` checks formatting and static issues with Ruff.
  - `make build` compiles tracked Python files.
- **Verification:** `make lint`, `make test`, `make build`

### U4. Developer Documentation

- **Goal:** Record setup, runtime configuration, quality gates, and change rationale.
- **Files:** `README.md`, `CHANGES.md`, `.gitignore`
- **Patterns:** Keep docs short and command-oriented for a small service.
- **Test Scenarios:**
  - README setup commands match the dependency files.
  - README quality gates match the Makefile target names.
  - CHANGES summarizes behavior and tooling changes made in this modernization pass.
- **Verification:** Manual doc review plus `make lint`, `make test`, `make build`

---

## Risks & Dependencies

- Mapbox 0.17.1 carries old AWS transitive dependencies; conservative pins may be needed to keep installs deterministic until a broader dependency modernization pass is planned.
- Bottle 0.12.8 and Requests 2.20.1 are old enough to warrant a follow-up security modernization, but updating them in the same pass could change runtime behavior beyond this testability-focused scope.
- CircleCI image and cache changes should be verified in remote CI after push because local checks cannot prove hosted CI configuration correctness.

---

## Sources / Research

- `air.py` contains the PM2.5 lookup, AQI math, Redis cache use, and air-quality feed dependency.
- `geocode.py` contains Mapbox lookup and Redis cache use.
- `run_tests.py` is the local test entrypoint used by the previous CI config.
- `.circleci/config.yml` is the hosted CI entrypoint for the repository.
