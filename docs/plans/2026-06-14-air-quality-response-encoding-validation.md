# Air Quality Response Encoding Validation

Status: Planned

## Context

The default sensor client decodes the bounded response body with the encoding
reported by `requests`. Invalid bytes and malformed JSON are normalized to the
existing `AIRQUALITY_DATA response must be valid JSON` service error, but an
unknown encoding name raises `LookupError` outside that boundary. A malformed
upstream `charset` can therefore escape the controlled provider-failure path.

## Scope

- Normalize unsupported upstream response encodings to the existing generic
  JSON response error.
- Preserve the current HTTPS, public-host, redirect, timeout, status, size,
  streaming, response-cleanup, and payload-shape behavior.
- Add focused runtime and static contracts that fail if the encoding boundary
  or completed plan evidence is removed.
- Document the normalized encoding failure alongside the existing malformed
  JSON contract.

## Implementation Units

### 1. Characterize unsupported encoding failures

Files:

- `air_tests.py`

Add a focused test whose streamed response contains valid JSON bytes but
reports an unknown encoding name. Require the existing generic JSON error and
prove the response is still closed exactly once.

### 2. Extend the decode boundary

Files:

- `air.py`

Treat unknown codec names as the same controlled upstream JSON failure as
invalid bytes and invalid JSON. Keep the decode and parse order, error text,
and response cleanup unchanged.

### 3. Protect and document the contract

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `docs/plans/2026-06-14-air-quality-response-encoding-validation.md`

Require the expanded exception boundary, focused regression name, normalized
error, documentation, and completed plan evidence in the dependency-free
baseline checker. Update user and security documentation without changing the
public API contract.

## Verification

- Run the focused unsupported-encoding regression first.
- Run the dependency-free runtime suite and `make check` from the repository
  root and from an external working directory.
- Run focused hostile mutations for the `LookupError` boundary, regression
  name, documentation, and completed plan status.
- Run Python, shell, JSON, and YAML syntax checks plus `git diff --check`.
- Inspect only the intended paths for secrets and generated artifacts before
  committing.

## Risks

- This change intentionally preserves the existing generic JSON error rather
  than exposing the upstream charset value.
- It does not add content-type enforcement or change how valid codec names are
  decoded.
- Live provider behavior remains outside the credential-free local test scope.
