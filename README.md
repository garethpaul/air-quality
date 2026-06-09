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
- Python matching the era of the project

### Setup

```bash
git clone https://github.com/garethpaul/air-quality.git
cd air-quality
python -m pip install -r requirements.txt
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- Run `python app.py` after installing Python dependencies.
- Run `make` or inspect `Makefile` for available targets.

## Testing and Verification

- `make check` - run lint, tests, and Python bytecode compilation
- `make lint` - check formatting and static issues with Ruff
- `make test` - run the dependency-free unittest suite
- `make build` - compile tracked Python files
- `scripts/check-baseline.sh` - verify required files, Make targets,
  completed plan metadata, README notes, and local secret/editor ignore hygiene

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- Detected references to Mapbox. Keep API keys, OAuth credentials, tokens, and account-specific values in local configuration only.
- The `/` route requires finite numeric `lat` and `lng` values in valid coordinate ranges. The `/s` route requires a non-empty text `query` value of 200 characters or fewer.
- The configured `AIRQUALITY_DATA` endpoint must return a JSON object with a `results` list of sensor readings; malformed upstream payloads fail as service errors instead of raw exceptions.
- Upstream sensor readings with non-finite latitude, longitude, or PM2.5 values
  are ignored before distance and AQI calculations.
- Cached air-quality payloads must decode to the expected response shape;
  corrupt entries are ignored and refreshed from the configured data source.
- Default `AIRQUALITY_DATA` HTTP fetches use a bounded timeout; tests verify the
  timeout without live network access.
- Mapbox geocoder responses must return a first feature with a two-value
  finite numeric `center` in valid coordinate bounds; malformed geocoder
  payloads fail with a controlled route error before caching.
- Cached geocode payloads must decode to finite in-range `lat` and `lng`
  values; corrupt entries are ignored and refreshed from Mapbox.

## Security and Privacy Notes

- Review changes touching network requests, sockets, or service endpoints; examples from the scan include air.py, air_tests.py.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include .circleci/config.yml, air.py, air_tests.py, app.py, and 3 more.
- Review changes touching database, model, or persistence code; examples from the scan include CHANGES.md, air.py, docs/plans/2026-06-08-air-quality-engineering-bar.md, geocode.py, and 1 more.
- Review changes touching infrastructure, proxy, cloud, or deployment configuration; examples from the scan include .circleci/config.yml, CHANGES.md, docs/plans/2026-06-08-air-quality-engineering-bar.md.

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
- See `docs/plans/2026-06-09-air-quality-geocode-cache-validation.md` for
  corrupt geocode cache refresh behavior.
- See `docs/plans/2026-06-09-scripted-baseline-check.md` for the scripted
  repository baseline guard.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
