#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"
MAKEFILE="$ROOT_DIR/Makefile"
GITIGNORE="$ROOT_DIR/.gitignore"
DOCS_PLANS="$ROOT_DIR/docs/plans"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  ".circleci/config.yml" \
  ".github/workflows/check.yml" \
  ".github/workflows/codeql.yml" \
  ".python-version" \
  ".gitignore" \
  "CHANGES.md" \
  "Makefile" \
  "Procfile" \
  "README.md" \
  "SECURITY.md" \
  "VISION.md" \
  "air.py" \
  "air_tests.py" \
  "app.py" \
  "app_tests.py" \
  "geocode.py" \
  "geocode_tests.py" \
  "pyproject.toml" \
  "requirements.txt" \
  "requirements-dev.txt" \
  "run_tests.py" \
  "test_helpers.py" \
  "docs/plans/2026-06-08-air-quality-engineering-bar.md" \
  "docs/plans/2026-06-09-air-quality-geocode-cache-validation.md" \
  "docs/plans/2026-06-09-scripted-baseline-check.md" \
  "docs/plans/2026-06-10-python-runtime-modernization.md" \
  "docs/plans/2026-06-10-air-quality-upstream-size-limit.md" \
  "docs/plans/2026-06-12-air-quality-response-cleanup.md" \
  "docs/plans/2026-06-12-stable-route-errors-and-codeql.md" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

if ! grep -Fq "response.close()" "$ROOT_DIR/air.py"; then
  printf '%s\n' "Default upstream responses must be closed." >&2
  exit 1
fi

for route_error_contract in \
  'INVALID_REQUEST_MESSAGE = "invalid request"' \
  'SERVICE_UNAVAILABLE_MESSAGE = "service unavailable"'; do
  if ! grep -Fq "$route_error_contract" "$ROOT_DIR/app.py"; then
    printf '%s\n' "Routes must keep stable public error contract: $route_error_contract" >&2
    exit 1
  fi
done

if grep -Eq 'json_error\([[:space:]]*str\(' "$ROOT_DIR/app.py"; then
  printf '%s\n' "Routes must not serialize exception details into JSON errors." >&2
  exit 1
fi

for route_test_contract in \
  'test_show_data_does_not_expose_exception_details' \
  'test_search_does_not_expose_exception_details' \
  'AIRQUALITY_DATA=https://secret' \
  'REDIS_URL=redis://secret'; do
  if ! grep -Fq "$route_test_contract" "$ROOT_DIR/app_tests.py"; then
    printf '%s\n' "Route error regression tests must keep contract: $route_test_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "scripts/check-baseline.sh" "$MAKEFILE"; then
  printf '%s\n' "Makefile must run scripts/check-baseline.sh from make check." >&2
  exit 1
fi

if ! grep -Fq 'ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))' "$MAKEFILE"; then
  printf '%s\n' "Makefile must resolve the repository root." >&2
  exit 1
fi

for target in "lint:" "test:" "build:" "check:"; do
  if ! grep -Fq "$target" "$MAKEFILE"; then
    printf '%s\n' "Makefile must expose the $target gate." >&2
    exit 1
  fi
done

for make_contract in \
  "python -m ruff format --check ." \
  "python -m ruff check ." \
  "python run_tests.py" \
  "python -m compileall -q"; do
  if ! grep -Fq "$make_contract" "$MAKEFILE"; then
    printf '%s\n' "Makefile must keep contract: $make_contract" >&2
    exit 1
  fi
done

for documented in \
  "AIRQUALITY_DATA" \
  "Mapbox" \
  "make check" \
  "make lint" \
  "make test" \
  "make build" \
  "scripts/check-baseline.sh"; do
  if ! grep -Fq "$documented" "$README"; then
    printf '%s\n' "README must document $documented." >&2
    exit 1
  fi
done

