# Strict Content-Length Syntax

Status: Planned

## Context

The default sensor client parses an upstream `Content-Length` with Python's
`int()`. That conversion accepts forms such as leading signs, surrounding
whitespace, and underscore separators even though the HTTP field value is a
non-empty sequence of ASCII decimal digits. Accepting those malformed values
weakens the response-metadata boundary before streaming.

## Scope

- Accept only non-empty ASCII decimal digits when `Content-Length` is present.
- Preserve absent-header behavior, the 1 MiB streamed-body limit, the generic
  malformed-header error, and exact response cleanup.
- Add focused runtime and static contracts that reject permissive parser
  mutations.
- Update operator and security documentation with the strict syntax contract.

## Implementation Units

### 1. Characterize strict field syntax

Files:

- `air_tests.py`

Cover signed, whitespace-padded, underscore-separated, comma-joined,
non-ASCII-digit, empty, and non-string values. Require rejection before body
streaming and prove every response closes exactly once. Retain valid zero and
upper-bound behavior.

### 2. Enforce ASCII decimal digits

Files:

- `air.py`

Validate the supplied header against an anchored ASCII-digit expression before
integer conversion. Keep the existing oversized-response branch and error
messages unchanged.

### 3. Protect and document the boundary

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `docs/plans/2026-06-14-strict-content-length-syntax.md`

Require the parser, focused regression, documentation, and completed plan
evidence in the dependency-free baseline checker.

## Verification

To be recorded after implementation:

- Focused strict-header regressions.
- Full runtime, formatting, lint, compilation, and baseline checks.
- Repository-root and external-directory `make check` invocations.
- Isolated mutations of parser, tests, documentation, and plan status.

## Risks

- Some non-compliant upstream servers may send a value previously accepted by
  Python's permissive integer conversion; those responses will now fail closed.
- `Content-Length` remains optional, and responses without it remain bounded by
  the streamed-body limit.
- This change does not alter Requests' handling of duplicate response headers.
