# Server Port Validation

status: planned

## Problem

Heroku startup converts `PORT` with a bare `int()` call and passes the result
directly to Bottle. Non-numeric, zero, negative, and above-range values can
escape with inconsistent errors or reach the server launcher despite being
invalid TCP listener ports.

## Scope

- Accept decimal listener ports from 1 through 65535.
- Preserve port 5000 when `PORT` is absent and preserve the existing local
  `localhost:8080` path.
- Fail with one stable configuration error before Bottle launch when `PORT` is
  malformed or outside the valid range.
- Add mutation-sensitive tests, static contracts, and synchronized guidance.
- Do not change routes, response behavior, host selection, debug mode,
  dependencies, or provider integrations.

## Implementation Units

### U1: Validate deployment listener ports

Add one private parser in `app.py` and use it only for the Heroku startup path.
The parser should distinguish an absent value from invalid configured values,
normalize valid decimal text to an integer, and enforce the TCP port range.

Test scenarios:

- Missing `PORT` launches Heroku mode on port 5000.
- Ports 1 and 65535 are accepted.
- Non-numeric, empty, zero, negative, and 65536 values raise the same stable
  error before the server launcher is called.

### U2: Preserve the startup contract

Extend `app_tests.py`, `scripts/check-baseline.sh`, and maintained guidance with
the named server-port validation boundary and completed verification evidence.

Test scenarios:

- Focused startup tests and the complete Python/Make gates pass.
- Mutations weakening conversion, bounds, launch ordering, tests, guidance, or
  plan completion are rejected.
- The absolute Makefile path continues to pass outside the checkout.

## Validation

- Run focused startup tests, Ruff formatting/linting, the complete suite,
  compilation, and repository/external `make check` gates.
- Run isolated hostile mutations for parsing, bounds, launch ordering, tests,
  guidance, and plan status.
- Audit the exact diff, generated artifacts, credentials, conflict markers,
  binaries, large files, file modes, and whitespace before committing.

## Risks

- Deployments with invalid `PORT` values will fail earlier with a stable error
  instead of relying on Bottle or socket-layer behavior.
- No live reverse proxy, Heroku runtime, or bound socket is exercised.
- This change is stacked on PR #42, which must remain open and merge first.
