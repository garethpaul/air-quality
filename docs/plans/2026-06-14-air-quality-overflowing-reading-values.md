---
title: Air Quality Overflowing Reading Values
type: reliability
status: completed
date: 2026-06-14
---

# Air Quality Overflowing Reading Values

## Status: Completed

## Problem

JSON permits integers larger than Python's finite float range. Converting an
oversized sensor latitude, longitude, or PM2.5 value raises `OverflowError`,
bypassing the existing malformed-reading guard and aborting selection before a
later valid reading can be used.

## Requirements

1. Ignore sensor fields that overflow during numeric conversion.
2. Continue selecting a later valid reading without changing valid payloads,
   distance calculation, AQI scoring, or cache behavior.
3. Cover overflow independently in latitude, longitude, and PM2.5 values.
4. Add mutation-sensitive source, test, documentation, and plan contracts.

## Scope Boundaries

- Do not change accepted coordinate or PM2.5 ranges.
- Do not change route schemas, cache keys, provider behavior, or HTTP policy.
- Do not merge or close any pull request without explicit authorization.

## Verification Plan

- Run the focused overflow regression and the full Python suite.
- Run Ruff formatting and lint, bytecode compilation, dependency audit, and
  root plus external-working-directory `make check`.
- Reject isolated mutations that remove the exception guard, regression test,
  or completed-plan evidence.
- Audit the exact diff, generated artifacts, conflict markers, whitespace, and
  credential-shaped additions before commit and push.

## Verification Results

Completed on 2026-06-14:

- The focused overflow regression passed for latitude, longitude, and PM2.5,
  and failed with `OverflowError` when the new exception guard was removed.
- `python run_tests.py` passed all 64 tests.
- `python -m ruff format --check .`, `python -m ruff check .`, and Python
  bytecode compilation passed.
- `python -m pip_audit -r requirements.txt -r requirements-dev.txt` reported
  no known vulnerabilities.
- Root and external-working-directory `make check` passed.
- Three isolated hostile mutations were rejected across the exception guard,
  regression test, and completed-plan evidence.
