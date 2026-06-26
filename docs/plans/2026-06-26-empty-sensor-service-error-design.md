# Empty Sensor Dataset Service Error Design

Status: Completed

## Evidence

- `AirQuality.getData()` validates the caller coordinates before fetching data.
- A missing or non-list `results` member already raises `RuntimeError` and maps
  to the stable HTTP 503 service-error response.
- An empty `results` list or a list containing no valid PM2.5 reading reaches
  `nearest_reading()`, which raises `ValueError`; both `/` and `/s` interpret
  every `ValueError` as HTTP 400 `invalid request`.
- RFC 9110 defines 400 around perceived client errors. A valid coordinate or
  search request cannot repair an empty upstream sensor dataset.

## Constraints

- Preserve 400 responses for invalid caller coordinates and search queries.
- Preserve filtering of malformed, negative, non-finite, boolean, overflowing,
  and out-of-range sensor readings.
- Do not expose provider payload details.
- Preserve the existing stable 503 `service unavailable` route response.
- Do not change the successful response schema or cache behavior.

## Considered Approaches

### Catch `ValueError` in the routes and return 503

Rejected because route-level `ValueError` also represents invalid client input;
converting all of it would misclassify real bad requests.

### Introduce a new custom exception hierarchy

Correct but unnecessary for one established service-failure boundary. It adds
public surface and complexity without changing route behavior.

### Raise the existing service `RuntimeError` when no reading survives

Recommended. The data layer knows the failure is upstream-data availability,
all existing routes already contain `RuntimeError` as a generic 503, and caller
validation remains unchanged.

## Decision

Change only the exhausted-dataset branch in `nearest_reading()` to raise a
stable unchained `RuntimeError`. Cover an exactly empty list and an all-invalid
list independently, then bind the behavior into the portable baseline and
maintenance documentation.

## Verification

- Red-first focused tests for empty and all-invalid result lists.
- Existing invalid-coordinate route tests must remain green.
- Root and external-directory `make check` on the supported isolated runtime.
- Mutation checks for the exception type, both regressions, docs, and plan.
