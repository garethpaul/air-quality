# Python Runtime Modernization

Status: completed

## Goal

Move the service from an unsupported Python 3.7 dependency graph to current,
reproducible direct dependencies and verify behavior on maintained Python
runtimes.

## Changes

- Replace `runtime.txt` with `.python-version` and select Python 3.14 for local
  and hosted runtime discovery.
- Test the locked application and development dependencies on Python 3.12 and
  3.14 in CircleCI, with runtime-specific dependency caches.
- Upgrade Bottle, Requests, Mapbox, Redis, and Ruff to current direct pins.
- Remove direct boto3, botocore, and s3transfer pins because they are Mapbox
  transitive dependencies rather than application imports.
- Reformat one test expression for the current Ruff formatter.

## Verification

- `python -m pip install -r requirements.txt -r requirements-dev.txt`
- `make check`
- Python 3.14: 24 unit tests, Ruff checks, compilation, and baseline contracts
  pass.
- OSV reports no known vulnerabilities for the five direct application and
  development pins.
- `git diff --check`
