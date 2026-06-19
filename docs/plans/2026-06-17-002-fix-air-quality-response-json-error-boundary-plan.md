---
title: Air Quality Response JSON Error Boundary
type: fix
date: 2026-06-17
---

# Air Quality Response JSON Error Boundary

status: completed

## Summary

Normalize response-adapter JSON decoding failures at the sensor-provider
boundary so malformed upstream responses are reported as a stable service
failure rather than a caller error or provider-derived exception.

## Problem Frame

`AirQuality.getData` accepts either a decoded mapping or a response-like object
from its HTTP adapter. A response object's `json()` exception currently escapes
as `ValueError`, which the Bottle route classifies as HTTP 400 even when the
coordinates are valid and the upstream provider returned malformed JSON.

## Requirements

- R1. Convert every ordinary exception raised by a response-like adapter's
  `json()` method into a stable, unchained `RuntimeError` that contains no
  provider detail.
- R2. Preserve direct decoded-mapping adapters, valid response objects, payload
  shape validation, cache ordering, and existing public response formats.
- R3. Ensure malformed upstream response JSON follows the existing HTTP 503
  service-unavailable route boundary instead of the HTTP 400 caller-error path.
- R4. Add focused runtime and static regressions that reject removal or
  weakening of normalization, exception suppression, and route classification.
- R5. Update maintained security and change guidance without adding live
  provider calls, retries, dependencies, credentials, or configuration.

## Key Technical Decisions

- **Normalize at `AirQuality`'s adapter boundary:** both the default HTTP client
  and injected response-like adapters then share one stable provider-error
  contract before route classification.
- **Catch ordinary adapter exceptions:** response decoding implementations may
  raise different `Exception` subclasses; process-control exceptions remain
  untouched.
- **Raise without chaining:** public behavior and diagnostic strings must not
  retain provider-derived content through `__cause__`.
- **Retain decoded mappings:** test and custom adapters that already return a
  mapping remain supported without an artificial response wrapper.

## Implementation Units

### U1. Normalize response decoding

- **Files:** `air.py`, `air_tests.py`, `app_tests.py`
- **Goal:** introduce the narrow response-decoding boundary and prove stable,
  unchained service-error behavior while preserving direct mappings.
- **Verification:** focused unit tests must distinguish HTTP 503 classification
  from the existing HTTP 400 validation path.

### U2. Lock the contract and guidance

- **Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `VISION.md`,
  `CHANGES.md`, this plan
- **Goal:** require the source and test contracts, document the provider-error
  boundary, and record completed verification truthfully.
- **Verification:** repository-root and external-directory baseline gates plus
  isolated hostile mutations must reject weakened implementations.

## Scope Boundaries

- Do not change coordinate validation, AQI calculations, cache keys, cache
  ordering, request timeouts, response size limits, or deployment behavior.
- Do not expose provider exception text or add provider-specific response
  handling.
- Keep this pull request stacked on the geocoder-timeout enforcement branch.

## Verification Plan

- Run focused sensor and route tests before the complete Python suite.
- Run Ruff format/lint, shell syntax, Python compilation, and `make check` from
  both the repository and an external directory under the pinned environment.
- Reject mutations that restore inline `json()` decoding, preserve exception
  chaining, narrow away representative adapter failures, or remove route/static
  regression registration.
- Audit the exact diff, generated artifacts, added secret patterns, dependency
  and workflow drift, whitespace, and intended staged paths before each commit.

## Work Completed

- Added a response-adapter decode boundary that preserves decoded mappings and
  converts ordinary `json()` failures to an unchained generic service error.
- Added focused sensor and route regressions for exception redaction, direct
  mapping compatibility, and HTTP 503 classification.
- Extended the portable baseline and maintained reliability guidance.

## Verification Completed

- The focused `test_response_json_failure_is_normalized_without_detail`,
  `test_direct_mapping_http_adapter_remains_supported`, and
  `test_show_data_classifies_upstream_json_failure_as_service_unavailable`
  regressions passed.
- Ruff format and lint, all 108 unit tests, and Python compilation passed before
  the baseline plan-status gate was reconciled.
- Repository-root and external-directory `make check` each passed the complete
  Ruff, 108-test, compilation, and maintained baseline gate.
- Seven isolated mutations were rejected for inline decoding, narrowed
  exception handling, restored exception chaining, and removed runtime or route
  regression registration. The three source mutations also failed focused
  runtime tests where applicable.
- No live provider or cache request was made.
