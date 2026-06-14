# Pre-Extend Stream Size Check

## Status: Planned

## Context

The upstream sensor response loop enforces a 1 MiB decoded-body limit, but it
currently appends each chunk before checking the accumulated size. An
oversized chunk therefore expands the retained byte buffer before the request
is rejected.

## Priority

Reject a chunk whose prospective accumulated size exceeds the limit before
mutating the response buffer.

## Requirements

- Calculate the prospective body size before extending the accumulator.
- Reject oversized chunks with the existing stable response-too-large error.
- Preserve empty-chunk handling, exact-limit acceptance, streaming behavior,
  response cleanup, JSON decoding, and all existing transport boundaries.
- Add a focused regression that observes no accumulator extension on the
  oversized path.
- Add mutation-sensitive baseline contracts and maintained documentation.

## Verification

- Focused streamed-response size tests
- Repository and external-directory `make check`
- Mutations covering check order, prospective arithmetic, test observability,
  documentation, and plan status
- Generated-artifact, credential-pattern, exact-diff, staged-path, and
  whitespace audits

## Scope Boundary

This change does not alter the 1 MiB limit, HTTP client, chunk size, content
encoding behavior, media-type validation, Content-Length policy, or JSON
schema validation.
