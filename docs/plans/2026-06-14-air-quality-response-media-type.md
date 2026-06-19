---
title: Air Quality Response Media Type Validation
type: security
status: completed
date: 2026-06-14
---

# Air Quality Response Media Type Validation

## Status: Completed

## Problem

The default `AIRQUALITY_DATA` client bounds and decodes the streamed body as
JSON, but it does not verify the upstream `Content-Type`. A text or HTML
response can therefore cross the provider boundary whenever its bytes happen
to parse as JSON. Media-type validation should fail before body streaming while
retaining deterministic response cleanup and stable local errors.

## Requirements

1. Require exactly one final-response media type before `Content-Length`
   validation or stream iteration.
2. Accept `application/json` and valid `application/*+json` structured syntax
   suffixes case-insensitively, with optional parameters.
3. Reject missing, non-string, malformed, comma-joined, non-application, and
   non-JSON media types with one generic local error.
4. Close every created response on media-type rejection and do not expose
   provider headers or body content.
5. Preserve HTTPS/public-address checks, redirect policy, status handling,
   size limits, response encoding, JSON parsing, caching, and route behavior.
6. Add mutation-sensitive source, ordering, test, documentation, and completed
   plan contracts.

## Verification Plan

- Add focused tests for accepted JSON forms and rejected missing, malformed,
  spoofed, and non-JSON media types, including no-stream and close assertions.
- Run the focused suite, all Python tests, lint/format/build/audit gates, root
  and external-working-directory `make check`, and isolated hostile mutations.
- Audit the exact diff, generated artifacts, whitespace, conflict markers, and
  credential-shaped additions before commit and push.

## Scope Boundaries

- Do not add content sniffing, MIME libraries, retries, or provider-specific
  exceptions.
- Do not change valid JSON payload semantics or route response schemas.
- Do not merge or close any pull request without explicit authorization.

## Verification Results

Completed on 2026-06-14:

- Focused accepted/rejected media-type tests passed and proved rejected
  responses are closed before `iter_content` is entered.
- `python run_tests.py` passed all 63 tests.
- `python -m ruff format --check .`, `python -m ruff check .`, and Python
  bytecode compilation passed.
- `python -m pip_audit -r requirements.txt -r requirements-dev.txt` reported
  no known vulnerabilities.
- Root and external-working-directory `make check` passed after plan
  completion.
- Six isolated hostile mutations were rejected across validation invocation,
  media-type policy, ordering, no-stream cleanup evidence, documentation, and
  completed-plan status.
