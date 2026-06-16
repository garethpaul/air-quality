# Search Query Control-Character Guard

status: in_progress

## Context

`parse_search_query` trims and length-limits search text but accepts embedded
Unicode control characters. Values containing NUL, newlines, or other `Cc`
characters are then forwarded to the geocoder and included in Redis cache
keys, creating ambiguous downstream input and cache identities.

## Priority

Close the public search-input boundary before making broader geocoder changes.
The route already treats malformed input as an invalid request, so this can be
fixed without changing response shapes or upstream failure classification.

## Requirements

- R1. Reject any search query containing a Unicode `Cc` control character after
  the existing trim step.
- R2. Preserve ordinary internationalized visible text, spaces, punctuation,
  and the existing 200-character limit.
- R3. Rejected input must not construct or call the geocoder.
- R4. The `/s` route must retain its generic `400 invalid request` response for
  this validation failure.
- R5. Focused tests, the maintained baseline, documentation, and completed plan
  evidence must be mutation-sensitive.
- R6. Do not expose query content in errors or add logging, analytics,
  networking, dependencies, or cache-format changes.

## Implementation Units

### U1. Shared query boundary

**File:** `app.py`

Classify each trimmed character using Python's Unicode database and reject only
the control category. Keep required, type, trim, and length validation ordering
unchanged.

### U2. Focused and maintained tests

**Files:** `app_tests.py`, `scripts/check-baseline.py`

Cover NUL, newline, and C1 controls; prove the geocoder is not constructed;
preserve an internationalized visible query; and require the source/test
contract from the portable gate.

### U3. Maintained guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

Record the input boundary without including rejected query values in messages
or changing the local cache and upstream transport model.

## Test Scenarios

- Embedded `U+0000`, newline, and `U+0085` values are rejected.
- A visible internationalized query remains accepted after trimming.
- A rejected query never constructs the geocoder factory.
- The search route converts the rejection to its existing generic 400 payload.
- Removing classification, tests, guidance, or completed evidence fails the
  portable gate.

## Scope Boundaries

- Do not introduce an ASCII allowlist or reject non-control Unicode text.
- Do not change query cache versioning, geocoder response parsing, route JSON,
  request timeouts, transport validation, or dependencies.
- Do not perform live Mapbox, Redis, sensor, or deployment requests.

## Verification

- Run focused search tests, the full Python suite, Ruff format/lint, Python
  compilation, all Make aliases, and the absolute Makefile externally.
- Reject isolated mutations for control classification, geocoder short-circuit,
  internationalized-text preservation, test registration, guidance, and plan
  status.
- Audit the exact diff, generated artifacts, changed lines for credentials,
  dependency/workflow drift, and whitespace before commit.

## Verification Completed

Pending implementation and validation.
