# Air Quality Geocoder Transport Errors

status: completed

## Context

`GeoCode.getLatLng` calls the external Mapbox client outside an exception
boundary. Connection failures and response-decoding errors therefore escape as
their original exception types and can include provider, credential, or
transport details. The Bottle routes only translate `ValueError` and
`RuntimeError`, so these failures bypass the stable service-unavailable
response contract.

The issue is reproducible offline with a fake geocoder whose `forward` method
raises `ConnectionError`: the raw exception and its message escape unchanged.

## Planned Scope

- Normalize exceptions raised while requesting or decoding a geocoder response
  to one stable `RuntimeError` without exception chaining.
- Keep successful-but-malformed payload validation as `ValueError` so route
  clients continue to receive the existing invalid-request response.
- Add focused offline tests for request failure, JSON-decoding failure, secret
  redaction, call order, and malformed-payload preservation.
- Extend the baseline checker and project documentation with the completed
  geocoder transport-error contract.

## Out Of Scope

- Live Mapbox requests, tokens, or deployment credentials.
- Retry, backoff, caching, query, or coordinate behavior changes.
- Changes to AIRQUALITY_DATA, Redis, route payloads, or status codes.

## Work Completed

- Added one unchained generic exception boundary around Mapbox client creation,
  request dispatch, and response JSON decoding.
- Kept feature and coordinate shape parsing outside that boundary so successful
  malformed responses continue to raise `ValueError`.
- Added offline request and decoding regressions with dispatch-order, message,
  cause, and secret-redaction assertions.
- Extended the portable baseline and project guidance with the completed
  geocoder transport-error contract.

## Verification Completed

- `make lint`
- `make test`
- `make build`
- `make check`
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest geocode_tests -v` (11 tests)
- `test_geocoder_request_failure_is_normalized_without_detail`
- `test_geocoder_json_failure_is_normalized_without_detail`
- Full offline behavioral suite (59 tests)
- Mutations for a removed exception boundary, leaked exception chaining,
  over-broad payload normalization, stale plan status, and missing evidence
  were rejected.
- External-working-directory `make check`
- `git diff --check`
- Intended-path secret and generated-artifact inspection passed
