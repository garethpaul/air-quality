# Disable Bottle Debug Mode By Default

Status: In Progress

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

Use Bottle's production-safe default for the local launch path while preserving
its existing host and port.

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

Pending implementation and validation.