for ignored in "__pycache__/" "*.py[cod]" ".venv/" "venv/" ".ruff_cache/" ".env" ".env.*" ".vscode/" ".idea/" "*.iml"; do
  if ! grep -Fq "$ignored" "$GITIGNORE"; then
    printf '%s\n' ".gitignore must include $ignored" >&2
    exit 1
  fi
done

tracked_local=$(git -C "$ROOT_DIR" ls-files '.env' '.env.*' '.idea' '.vscode' '*.iml' || true)
if [ -n "$tracked_local" ]; then
  printf '%s\n%s\n' "Local secrets or editor metadata must not be tracked:" "$tracked_local" >&2
  exit 1
fi

found_plan=0
for plan in "$DOCS_PLANS"/*.md; do
  [ -e "$plan" ] || continue
  found_plan=1
  if ! grep -iq "status" "$plan" || ! grep -iq "completed" "$plan"; then
    printf '%s\n' "$plan must record completed status." >&2
    exit 1
  fi
  if ! grep -iq "verification" "$plan"; then
    printf '%s\n' "$plan must document verification." >&2
    exit 1
  fi
done

if [ "$found_plan" -eq 0 ]; then
  printf '%s\n' "docs/plans must contain completed markdown plans." >&2
  exit 1
fi

for plan in \
  "$DOCS_PLANS/2026-06-09-air-quality-geocode-cache-validation.md" \
  "$DOCS_PLANS/2026-06-09-scripted-baseline-check.md" \
  "$DOCS_PLANS/2026-06-10-python-runtime-modernization.md"; do
  if ! grep -Fq "make check" "$plan"; then
    printf '%s\n' "$plan must document make check verification." >&2
    exit 1
  fi
done

if [ "$(cat "$ROOT_DIR/.python-version")" != "3.14" ]; then
  printf '%s\n' ".python-version must select Python 3.14." >&2
  exit 1
fi

if [ -e "$ROOT_DIR/runtime.txt" ]; then
  printf '%s\n' "Deprecated runtime.txt must remain removed in favor of .python-version." >&2
  exit 1
fi

for requirement in \
  'bottle==0.13.4' \
  'requests==2.34.2' \
  'mapbox==0.18.1' \
  'redis==8.0.0'; do
  if ! grep -Fxq "$requirement" "$ROOT_DIR/requirements.txt"; then
    printf '%s\n' "requirements.txt must keep exact direct pin: $requirement" >&2
    exit 1
  fi
done

if ! grep -Fxq 'ruff==0.15.15' "$ROOT_DIR/requirements-dev.txt"; then
  printf '%s\n' "requirements-dev.txt must keep the exact Ruff pin." >&2
  exit 1
fi

for ci_contract in \
  'python-version: ["3.12", "3.14"]' \
  'cimg/python:<< parameters.python-version >>'; do
  if ! grep -Fq "$ci_contract" "$ROOT_DIR/.circleci/config.yml"; then
    printf '%s\n' "CircleCI must keep contract: $ci_contract" >&2
    exit 1
  fi
done

for workflow_contract in \
  'permissions:' \
  'contents: read' \
  'actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10' \
  'actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405' \
  'persist-credentials: false' \
  'python-version: ["3.12", "3.14"]' \
  'concurrency:' \
  'cancel-in-progress: true' \
  'runs-on: ubuntu-24.04' \
  'run: make check' \
  'make -f "$GITHUB_WORKSPACE/Makefile" check'; do
  if ! grep -Fq "$workflow_contract" "$ROOT_DIR/.github/workflows/check.yml"; then
    printf '%s\n' "GitHub Actions must keep contract: $workflow_contract" >&2
    exit 1
  fi
done

if grep -Fq 'ubuntu-latest' "$ROOT_DIR/.github/workflows/check.yml"; then
  printf '%s\n' "GitHub Actions must not use a floating Ubuntu runner." >&2
  exit 1
fi

if grep -Fq 'pull_request_target' "$ROOT_DIR/.github/workflows/check.yml"; then
  printf '%s\n' "GitHub Actions must not run pull-request code with target-branch privileges." >&2
  exit 1
fi

for workflow_contract in \
  'push:' \
  'pull_request:' \
  'schedule:' \
  'workflow_dispatch:' \
  'contents: read' \
  'security-events: write' \
  'runs-on: ubuntu-24.04' \
  'timeout-minutes: 10' \
  'language: [actions, python]' \
  'build-mode: none' \
  'concurrency:' \
  'cancel-in-progress: true' \
  'actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10' \
  'github/codeql-action/init@8aad20d150bbac5944a9f9d289da16a4b0d87c1e' \
  'github/codeql-action/analyze@8aad20d150bbac5944a9f9d289da16a4b0d87c1e' \
  'persist-credentials: false'; do
  if ! grep -Fq "$workflow_contract" "$ROOT_DIR/.github/workflows/codeql.yml"; then
    printf '%s\n' "CodeQL must keep contract: $workflow_contract" >&2
    exit 1
  fi
done

if grep -Fq 'ubuntu-latest' "$ROOT_DIR/.github/workflows/codeql.yml"; then
  printf '%s\n' "CodeQL must not use a floating Ubuntu runner." >&2
  exit 1
fi

if grep -Fq 'pull_request_target' "$ROOT_DIR/.github/workflows/codeql.yml"; then
  printf '%s\n' "CodeQL must not run pull-request code with target-branch privileges." >&2
  exit 1
fi

action_count=$(grep -Ec '^[[:space:]]*(- )?uses: ' "$ROOT_DIR/.github/workflows/check.yml")
if [ "$action_count" -ne 2 ]; then
  printf '%s\n' "GitHub Actions must use exactly the approved checkout and setup-python actions." >&2
  exit 1
fi

sed -n 's/^[[:space:]]*-\{0,1\}[[:space:]]*uses:[[:space:]]*\([^[:space:]]*\).*/\1/p' \
  "$ROOT_DIR/.github/workflows/check.yml" | while IFS= read -r action; do
  case "$action" in
    actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10|\
    actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405)
      ;;
    *)
      printf '%s\n' "GitHub Actions contains an unapproved action: $action" >&2
      exit 1
      ;;
  esac
