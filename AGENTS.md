# AGENTS.md

## Repository purpose

`garethpaul/air-quality` is a Python web API or service project. Python Bottle API for Getting Air Quality based on Lat/Lng or Query String

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `pyproject.toml` - Python tooling configuration
- `requirements.txt` - Python runtime dependencies
- `requirements-dev.txt` - Python development dependencies

## Development commands

- Supported runtime: Python 3.12
- Install dependencies: `python3 -m pip install -r requirements-dev.txt`; `python3 -m pip install -r requirements.txt`
- Full baseline: `make check`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: Python (7).
- Python formatting/linting uses Ruff settings from `pyproject.toml`.
- Prefer dependency-free tests or stdlib checks when legacy packages are unavailable.

## Testing guidance

- Test-related files detected: `air_tests.py`, `app_tests.py`, `geocode_tests.py`, `run_tests.py`, `test_helpers.py`
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- Detected references to Mapbox. Keep API keys, OAuth credentials, tokens, and account-specific values in local configuration only.
- The `/` route requires finite numeric `lat` and `lng` values in valid coordinate ranges. The `/s` route requires a non-empty text `query` value of 200 characters or fewer.
- The configured `AIRQUALITY_DATA` endpoint must return a JSON object with a `results` list of sensor readings; malformed upstream payloads fail as service errors instead of raw exceptions.
- Non-finite readings and overflowing upstream sensor values for latitude, longitude, or PM2.5 are ignored before distance and AQI calculations.
- Boolean upstream sensor values are ignored before distance and AQI calculations.
- Boolean scoring helper inputs are rejected before numeric conversion.
- Non-finite scoring helper inputs are rejected before interpolation or
  category construction.
- Zero-width AQI interpolation ranges are rejected before division.
- Descending AQI interpolation ranges are rejected before division.
- Negative AQI scores are classified as Out of Range instead of Good.
- Near-antipodal sensor distances clamp floating-point drift to the haversine
  domain; preserve the focused regression when changing location math.
- Direct AirQuality construction rejects boolean, nonnumeric, non-finite, and out-of-range coordinates.
- Route coordinate validation rejects boolean and overflowing numeric values before AirQuality construction.
- Accepted signed-zero coordinates normalize to positive zero so equivalent requests share one cache key.
- Mapbox and cached geocoder signed-zero coordinates normalize to positive zero
  before use or cache serialization.
- Valid cached geocoder numeric strings are rewritten as canonical JSON numbers
  after validation; preserve the no-rewrite path for canonical numeric hits.
- Overflowing Mapbox center values are rejected before coordinate caching.
- Boolean Mapbox and cached geocoder coordinates are rejected instead of being
  normalized to numeric locations.
- Cached air-quality payloads must decode to the expected response shape; corrupt entries are ignored and refreshed from the configured data source.
- Overflowing cached numeric values are ignored and refreshed rather than
  surfacing conversion failures from Redis data.
- Cached AQI guidance is accepted only when its 0-500 score, category, and
  caution match the canonical response.
- Upstream sensor responses must declare `application/json` or a valid
  `application/*+json` media type before body streaming.
- Default `AIRQUALITY_DATA` HTTP fetches use a bounded timeout; tests verify the timeout without live network access.
- Checked-in binary libraries are present; do not replace them without documenting toolchain and checksums.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
