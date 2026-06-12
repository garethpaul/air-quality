# Air Quality Upstream Response Cleanup

Status: Completed

## Context

The default sensor-data client streams and bounds upstream responses, but it
does not close the response object after reading it. Repeated requests can
therefore retain pooled connections or sockets longer than necessary, and the
same leak occurs when status, size, decoding, or JSON validation fails.

## Changes

- Close every successfully created default HTTP response exactly once.
- Preserve the existing timeout, streaming, status, size, encoding, and JSON
  validation behavior.
- Cover successful parsing and representative rejection paths with
  dependency-free unit tests.
- Document response cleanup in the repository reliability and security notes.
- Extend the scripted baseline so the cleanup contract and this plan cannot be
  removed accidentally.

## Verification

- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
