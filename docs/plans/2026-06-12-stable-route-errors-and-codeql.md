# Stable Route Errors and CodeQL

Status: Completed

## Problem

The `/` and `/s` routes serialize caught exception messages into JSON. Those
messages currently describe validation and provider failures, but exception
text is an internal diagnostic channel and future dependency errors could
expose stack-trace or configuration details. The current remediation PR also
lacks CodeQL analysis, so four default-branch `py/stack-trace-exposure` alerts
cannot be verified as absent from its head.

## Plan

1. Return stable public messages for invalid requests and unavailable upstream
   services without deriving response content from caught exceptions.
2. Add route-level tests that inject secret-like exception details and prove
   neither route returns them.
3. Add immutable-pinned actions and Python CodeQL analysis with read-only
   contents, security-event upload permission, fixed Ubuntu, bounded jobs, and
   canonical push, pull-request, schedule, and manual triggers.
4. Extend the portable checker to reject workflow removal, mutable actions,
   permission or trigger drift, and loss of buildless actions/Python analysis.
5. Run focused tests, the full local and external-directory gates, hostile
   mutations, and exact-head hosted Check and CodeQL verification.

## Verification

- Focused route tests first failed on all four exception paths because the
  internal messages were returned, then passed after stable public errors were
  implemented.
- `make check` passed Ruff, all 33 tests, Python bytecode compilation, and the
  portable baseline checker; an external-working-directory invocation passed
  the same complete gate.
- Ruby parsed both workflow files, and `git diff --check` passed.
- Four isolated mutations were rejected for public-message drift, restored
  exception serialization, a mutable CodeQL action, and missing
  `security-events: write` permission.
- Exact-head hosted Check and CodeQL verification remains required before the
  pull request is considered ready.
