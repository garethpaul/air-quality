---
title: Air Quality Upstream Results Validation
type: reliability
status: completed
date: 2026-06-09
---

# Air Quality Upstream Results Validation

## Problem Frame

`AirQuality.getData()` trusted the configured `AIRQUALITY_DATA` endpoint to
return a JSON object with a `results` list of sensor readings. If the upstream
payload was missing that key, used a non-list value, or contained malformed
items, the service could raise raw Python exceptions instead of a clear
data-source error.

## Scope Boundaries

- Preserve cached response behavior and the current AQI calculation.
- Preserve the public route contracts for valid coordinate and search requests.
- Do not add live Redis, Mapbox, or HTTP requirements to tests.
- Treat malformed upstream response shape as a service configuration/data
  problem, not as caller input.

## Implementation Units

- Validate that the upstream JSON payload is an object containing a `results`
  list before selecting the nearest reading.
- Ignore malformed non-object readings when scanning sensor candidates.
- Add dependency-free unit coverage for missing `results`, non-list `results`,
  and malformed readings mixed with valid readings.
- Record the behavior in `CHANGES.md`, `README.md`, and `VISION.md`.

## Verification

- `make check`
- `make lint`
- `make test`
- `make build`
- `git diff --check`
