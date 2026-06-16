# Enforce The Network JSON UTF-8 Boundary

Status: Planned

## Problem

The bounded `AIRQUALITY_DATA` client validates JSON media types but decodes the
response body with any valid codec name exposed by Requests. A provider can
therefore send non-UTF-8 bytes with a codec such as ISO-8859-1 and have the
payload accepted as JSON. RFC 8259 requires JSON exchanged between networked
systems to use UTF-8 and defines no `charset` parameter for
`application/json`.

## Priorities

1. P0: Reject non-UTF-8 upstream JSON encodings before semantic payload use.
2. P1: Preserve accepted UTF-8 declarations, structured `+json` media types,
   bounded streaming, and response cleanup.
3. P1: Normalize encoding violations to the existing generic JSON response
   error without exposing provider-controlled header values.
4. P1: Add deterministic regressions and maintained security guidance for the
   network JSON encoding boundary.

## Requirements

1. Upstream JSON bodies must be decoded as UTF-8 regardless of Requests'
   codec inference.
2. A declared or inferred non-UTF-8 encoding must fail with the existing
   `AIRQUALITY_DATA response must be valid JSON` error.
3. UTF-8 codec aliases and ordinary `application/json` or
   `application/*+json` responses must remain accepted.
4. Rejected responses must still close exactly once and must not expose the
   upstream encoding value.
5. Baseline contracts must protect source integration, focused runtime tests,
   maintained guidance, and completed verification evidence.

## Implementation Units

### U1: Validate The JSON Encoding

**File:** `air.py`

Add a small encoding guard at the accepted JSON response boundary. Resolve the
reported codec through Python's codec registry, require its canonical name to
be UTF-8, and decode the bounded body explicitly as UTF-8. Normalize unknown,
non-UTF-8, and invalid byte sequences through the existing generic JSON error.

### U2: Add Encoding Regressions

**File:** `air_tests.py`

Cover UTF-8 aliases, a valid non-UTF-8 JSON byte sequence, and response cleanup.
The non-UTF-8 case must demonstrate that the pre-change implementation accepts
the payload and the completed implementation rejects it without leaking the
codec name.

### U3: Protect And Document The Boundary

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require the encoding guard, explicit UTF-8 decode, focused regressions,
maintained guidance, and completed plan status in the dependency-free checker.
Document the RFC 8259 network JSON boundary without changing the public API.

## Test Scenarios

- `application/json` with UTF-8 bytes and a UTF-8 alias is accepted.
- `application/json` with ISO-8859-1 bytes and a matching codec name is
  rejected before payload use.
- Unknown codec names and invalid UTF-8 bytes retain the existing generic JSON
  error.
- Every success and failure path closes the response exactly once.
- Repository and external-directory `make check` remain green.

## Scope Boundaries

- Do not change HTTPS, public-host, redirect, timeout, status, size,
  content-length, media-type, cache, scoring, route, or Mapbox behavior.
- Do not add content negotiation or accept non-UTF-8 JSON for compatibility.
- Do not expose upstream charset or codec values in service errors.
- Live provider, TLS proxy, and deployed-instance behavior remain outside
  local validation.

## Verification

- Preserve the pre-change reproduction that accepts ISO-8859-1 JSON.
- Run focused response-encoding tests and the complete test suite.
- Run Ruff, Python compilation, and repository and external-directory
  `make check` with explicit timeouts.
- Reject isolated mutations that remove canonical codec validation, restore
  arbitrary response decoding, remove either focused regression, remove
  maintained guidance, or falsify plan status.
- Audit the exact diff, generated artifacts, dependency and workflow drift,
  credential-shaped additions, conflict markers, modes, and whitespace.

## External Basis

- RFC 8259 section 8.1 requires network-transmitted JSON to use UTF-8.
- The RFC 8259 media type registration defines no `charset` parameter for
  `application/json`.
