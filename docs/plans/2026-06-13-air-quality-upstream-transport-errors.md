# Air Quality Upstream Transport Errors

Status: Completed

## Context

The default `AIRQUALITY_DATA` client bounds and closes streamed responses, but
ordinary Requests failures are not translated into the service's existing
`RuntimeError` provider boundary. DNS failures, refused connections, timeouts,
HTTP status failures, and streamed read failures can therefore bypass the
stable JSON 503 route contract and reach Bottle as unexpected exceptions.

Requests documents that its explicit transport and HTTP exceptions inherit
from `requests.exceptions.RequestException`.

## Requirements

- **R1:** Convert `RequestException` raised before a response exists into a
  stable local `RuntimeError` with no chained provider details.
- **R2:** Convert `RequestException` raised by status validation or streamed
  body reads into the same stable local error.
- **R3:** Close every successfully created response exactly once on success and
  on normalized status or streaming failures.
- **R4:** Preserve timeout, streaming, response-size, encoding, JSON, and
  payload-shape behavior.
- **R5:** Keep `/` and `/s` responses on the established generic JSON 503
  contract without exposing URLs, status text, or dependency exception data.
- **R6:** Add the transport boundary and completed verification to the portable
  baseline and repository reliability documentation.

## Implementation Units

### U1: Normalize Requests Failures

**Files:** `air.py`

Catch the Requests exception base around response creation and around work that
uses a created response. Raise one generic `RuntimeError` without exception
chaining. Keep response cleanup in the existing `finally` path so only created
responses are closed.

### U2: Exercise Connection, Status, And Stream Failures

**Files:** `air_tests.py`

Use no-network fakes to prove connection failures are normalized without a
response, while status and streamed-read failures are normalized and close the
created response once. Assert provider-controlled exception text is absent
from the normalized error.

### U3: Preserve The Durable Contract

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `CHANGES.md`,
`docs/plans/2026-06-13-air-quality-upstream-transport-errors.md`

Require the Requests exception boundary, generic local error, regression test
names, completed plan, and reliability guidance. Record actual focused, full,
external-directory, mutation, and hosted verification evidence after execution.

## Test Scenarios

- A connection error raised by `requests.get` becomes a generic
  `RuntimeError` and does not attempt response cleanup.
- An HTTP error raised by `raise_for_status` becomes the same generic error and
  closes the response exactly once.
- A Requests error raised while iterating body chunks becomes the same generic
  error and closes the response exactly once.
- Existing success, size, malformed length, decoding, JSON, cache, AQI, and
  route tests remain green.
- Hostile mutations removing either normalization boundary, restoring exception
  chaining, or removing cleanup/test/plan contracts fail verification.

## Scope Boundaries

- Do not retry requests, change timeout values, alter configured endpoints, or
  weaken response-size and payload validation.
- Do not add provider details to public responses or logs.
- Do not change Redis or Mapbox failure handling in this task.

## Verification

- Three focused default-client tests passed for connection, HTTP-status, and
  streamed-read failures, including generic messages, suppressed chaining, and
  exact cleanup behavior.
- Local and external-directory `make check` passed Ruff formatting/lint, all 36
  unit tests, Python compilation, and the portable baseline checker.
- Seven hostile mutations were rejected: removing either normalization
  boundary, restoring exception chaining, removing response cleanup, removing
  streamed-read regression coverage, removing security guidance, and removing
  the canonical plan.
- GitHub Actions and CircleCI YAML parsing, secret-pattern scanning, and
  `git diff --check` passed.
- Live Redis, Mapbox, and `AIRQUALITY_DATA` integrations were not exercised
  without deployment credentials; all new transport tests are no-network.

## Source

- Requests Quickstart, Errors and Exceptions:
  https://requests.readthedocs.io/en/latest/user/quickstart/#errors-and-exceptions
