# Air Quality Upstream Size Limit

Status: Completed

## Context

The sensor-data request had a timeout but decoded the entire upstream response
without a size limit. A compromised or misconfigured endpoint could therefore
force excessive memory use before payload validation ran.

## Changes

- Stream the default sensor-data response in 64 KiB chunks.
- Reject declared or observed bodies larger than 1 MiB.
- Raise on HTTP failures and reject invalid JSON before payload-shape checks.
- Preserve injected response objects used by dependency-free unit tests.
- Pin hosted verification to Ubuntu 24.04 with superseded-run cancellation.
- Make repository verification independent of the caller's working directory.

## Verification

- `make check`
- Root-independent `make test`
- Unit tests for timeout/streaming and declared/observed size limits
- Mutation checks for byte caps, CI, Make paths, and plan completion
- `git diff --check`
