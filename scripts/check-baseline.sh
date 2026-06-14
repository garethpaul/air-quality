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
  "docs/plans/2026-06-13-air-quality-cache-transport-errors.md" \
  "docs/plans/2026-06-13-air-quality-geocoder-transport-errors.md" \
  "docs/plans/2026-06-13-air-quality-https-data-source.md" \
  "docs/plans/2026-06-13-air-quality-public-data-addresses.md" \
  "docs/plans/2026-06-13-air-quality-upstream-transport-errors.md" \
  "docs/plans/2026-06-14-make-root-override-protection.md" \
  "docs/plans/2026-06-14-air-quality-response-encoding-validation.md" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

python - "$ROOT_DIR/air.py" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
validator = source.split("def _require_https_data_url(url):", 1)[1].split(
    "\n\ndef _require_https_redirect", 1
)[0]
redirect_hook = source.split("def _require_https_redirect(response", 1)[1].split(
    "\n\ndef _default_http_get", 1
)[0]
function = source.split("def _default_http_get(url):", 1)[1].split(
    "\n\nclass AirQuality", 1
)[0]
precheck = "_require_https_data_url(url)"
request = "response = requests.get("
redirect_check = "_require_https_data_url(response.url)"
status_check = "response.raise_for_status()"
close = "response.close()"

if source.count('HTTPS_DATA_URL_ERROR = "AIRQUALITY_DATA URL must use HTTPS"') != 1:
    raise SystemExit("HTTPS data URL failures must use one generic local message.")
if source.count("raise RuntimeError(HTTPS_DATA_URL_ERROR)") != 2:
    raise SystemExit("Every HTTPS data URL rejection must use the generic error constant.")
if not (
    "except (AttributeError, TypeError, ValueError):" in validator
    and "raise RuntimeError(HTTPS_DATA_URL_ERROR) from None" in validator
    and "parsed.username is not None" in validator
    and "parsed.password is not None" in validator
):
    raise SystemExit("Malformed or credential-bearing URLs must use the generic HTTPS error.")
if not (
    "urljoin(response.url, response.headers[\"Location\"])" in redirect_hook
    and "_require_https_data_url(redirect_url)" in redirect_hook
    and redirect_hook.index("_require_https_data_url(redirect_url)")
    < redirect_hook.index("response.close()")
):
    raise SystemExit("Redirect targets must be validated before Requests follows them.")
if 'hooks={"response": _require_https_redirect}' not in function:
    raise SystemExit("The default request must install the HTTPS redirect hook.")
if not (precheck in function and request in function and function.index(precheck) < function.index(request)):
    raise SystemExit("AIRQUALITY_DATA URLs must be validated before requests.get.")
if not (
    redirect_check in function
    and status_check in function
    and function.index(request) < function.index(redirect_check) < function.index(status_check)
):
    raise SystemExit("Final response URLs must be validated before status and body processing.")
if close not in function:
    raise SystemExit("Redirect downgrade rejection must retain response cleanup.")
PY

for https_test_contract in \
  "test_default_http_get_rejects_plaintext_url_before_request" \
  "test_default_http_get_normalizes_malformed_url_without_request" \
  "test_default_http_get_rejects_url_userinfo_before_resolution" \
  "test_default_http_get_allows_relative_https_redirect_target" \
  "test_default_http_get_rejects_plaintext_redirect_before_following" \
  "test_default_http_get_rejects_redirect_downgrade_and_closes_response"; do
  if ! grep -Fq "$https_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "HTTPS data source tests must keep contract: $https_test_contract" >&2
    exit 1
  fi
done

for response_encoding_source_contract in \
  'except (LookupError, UnicodeDecodeError, ValueError):' \
  'raise RuntimeError("AIRQUALITY_DATA response must be valid JSON")'; do
  if ! grep -Fq "$response_encoding_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Upstream response encoding must keep source contract: $response_encoding_source_contract" >&2
    exit 1
  fi
done

if ! grep -Fq \
  'test_default_http_get_normalizes_unknown_encoding_and_closes_response' \
  "$ROOT_DIR/air_tests.py"; then
  printf '%s\n' 'Upstream response encoding regression must remain covered.' >&2
  exit 1
fi

for response_encoding_document in \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md"; do
  if ! grep -Fq "unsupported response encodings" "$response_encoding_document"; then
    printf '%s\n' "$response_encoding_document must document unsupported response encodings." >&2
    exit 1
  fi
done