done

codeql_action_count=$(grep -Ec '^[[:space:]]*(- )?uses: ' "$ROOT_DIR/.github/workflows/codeql.yml")
if [ "$codeql_action_count" -ne 3 ]; then
  printf '%s\n' "CodeQL must use exactly checkout, init, and analyze actions." >&2
  exit 1
fi

sed -n 's/^[[:space:]]*-\{0,1\}[[:space:]]*uses:[[:space:]]*\([^[:space:]]*\).*/\1/p' \
  "$ROOT_DIR/.github/workflows/codeql.yml" | while IFS= read -r action; do
  case "$action" in
    actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10|\
    github/codeql-action/init@8aad20d150bbac5944a9f9d289da16a4b0d87c1e|\
    github/codeql-action/analyze@8aad20d150bbac5944a9f9d289da16a4b0d87c1e)
      ;;
    *)
      printf '%s\n' "CodeQL contains an unapproved action: $action" >&2
      exit 1
      ;;
  esac
done

workflow_count=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) | wc -l | tr -d ' ')
if [ "$workflow_count" -ne 2 ]; then
  printf '%s\n' ".github/workflows must contain only check.yml and codeql.yml." >&2
  exit 1
fi

if ! grep -Fq 'GitHub Actions uses credential-free checkout and runs `make check` from outside the repository directory.' "$README"; then
  printf '%s\n' "README must document external-working-directory verification." >&2
  exit 1
fi

if ! grep -Fq 'credential persistence disabled' "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY.md must document credential-free checkout." >&2
  exit 1
fi

printf '%s\n' "air-quality baseline checks passed."
