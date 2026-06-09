# Scripted Baseline Check

status: completed

## Context

The repository had Ruff, unittest, compile, and Makefile gates, but it did not
have a scriptable repository baseline guard for required files, Make target
contracts, completed plan metadata, README notes, or local secret/editor
metadata hygiene.

## Objectives

- Keep `make check` as the root verification command.
- Add a dependency-light shell baseline check for repository contracts.
- Verify completed maintenance plans without requiring live Redis, Mapbox, or
  air-quality feed dependencies.
- Keep local secrets and editor metadata out of git.

## Work Completed

- Added `scripts/check-baseline.sh`.
- Wired the script into `make check` after lint, test, and build.
- Added local secret and editor metadata ignore coverage.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `PYTHONDONTWRITEBYTECODE=1 python run_tests.py`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Move compile output to a temporary cache if the project later wants a
  bytecode-free working tree after `make build`.
