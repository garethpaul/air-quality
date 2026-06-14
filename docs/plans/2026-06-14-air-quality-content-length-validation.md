# Air Quality Content-Length Validation

Status: Planned

## Context

The default sensor client rejects non-integer and oversized `Content-Length`
values before streaming. It currently accepts a negative integer even though a
response length cannot be negative, leaving malformed upstream metadata outside
the explicit header-validation contract.

## Scope

- Reject negative upstream `Content-Length` values with the existing generic
  integer-validation error.
- Preserve the HTTPS, public-host, redirect, timeout, status, streaming-size,
  response-cleanup, encoding, JSON, and payload-shape behavior.
- Add focused runtime and static contracts that fail if the lower-bound check
  or completed plan evidence is removed.
- Document the non-negative header requirement without exposing provider data.

## Implementation Units

### 1. Characterize the malformed header

Files:

- `air_tests.py`

Add a focused response test with a negative `Content-Length`. Require the
existing controlled header error and prove the response closes exactly once.

### 2. Enforce the lower bound

Files:

- `air.py`

Parse the header once and reject values below zero before reading the response
stream. Keep oversized-response handling and error normalization unchanged.

### 3. Protect and document the contract

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `docs/plans/2026-06-14-air-quality-content-length-validation.md`

Require the lower-bound check, focused regression, documentation, and completed
plan evidence in the dependency-free baseline checker.

## Verification

Planned:

- Run the focused negative-header regression and the full runtime suite.
- Run the complete `make check` gate from the repository root and an unrelated
  working directory.
- Reject focused mutations that remove the lower bound, regression, security
  wording, or completed plan status.
- Audit the exact diff, generated artifacts, whitespace, and credential-shaped
  additions before committing.

## Risks

- This change intentionally reuses the generic integer-validation error.
- It does not require `Content-Length`; chunked and absent-length responses
  remain bounded by the streamed-body limit.
- Live provider behavior remains outside the credential-free local test scope.