for public_address_source_contract in \
  'PUBLIC_DATA_HOST_ERROR = "AIRQUALITY_DATA host must resolve to public addresses"' \
  'socket.getaddrinfo(' \
  'family=socket.AF_UNSPEC' \
  'type=socket.SOCK_STREAM' \
  'ipaddress.ip_address(result[4][0])' \
  'except (IndexError, OSError, TypeError, ValueError):' \
  'if not addresses or any(' \
  'not address.is_global or address.is_multicast for address in addresses'; do
  if ! grep -Fq "$public_address_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Public address enforcement must keep contract: $public_address_source_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc '_require_public_data_host(hostname, port)' "$ROOT_DIR/air.py")" -ne 2 ]; then
  printf '%s\n' "Every accepted HTTPS data URL must enforce the public address policy." >&2
  exit 1
fi

for public_address_test_contract in \
  'test_default_http_get_rejects_private_literal_before_request' \
  'test_default_http_get_rejects_private_ipv6_literal_before_request' \
  'test_default_http_get_rejects_multicast_literals_before_request' \
  'test_default_http_get_rejects_mixed_public_private_dns_answers' \
  'test_default_http_get_rejects_empty_dns_answers' \
  'test_default_http_get_normalizes_dns_resolution_failure' \
  'test_default_http_get_rejects_private_redirect_before_following' \
  'test_default_http_get_rejects_private_final_url_before_status' \
  'test_default_http_get_resolves_hostname_for_stream_connections'; do
  if ! grep -Fq "$public_address_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Public address tests must keep contract: $public_address_test_contract" >&2
    exit 1
  fi
done

for public_address_document in \
  "$README" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md"; do
  if ! grep -Fq "globally reachable" "$public_address_document"; then
    printf '%s\n' "$public_address_document must document the globally reachable address policy." >&2
    exit 1
  fi
done

python - "$ROOT_DIR/geocode.py" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
function = source.split("    def getLatLng(self):", 1)[1].split(
    "\n    def cached_data", 1
)[0]

if source.count('GEOCODER_ERROR_MESSAGE = "geocoder request failed"') != 1:
    raise SystemExit("Geocoder failures must use one stable local message.")
if function.count("except Exception:") != 1:
    raise SystemExit("Geocoder request and JSON decoding must share one exception boundary.")
if function.count("raise RuntimeError(GEOCODER_ERROR_MESSAGE) from None") != 1:
    raise SystemExit("Geocoder failures must use one unchained generic RuntimeError.")
for contract in (
    "response = self.geocoder_client().forward(self.query)",
    "payload = response.json()",
    "data = self.parse_first_feature_center(payload)",
):
    if contract not in function:
        raise SystemExit(f"Geocoder handling must keep contract: {contract}")
if not (
    function.index("response = self.geocoder_client().forward(self.query)")
    < function.index("payload = response.json()")
    < function.index("except Exception:")
    < function.index("data = self.parse_first_feature_center(payload)")
):
    raise SystemExit("Payload validation must remain outside the geocoder transport boundary.")
PY

for geocoder_transport_test_contract in \
  "test_geocoder_request_failure_is_normalized_without_detail" \
  "test_geocoder_json_failure_is_normalized_without_detail" \
  "test_malformed_geocoder_payloads_raise_value_error"; do
  if ! grep -Fq "$geocoder_transport_test_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Geocoder transport tests must keep contract: $geocoder_transport_test_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "response.close()" "$ROOT_DIR/air.py"; then
  printf '%s\n' "Default upstream responses must be closed." >&2
  exit 1
fi

if [ "$(grep -Fc 'except requests.exceptions.RequestException:' "$ROOT_DIR/air.py")" -ne 2 ] ||
   [ "$(grep -Fc 'raise RuntimeError("AIRQUALITY_DATA request failed") from None' "$ROOT_DIR/air.py")" -ne 2 ]; then
  printf '%s\n' "Requests transport failures must use both unchained generic error boundaries." >&2
  exit 1
fi

for transport_test_contract in \
  "test_default_http_get_normalizes_connection_failure" \
  "test_default_http_get_normalizes_status_failure_and_closes_response" \
  "test_default_http_get_normalizes_stream_failure_and_closes_response"; do
  if ! grep -Fq "$transport_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Transport regression tests must keep contract: $transport_test_contract" >&2
    exit 1
  fi
done

