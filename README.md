# air-quality

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/air-quality` is a Python web API or service project. Python Bottle API for Getting Air Quality based on Lat/Lng or Query String

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `master` branch. The project language mix found during review was: Python (7).

## Repository Contents

- `README.md` - project overview and local usage notes
- `requirements.txt` - Python dependency or packaging metadata
- `.circleci` - source or example code
- `app.py`
- `docs` - source or example code
- `Makefile` - local build or utility targets
- `Procfile`
- `pyproject.toml` - Python dependency or packaging metadata
- `SECURITY.md` - security reporting and disclosure guidance
- `scripts/check-baseline.sh` - repository baseline and local metadata hygiene guard
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: .circleci, docs
- Dependency and build manifests: Makefile, Procfile, pyproject.toml, requirements.txt
- Entry points or build surfaces: app.py, Makefile, scripts/check-baseline.sh
- Test-looking files: air_tests.py, geocode_tests.py, run_tests.py, test_helpers.py

## Getting Started

### Prerequisites

- Git
- Python 3.12 or 3.14; `.python-version` selects 3.14 by default

### Setup

```bash
git clone https://github.com/garethpaul/air-quality.git
cd air-quality
python -m pip install -r requirements.txt
```

The setup commands above are derived from repository files. GitHub Actions and
CircleCI validate the locked dependency set on Python 3.12 and 3.14. GitHub Actions uses credential-free checkout and runs `make check` from outside the repository directory.

## Running or Using the Project

- Run `python app.py` after installing Python dependencies.
- Run `make` or inspect `Makefile` for available targets.

## Testing and Verification

- `make check` - run lint, tests, and Python bytecode compilation
- `make lint` - check formatting and static issues with Ruff
- `make test` - run the dependency-free unittest suite
- AQI tests enforce the EPA PM2.5 breakpoints effective May 6, 2024, accept
  nonnegative sensor concentrations, and reject out-of-range sensor locations.
- `make build` - compile tracked Python files
- `scripts/check-baseline.sh` - verify required files, Make targets,
  completed plan metadata, CI contracts, README notes, and local secret/editor
  ignore hygiene
- Route failures return stable JSON messages instead of exposing caught
  exception details; hosted CodeQL analyzes actions and Python on every push
  and pull request and on a weekly schedule.
- The default `AIRQUALITY_DATA` fetch streams at most 1 MiB and rejects an
  oversized chunk before extending the retained response buffer, rejects malformed
  JSON, missing or non-JSON `application/json` or `application/*+json`
  response media types, unsupported response encodings, and supplied values
  that violate non-negative Content-Length syntax (ASCII decimal digits only),
  plus HTTP failures,
  keeps the existing
  10-second timeout, and closes the streamed response after both successful and
  failed reads.
- Requests transport failures at connection, status, and streamed-read stages
  become stable service errors without exposing provider exception details.
- Geocoder transport failures during Mapbox dispatch or JSON decoding become
  stable service errors without exposing provider or credential details;
  successful malformed payloads remain invalid requests.
- The default client enforces an HTTPS-only data source before requesting,
  before following redirects, and on the final response URL without exposing
  endpoint URLs. Literal and DNS-resolved IPv4 and IPv6 targets must all be
  globally reachable unicast addresses; private, loopback, link-local,
  multicast, shared, reserved, unresolved, and mixed public/private results
  fail closed.
- Cache command failures become stable service errors before Redis URLs or
  dependency exception details can reach public route responses.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- Detected references to Mapbox. Keep API keys, OAuth credentials, tokens, and account-specific values in local configuration only.
- The `/` route requires finite numeric `lat` and `lng` values in valid coordinate ranges. The `/s` route requires a non-empty text `query` value of 200 characters or fewer.
- The configured `AIRQUALITY_DATA` endpoint must use HTTPS and return a JSON
  object with a `results` list of sensor readings; redirects must also remain
  HTTPS, every resolved address must be globally reachable, and malformed
  upstream payloads fail as service errors.
- Non-finite readings and overflowing upstream sensor values for latitude,
  longitude, or PM2.5 are ignored before distance and AQI calculations.
- PM2.5 scores use EPA's current 0.0-9.0 Good, 9.1-35.4 Moderate,
  35.5-55.4 Unhealthy for Sensitive Groups, 55.5-125.4 Unhealthy,
  125.5-225.4 Very Unhealthy, and 225.5+ Hazardous breakpoints. Scores above
  the published 325.4 µg/m³ AQI-500 boundary are capped at 500.
- Cached air-quality payloads must decode to the expected response shape;
  corrupt entries are ignored and refreshed from the configured data source.
- Overflowing cached numeric values are ignored and refreshed instead of
  turning corrupt Redis entries into route failures.
- Cached AQI guidance is accepted only when its 0-500 score, category, and
  caution match the canonical response.
- Cached air-quality hits return only the public `category`, `caution`, and
  finite non-negative integer `score` fields.
- Default `AIRQUALITY_DATA` HTTP fetches use a bounded timeout; tests verify the
  timeout without live network access.
- Mapbox geocoder responses must return a first feature with a two-value
  finite numeric `center` in valid coordinate bounds; malformed geocoder
  payloads fail with a controlled route error before caching.
- Overflowing Mapbox center values are rejected before coordinate caching.
- Cached geocode payloads must decode to finite in-range `lat` and `lng`
  values; corrupt entries are ignored and refreshed from Mapbox.
- Cache command failures stop request processing instead of bypassing Redis or
  exposing dependency details; the service does not retry cache operations.

## Security and Privacy Notes

- Review changes touching network requests, sockets, or service endpoints; examples from the scan include air.py, air_tests.py.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include .circleci/config.yml, air.py, air_tests.py, app.py, and 3 more.
- Review changes touching database, model, or persistence code; examples from the scan include CHANGES.md, air.py, docs/plans/2026-06-08-air-quality-engineering-bar.md, geocode.py, and 1 more.
- Review changes touching infrastructure, proxy, cloud, or deployment configuration; examples from the scan include .circleci/config.yml, CHANGES.md, docs/plans/2026-06-08-air-quality-engineering-bar.md.

## Deployment

Use [`DEPLOYMENT.md`](DEPLOYMENT.md) for the provider-neutral small-instance deployment runbook.
It defines the required runtime variables, TLS reverse-proxy boundary,
fresh-checkout preflight, bounded health probe, secret handling, and rollback
steps without treating repository checks as live infrastructure verification.

The application must run as an unprivileged service account, and its Bottle
listener must be reachable only by the reverse proxy or private network.

## Maintenance Notes

- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `docs/plans/2026-06-09-air-quality-geocode-shape-validation.md` for the
  current geocoder response-shape validation plan.
- See `docs/plans/2026-06-09-air-quality-http-timeout.md` for default upstream
  HTTP timeout coverage.
- See `docs/plans/2026-06-09-air-quality-search-query-validation.md` for the
  `/s` query validation contract.
- See `docs/plans/2026-06-09-air-quality-nonfinite-sensor-values.md` for
  upstream sensor finite-value guard coverage.
- See `docs/plans/2026-06-09-air-quality-geocode-coordinate-validation.md` for
  geocoder coordinate finite/range validation.
- See `docs/plans/2026-06-09-air-quality-cache-payload-validation.md` for
  corrupt cache refresh behavior.
- See `docs/plans/2026-06-09-air-quality-cache-score-validation.md` for cached
  response field type and score validation.
- See `docs/plans/2026-06-09-air-quality-geocode-cache-validation.md` for
  corrupt geocode cache refresh behavior.
- See `docs/plans/2026-06-09-scripted-baseline-check.md` for the scripted
  repository baseline guard.
- See `docs/plans/2026-06-10-python-runtime-modernization.md` for the current
  Python runtime, dependency pins, and CI matrix.
- See `docs/plans/2026-06-10-air-quality-upstream-size-limit.md` for bounded
  sensor-data streaming and root-independent verification.
- See `docs/plans/2026-06-10-current-epa-pm25-breakpoints.md` for the current
  PM2.5 AQI calculation and cache-version contract.
- See `docs/plans/2026-06-12-air-quality-response-cleanup.md` for deterministic
  upstream response cleanup.
- See `docs/plans/2026-06-13-air-quality-upstream-transport-errors.md` for the
  normalized Requests transport-failure boundary.
- See `docs/plans/2026-06-13-air-quality-cache-transport-errors.md` for the
  normalized Redis read/write failure boundary.
- See `docs/plans/2026-06-13-air-quality-geocoder-transport-errors.md` for the
  normalized Mapbox request and JSON-decoding boundary.
- See `docs/plans/2026-06-13-air-quality-https-data-source.md` for direct and
  post-redirect HTTPS transport enforcement.
- See `docs/plans/2026-06-13-air-quality-public-data-addresses.md` for the
  public-address policy and its DNS-rebinding boundary.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
