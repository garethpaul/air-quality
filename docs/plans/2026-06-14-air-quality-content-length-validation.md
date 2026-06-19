# Air Quality Content-Length Validation

Status: Completed

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

Completed on 2026-06-14:

- The focused negative-header regression passed and proved response cleanup.
- The dependency-free runtime suite passed all 61 tests.
- Ruff formatting and lint checks passed across all Python files.
- Full `make check` passed from the repository root and from `/tmp` through the
  absolute Makefile path with a hostile `ROOT=/tmp` override; both runs passed
  formatting, lint, all 61 tests, compilation, and the baseline checker.
- Four isolated mutations were rejected when they removed the lower-bound
  comparison, renamed the regression, removed the security wording, or changed
  this plan back to `Status: Planned`.

## Risks

- This change intentionally reuses the generic integer-validation error.
- It does not require `Content-Length`; chunked and absent-length responses
  remain bounded by the streamed-body limit.
- Live provider behavior remains outside the credential-free local test scope.
