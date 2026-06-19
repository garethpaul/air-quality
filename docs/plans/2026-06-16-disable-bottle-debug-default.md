# Disable Bottle Debug Mode By Default

Status: Completed

## Problem

The documented provider-neutral launch command, `python app.py`, enables
Bottle's debug mode whenever `APP_LOCATION` is not `heroku`. A deployment that
uses the documented process command on another provider can therefore expose
debug behavior even when it follows the reverse-proxy and unprivileged-process
guidance.

## Priorities

1. P0: Keep Bottle debug mode disabled for every built-in launch path.
2. P1: Preserve the existing Heroku and local host/port bindings.
3. P1: Add deterministic startup regressions without opening a socket.
4. P1: Keep deployment and security guidance aligned with the safe default.

## Requirements

1. The local launch path must bind to `localhost:8080` without enabling debug
   mode.
2. The Heroku launch path must continue to bind to `0.0.0.0` and the configured
   `PORT` without enabling debug mode.
3. Tests must patch Bottle startup and assert exact launch arguments without
   starting a server.
4. Maintained deployment and security guidance must state that repository
   launch paths keep Bottle debug mode disabled.
5. Baseline contracts must protect source integration, both startup tests,
   maintained guidance, and completed verification evidence.

## Implementation Units

### U1: Remove The Unsafe Local Default

**File:** `app.py`

Select the existing local or Heroku host and port, then launch Bottle once with
debug mode explicitly disabled.

### U2: Add Startup Regressions

**File:** `app_tests.py`

Patch `app.run` and the process environment to cover local and Heroku launch
arguments. Assert that neither path passes an enabled debug option.

### U3: Protect The Operational Contract

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `DEPLOYMENT.md`,
`SECURITY.md`, `VISION.md`, `CHANGES.md`, and this plan.

Require the safe source call, runtime regressions, maintained guidance,
completed status, and truthful full-gate evidence.

## Test Scenarios

- An empty environment launches on `localhost:8080` without `debug=True`.
- `APP_LOCATION=heroku` and `PORT=4321` launch on `0.0.0.0:4321` without
  `debug=True`.
- Bottle import absence continues to produce the existing startup error.
- Repository and external-directory `make check` remain green.

## Scope Boundaries

- Do not change route behavior, response schemas, cache behavior, data-source
  requests, Mapbox behavior, dependencies, or CI workflows.
- Do not change existing host or port selection.
- Do not add a new runtime configuration flag for debug mode.
- Live deployment, reverse-proxy, Redis, Mapbox, and sensor-feed verification
  remain outside local validation.

## Verification

- Preserve a pre-change reproduction showing the local path passes
  `debug=True` to Bottle.
- Run focused startup tests, the complete test suite, Ruff, and Python
  compilation.
- Run repository and external-directory `make check` with explicit timeouts.
- Reject isolated mutations that restore debug mode, remove either startup
  assertion, weaken source contracts, remove guidance, or falsify plan status.
- Audit the exact diff, generated artifacts, dependency/workflow drift,
  credential-shaped additions, conflict markers, modes, and whitespace.

## Completed Verification

- The pre-change reproduction showed the local launch path passing
  `debug=True` to Bottle.
- The focused test-first run failed only on the unsafe local argument while the
  Heroku and missing-Bottle scenarios passed.
- `test_main_uses_safe_local_server_defaults`,
  `test_main_uses_safe_heroku_server_defaults`, and `test_main_requires_bottle`
  passed, as did all 15 app tests.
- Ruff formatting and lint checks passed, all maintained Python modules
  compiled, and the complete suite passed all 94 tests.
- Repository and external-directory `make check` both passed the complete gate,
  including all 94 tests and the baseline contracts.
- Seven isolated hostile mutations were rejected: enabling debug mode, removing
  the explicit false setting, removing either startup test, removing the
  missing-Bottle guard, removing maintained guidance, and reopening plan
  status.
- A plan-aware review across correctness, security, testing, maintainability,
  reuse, and efficiency found no actionable findings.
- Exact diff, whitespace, mode, conflict-marker, generated-artifact,
  credential-shaped addition, dependency, and workflow audits passed.
- Live deployment, reverse-proxy, Redis, Mapbox, and sensor-feed behavior remain
  outside local validation.