for cache_source in "$ROOT_DIR/air.py" "$ROOT_DIR/geocode.py"; do
  if ! grep -Fq 'CACHE_ERROR_MESSAGE = "cache request failed"' "$cache_source" ||
     [ "$(grep -Fc 'raise RuntimeError(CACHE_ERROR_MESSAGE) from None' "$cache_source")" -ne 2 ]; then
    printf '%s\n' "$cache_source must normalize cache commands to an unchained generic error." >&2
    exit 1
  fi
done

for cache_contract in \
  'cache = self.cache_get(key)' \
  'self.cache_setex(key, CACHE_TTL_SECONDS, json.dumps(data))'; do
  if ! grep -Fq "$cache_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "AQI cache handling must keep contract: $cache_contract" >&2
    exit 1
  fi
done

for cache_contract in \
  'cache = self.cache_get(key)' \
  'self.cache_set(key, json.dumps(data))'; do
  if ! grep -Fq "$cache_contract" "$ROOT_DIR/geocode.py"; then
    printf '%s\n' "Geocode cache handling must keep contract: $cache_contract" >&2
    exit 1
  fi
done

for cache_test_contract in \
  'test_cache_read_failure_is_normalized_before_upstream_request' \
  'test_missing_cache_configuration_remains_a_configuration_error' \
  'test_cache_write_failure_is_normalized_after_valid_upstream_response'; do
  if ! grep -Fq "$cache_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "AQI cache regression tests must keep contract: $cache_test_contract" >&2
    exit 1
  fi
done

for cache_test_contract in \
  'test_cache_read_failure_is_normalized_before_geocoder_request' \
  'test_missing_cache_configuration_remains_a_configuration_error' \
  'test_cache_write_failure_is_normalized_after_valid_geocoder_response'; do
  if ! grep -Fq "$cache_test_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Geocode cache regression tests must keep contract: $cache_test_contract" >&2
    exit 1
  fi
done

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

if ! grep -Fxq 'override ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))' "$MAKEFILE"; then
  printf '%s\n' "Makefile must protect the repository root." >&2
  exit 1
fi

if ! grep -Fxq 'PYTHON_FILES := $(shell git -C "$(ROOT)" ls-files '\''*.py'\'')' "$MAKEFILE"; then
  printf '%s\n' "Makefile must derive Python files from the repository root." >&2
  exit 1
fi

if [ "$(grep -Fc 'cd "$(ROOT)" &&' "$MAKEFILE")" -ne 4 ]; then
  printf '%s\n' "All four package commands must execute from the repository root." >&2
  exit 1
fi

make_tab=$(printf '\t')
if ! grep -Fxq "${make_tab}\"\$(ROOT)/scripts/check-baseline.sh\"" "$MAKEFILE"; then
  printf '%s\n' "Makefile must execute the rooted baseline script." >&2
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

for reliability_document in "$README" "$ROOT_DIR/SECURITY.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Requests transport failures" "$reliability_document"; then
    printf '%s\n' "$reliability_document must document Requests transport failures." >&2
    exit 1
  fi
  if ! grep -Fq "Cache command failures" "$reliability_document"; then
    printf '%s\n' "$reliability_document must document Cache command failures." >&2
    exit 1
  fi
  if ! grep -Fq "Geocoder transport failures" "$reliability_document"; then
    printf '%s\n' "$reliability_document must document Geocoder transport failures." >&2
    exit 1
  fi
  if ! grep -Fq "HTTPS-only data source" "$reliability_document"; then
    printf '%s\n' "$reliability_document must document the HTTPS-only data source boundary." >&2
    exit 1
  fi
done

if ! grep -Fq "geocoder transport failures" "$ROOT_DIR/VISION.md"; then
  printf '%s\n' "VISION.md must document geocoder transport failures." >&2
  exit 1
fi

GEOCODER_TRANSPORT_PLAN="$DOCS_PLANS/2026-06-13-air-quality-geocoder-transport-errors.md"
for plan_contract in \
  "status: completed" \
  "## Work Completed" \
  "## Verification Completed" \
  "make check" \
  "test_geocoder_request_failure_is_normalized_without_detail" \
  "test_geocoder_json_failure_is_normalized_without_detail" \
  'External-working-directory `make check`'; do
  if ! grep -Fiq "$plan_contract" "$GEOCODER_TRANSPORT_PLAN"; then
    printf '%s\n' "Geocoder transport plan must keep completed evidence: $plan_contract" >&2
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
  if ! grep -Eiq '^(##[[:space:]]+)?status:[[:space:]]+completed[[:space:]]*$' "$plan"; then
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
