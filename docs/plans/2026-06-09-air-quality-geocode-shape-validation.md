---
title: Air Quality Geocode Shape Validation
type: reliability
status: completed
date: 2026-06-09
---

# Air Quality Geocode Shape Validation

## Problem Frame

`GeoCode.getLatLng()` already handles an empty Mapbox `features` list, but it
still assumes the first feature is an object with a two-value numeric `center`
array. Malformed geocoder payloads can therefore raise raw indexing,
conversion, or key errors instead of a clear route-level validation error.

## Scope Boundaries

- Preserve cache behavior and the existing first-feature selection.
- Do not add live Mapbox, Redis, or HTTP requirements to tests.
- Treat malformed geocoder payload shape as a controlled `ValueError`.

## Implementation Units

- Add a small parser for the first geocoder center.
- Validate that `features` is a list, the first feature is a mapping, `center`
  contains longitude and latitude, and both values are numeric.
- Add dependency-free tests for malformed feature payloads and valid string
  coordinate values.
- Document the behavior in `README.md`, `VISION.md`, and `CHANGES.md`.

## Verification

- `make check`
- `make lint`
- `make test`
- `make build`
- `git diff --check`
