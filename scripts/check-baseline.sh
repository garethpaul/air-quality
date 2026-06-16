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
  "DEPLOYMENT.md" \
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
  "docs/plans/2026-06-14-air-quality-content-length-validation.md" \
  "docs/plans/2026-06-14-strict-content-length-syntax.md" \
  "docs/plans/2026-06-14-preextend-stream-size-check.md" \
  "docs/plans/2026-06-14-air-quality-response-media-type.md" \
  "docs/plans/2026-06-14-air-quality-overflowing-reading-values.md" \
  "docs/plans/2026-06-14-air-quality-overflowing-geocoder-center.md" \
  "docs/plans/2026-06-14-small-instance-deployment-guide.md" \
  "docs/plans/2026-06-15-overflowing-cached-numeric-values.md" \
  "docs/plans/2026-06-15-air-quality-cache-guidance-consistency.md" \
  "docs/plans/2026-06-15-air-quality-boolean-scoring-inputs.md" \
  "docs/plans/2026-06-15-air-quality-zero-width-linear-range.md" \
  "docs/plans/2026-06-15-negative-aqi-category.md" \
  "docs/plans/2026-06-15-air-quality-constructor-coordinate-validation.md" \
  "docs/plans/2026-06-15-air-quality-constructor-validation-stack-reconciliation.md" \
  "docs/plans/2026-06-15-air-quality-route-coordinate-type-guards.md" \
  "docs/plans/2026-06-16-air-quality-signed-zero-coordinates.md" \
  "docs/plans/2026-06-16-air-quality-geocoder-signed-zero.md" \
  "docs/plans/2026-06-16-air-quality-permanent-geocoding-cache.md" \
  "docs/plans/2026-06-16-air-quality-canonical-geocode-cache.md" \
  "docs/plans/2026-06-16-disable-bottle-debug-default.md" \
  "docs/plans/2026-06-16-air-quality-geocoder-payload-errors.md" \
  "docs/plans/2026-06-16-server-port-validation.md" \
  "docs/plans/2026-06-16-search-query-control-character-guard.md" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

for permanent_geocoder_source_contract in \
  'MAPBOX_PERMANENT_DATASET = "mapbox.places-permanent"' \
  'self.geocoder = Geocoder(name=MAPBOX_PERMANENT_DATASET)'; do
  if ! grep -Fq "$permanent_geocoder_source_contract" "$ROOT_DIR/geocode.py"; then
    printf '%s\n' "Permanent geocoder construction must keep contract: $permanent_geocoder_source_contract" >&2
    exit 1
  fi
done

if grep -Fq 'self.geocoder = Geocoder()' "$ROOT_DIR/geocode.py"; then
  printf '%s\n' "Cached geocoding must not use the temporary default Mapbox dataset." >&2
  exit 1
fi

for permanent_geocoder_test_contract in \
  'test_default_geocoder_uses_permanent_dataset_before_caching' \
  '("construct", {"name": "mapbox.places-permanent"})' \
  '("forward", "San Francisco, CA")' \
  '"geocode_query_1_San Francisco, CA"'; do
  if ! grep -Fq "$permanent_geocoder_test_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Permanent geocoder regression must keep contract: $permanent_geocoder_test_contract" >&2
    exit 1
  fi
done

for permanent_geocoder_document in README.md SECURITY.md CHANGES.md; do
  if ! grep -Fq 'Cached Mapbox results use the `mapbox.places-permanent` dataset' "$ROOT_DIR/$permanent_geocoder_document"; then
    printf '%s\n' "$permanent_geocoder_document must document permanent Mapbox geocoding." >&2
    exit 1
  fi
done

for permanent_geocoder_plan_contract in \
  '## Status: Completed' \
  'repository-root and external-directory `make check`' \
  'hostile mutations' \
  'No live Mapbox request was made'; do
  if ! grep -Fq "$permanent_geocoder_plan_contract" "$ROOT_DIR/docs/plans/2026-06-16-air-quality-permanent-geocoding-cache.md"; then
    printf '%s\n' "Permanent geocoding plan must record completed evidence: $permanent_geocoder_plan_contract" >&2
    exit 1
  fi
done

for canonical_geocode_cache_source_contract in \
  'any(isinstance(data[field], str) for field in ("lat", "lng"))' \
  'self.cache_set(key, json.dumps(normalized))'; do
  if ! grep -Fq "$canonical_geocode_cache_source_contract" "$ROOT_DIR/geocode.py"; then
    printf '%s\n' "Canonical geocode cache handling must keep contract: $canonical_geocode_cache_source_contract" >&2
    exit 1
  fi
done

for canonical_geocode_cache_test_contract in \
  'test_cached_numeric_strings_are_rewritten_as_canonical_numbers' \
  'test_canonical_numeric_cache_hit_does_not_rewrite' \
  'test_numeric_string_cache_repair_failure_is_normalized' \
  'self.assertIsInstance(cached["lat"], float)' \
  'self.assertEqual(geocoder.queries, [])'; do
  if ! grep -Fq "$canonical_geocode_cache_test_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Canonical geocode cache regression must keep contract: $canonical_geocode_cache_test_contract" >&2
    exit 1
  fi
done

for canonical_geocode_cache_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "cached geocoder numeric strings" "$ROOT_DIR/$canonical_geocode_cache_document"; then
    printf '%s\n' "$canonical_geocode_cache_document must document canonical cached geocoder numbers." >&2
    exit 1
  fi
done

for canonical_geocode_cache_plan_contract in \
  'Status: Completed' \
  'repository and external-directory `make check`' \
  'hostile mutations' \
  'Live Redis, Mapbox credentials, and provider behavior remain outside'; do
  if ! grep -Fq "$canonical_geocode_cache_plan_contract" "$ROOT_DIR/docs/plans/2026-06-16-air-quality-canonical-geocode-cache.md"; then
    printf '%s\n' "Canonical geocode cache plan must record completed evidence: $canonical_geocode_cache_plan_contract" >&2
    exit 1
  fi
done

for geocoder_signed_zero_source_contract in \
  'from air import _canonicalize_zero' \
  '"lat": _canonicalize_zero(lat)' \
  '"lng": _canonicalize_zero(lng)' \
  'math.copysign(1.0, value) < 0' \
  'self.cache_set(key, json.dumps(normalized))'; do
  if ! grep -Fq "$geocoder_signed_zero_source_contract" "$ROOT_DIR/geocode.py"; then
    printf '%s\n' "Geocoder signed-zero handling must keep contract: $geocoder_signed_zero_source_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Foc '"lat": _canonicalize_zero(lat)' "$ROOT_DIR/geocode.py")" -ne 2 ] || \
   [ "$(grep -Foc '"lng": _canonicalize_zero(lng)' "$ROOT_DIR/geocode.py")" -ne 2 ]; then
  printf '%s\n' "Fresh and cached geocoder coordinates must both canonicalize signed zero." >&2
  exit 1
fi

for geocoder_signed_zero_test_contract in \
  'test_fresh_geocoder_center_canonicalizes_and_caches_signed_zero' \
  'test_cached_geocoder_coordinates_canonicalize_signed_zero' \
  'test_signed_zero_cache_repair_failure_is_normalized' \
  'test_positive_zero_cache_hit_does_not_rewrite' \
  'math.copysign(1.0, cached["lat"])' \
  'math.copysign(1.0, cache.decoded(key)["lat"])' \
  'self.assertEqual(geocoder.queries, [])'; do
  if ! grep -Fq "$geocoder_signed_zero_test_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Geocoder signed-zero regression must keep contract: $geocoder_signed_zero_test_contract" >&2
    exit 1
  fi
done

for geocoder_signed_zero_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "Mapbox and cached geocoder signed-zero coordinates normalize to positive zero" "$ROOT_DIR/$geocoder_signed_zero_document"; then
    printf '%s\n' "$geocoder_signed_zero_document must document geocoder signed-zero normalization." >&2
    exit 1
  fi
done

for geocoder_signed_zero_plan_contract in \
  'Status: Completed' \
  'repository and external-directory `make check`' \
  'hostile mutations' \
  'Live Redis, Mapbox credentials, and provider behavior remain outside'; do
  if ! grep -Fq "$geocoder_signed_zero_plan_contract" "$ROOT_DIR/docs/plans/2026-06-16-air-quality-geocoder-signed-zero.md"; then
    printf '%s\n' "Geocoder signed-zero plan must record completed evidence: $geocoder_signed_zero_plan_contract" >&2
    exit 1
  fi
done

for signed_zero_source_contract in \
  'def _canonicalize_zero(value):' \
  'return 0.0 if value == 0.0 else value' \
  'return _canonicalize_zero(coordinate)'; do
  if ! grep -Fq "$signed_zero_source_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$signed_zero_source_contract" "$ROOT_DIR/app.py"; then
    printf '%s\n' "Signed-zero coordinate handling must keep contract: $signed_zero_source_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Foc 'return _canonicalize_zero(coordinate)' "$ROOT_DIR/air.py" "$ROOT_DIR/app.py" | awk -F: '{ total += $2 } END { print total + 0 }')" -ne 2 ]; then
  printf '%s\n' "Constructor and route coordinate boundaries must both canonicalize zero." >&2
  exit 1
fi

for signed_zero_test_contract in \
  'test_constructor_canonicalizes_signed_zero_coordinates_and_cache_keys' \
  'math.copysign(1.0, quality.lat)' \
  'self.assertEqual(positive.cache_key(), negative.cache_key())' \
  'test_parse_coordinate_canonicalizes_signed_zero' \
  'test_air_quality_payload_passes_canonical_zero_coordinates' \
  'math.copysign(1.0, FakeAirQuality.calls[0][0])'; do
  if ! grep -Fq "$signed_zero_test_contract" "$ROOT_DIR/air_tests.py" "$ROOT_DIR/app_tests.py"; then
    printf '%s\n' "Signed-zero coordinate regression must keep contract: $signed_zero_test_contract" >&2
    exit 1
  fi
done

for signed_zero_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "signed-zero coordinates normalize to positive zero" "$ROOT_DIR/$signed_zero_document"; then
    printf '%s\n' "$signed_zero_document must document canonical signed-zero coordinates." >&2
    exit 1
  fi
done

for signed_zero_plan_contract in \
  'Status: Completed' \
  'repository and external-directory `make check`' \
  'hostile mutations' \
  'Live Redis, configured upstream data, and provider behavior remain outside'; do
  if ! grep -Fq "$signed_zero_plan_contract" "$ROOT_DIR/docs/plans/2026-06-16-air-quality-signed-zero-coordinates.md"; then
    printf '%s\n' "Signed-zero coordinate plan must record completed evidence: $signed_zero_plan_contract" >&2
    exit 1
  fi
done

for cached_guidance_contract in \
  'if normalized_score != score or normalized_score < 0 or normalized_score > 500:' \
  'normalized_data = self.AQICategory(normalized_score)' \
  'category != normalized_data["category"]' \
  'caution != normalized_data["caution"]' \
  '"category": "Out of Range", "caution": "None", "score": 501' \
  '"category": "Hazardous", "caution": "None", "score": 50' \
  '"caution": "Everyone should remain indoors."'; do
  if ! grep -Fq "$cached_guidance_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$cached_guidance_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Cached AQI guidance must keep contract: $cached_guidance_contract" >&2
    exit 1
  fi
done

for cached_guidance_document in \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/AGENTS.md" \
  "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Cached AQI guidance is accepted only when its 0-500 score" \
    "$cached_guidance_document"; then
    printf '%s\n' "$cached_guidance_document must document canonical cached AQI guidance." >&2
    exit 1
  fi
done

for cached_guidance_plan_contract in \
  'status: completed' \
  '68 tests' \
  'make check' \
  'external working directory' \
  'hostile mutations' \
  'secret and generated-artifact scan'; do
  if ! grep -Fq "$cached_guidance_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-cache-guidance-consistency.md"; then
    printf '%s\n' "Cached AQI guidance plan must preserve completion evidence: $cached_guidance_plan_contract" >&2
    exit 1
  fi
done

for preextend_size_source_contract in \
  'if len(body) + len(chunk) > UPSTREAM_RESPONSE_MAX_BYTES:' \
  'body.extend(chunk)'; do
  if ! grep -Fq "$preextend_size_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Pre-extend stream limit must keep contract: $preextend_size_source_contract" >&2
    exit 1
  fi
done

preextend_check_line=$(grep -n 'if len(body) + len(chunk) > UPSTREAM_RESPONSE_MAX_BYTES:' "$ROOT_DIR/air.py" | cut -d: -f1)
preextend_extend_line=$(grep -n 'body.extend(chunk)' "$ROOT_DIR/air.py" | cut -d: -f1)
if [ "$preextend_check_line" -ge "$preextend_extend_line" ]; then
  printf '%s\n' 'Stream size must be checked before extending the response buffer.' >&2
  exit 1
fi

for preextend_size_test_contract in \
  'test_default_http_get_rejects_oversized_chunk_before_buffer_extension' \
  'self.assertEqual(TrackingBytearray.extend_calls, 0)'; do
  if ! grep -Fq "$preextend_size_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Pre-extend stream limit tests must keep contract: $preextend_size_test_contract" >&2
    exit 1
  fi
done

for preextend_size_document in \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md"; do
  if ! grep -Fq "before extending the retained response buffer" "$preextend_size_document"; then
    printf '%s\n' "$preextend_size_document must document the pre-extension stream limit." >&2
    exit 1
  fi
done

if ! grep -Fq "before extending the retained response" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' 'CHANGES.md must record the pre-extension stream limit.' >&2
  exit 1
fi

for overflowing_cache_contract in \
  'except OverflowError:' \
  'except (KeyError, OverflowError, TypeError, ValueError):' \
  '"score": 10**400' \
  '"lat": 10**400' \
  '"lng": 10**400'; do
  if ! grep -Fq "$overflowing_cache_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$overflowing_cache_contract" "$ROOT_DIR/geocode.py" && \
     ! grep -Fq "$overflowing_cache_contract" "$ROOT_DIR/air_tests.py" && \
     ! grep -Fq "$overflowing_cache_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Overflowing cached numeric handling must keep contract: $overflowing_cache_contract" >&2
    exit 1
  fi
done

for overflowing_cache_document in \
  "$README" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" \
  "$ROOT_DIR/AGENTS.md" \
  "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Overflowing cached numeric values are ignored and refreshed" "$overflowing_cache_document"; then
    printf '%s\n' "$overflowing_cache_document must document overflowing cached numeric handling." >&2
    exit 1
  fi
done

for overflowing_cache_plan_contract in \
  'status: completed' \
  '68 tests' \
  'make check' \
  'external working directory' \
  'hostile mutations' \
  'secret and generated-artifact scan'; do
  if ! grep -Fq "$overflowing_cache_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-overflowing-cached-numeric-values.md"; then
    printf '%s\n' "Overflowing cached numeric plan must preserve completion evidence: $overflowing_cache_plan_contract" >&2
    exit 1
  fi
done

for deployment_contract in \
  'APP_LOCATION' \
  'PORT' \
  'REDIS_URL' \
  'MAPBOX_ACCESS_TOKEN' \
  'AIRQUALITY_DATA' \
  'Never run the process as root.' \
  'curl --fail --silent --show-error --max-time 15' \
  'restore the previous release checkout' \
  'do not prove a live Redis service'; do
  if ! grep -Fq "$deployment_contract" "$ROOT_DIR/DEPLOYMENT.md"; then
    printf '%s\n' "Deployment guide must keep contract: $deployment_contract" >&2
    exit 1
  fi
done

for deployment_doc_contract in \
  'provider-neutral small-instance deployment runbook' \
  'unprivileged service account'; do
  if ! grep -Fq "$deployment_doc_contract" "$README"; then
    printf '%s\n' "README must keep deployment contract: $deployment_doc_contract" >&2
    exit 1
  fi
done

for deployment_plan_contract in \
  'Status: Completed' \
  'make check' \
  'hostile mutations' \
  'No live Redis, Mapbox, sensor-feed, TLS-proxy, or deployed-instance verification is claimed.'; do
  if ! grep -Fq "$deployment_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-14-small-instance-deployment-guide.md"; then
    printf '%s\n' "Deployment plan must preserve completion evidence: $deployment_plan_contract" >&2
    exit 1
  fi
done

for overflowing_geocoder_contract in \
  'except (OverflowError, TypeError, ValueError):' \
  'test_overflowing_geocoder_center_values_are_service_errors' \
  'huge_integer = 10**400' \
  '[huge_integer, "37.794678"]' \
  '["-122.41143", huge_integer]' \
  'RuntimeError, "^geocoder request failed$"'; do
  if ! grep -Fq "$overflowing_geocoder_contract" "$ROOT_DIR/geocode.py" && \
     ! grep -Fq "$overflowing_geocoder_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Overflowing geocoder center handling must keep contract: $overflowing_geocoder_contract" >&2
    exit 1
  fi
done

for overflowing_geocoder_doc in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "Overflowing Mapbox center values are rejected before coordinate caching." \
    "$ROOT_DIR/$overflowing_geocoder_doc"; then
    printf '%s\n' "$overflowing_geocoder_doc must document overflowing Mapbox center rejection." >&2
    exit 1
  fi
done

for overflowing_geocoder_plan_contract in \
  "Status: Completed" \
  "test_overflowing_geocoder_center_values_raise_value_error" \
  "make check" \
  "hostile mutations"; do
  if ! grep -Fq "$overflowing_geocoder_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-14-air-quality-overflowing-geocoder-center.md"; then
    printf '%s\n' "Overflowing geocoder center plan must preserve completion evidence: $overflowing_geocoder_plan_contract" >&2
    exit 1
  fi
done

for boolean_geocoder_contract in \
  'isinstance(data.get("lat"), bool)' \
  'isinstance(data.get("lng"), bool)' \
  'isinstance(center[0], bool)' \
  'isinstance(center[1], bool)' \
  'json.dumps({"lat": True, "lng": -122.41143})' \
  'json.dumps({"lat": 37.794678, "lng": False})' \
  'test_boolean_geocoder_center_values_are_service_errors' \
  '[True, "37.794678"]' \
  '["-122.41143", False]' \
  'RuntimeError, "^geocoder request failed$"'; do
  if ! grep -Fq "$boolean_geocoder_contract" "$ROOT_DIR/geocode.py" && \
     ! grep -Fq "$boolean_geocoder_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Boolean geocoder coordinate handling must keep contract: $boolean_geocoder_contract" >&2
    exit 1
  fi
done

for boolean_geocoder_doc in AGENTS.md README.md SECURITY.md CHANGES.md; do
  if ! grep -Fq "Boolean Mapbox and cached geocoder coordinates are rejected" \
    "$ROOT_DIR/$boolean_geocoder_doc"; then
    printf '%s\n' "$boolean_geocoder_doc must document boolean geocoder coordinate rejection." >&2
    exit 1
  fi
done

for boolean_geocoder_plan_contract in \
  "status: completed" \
  "test_boolean_geocoder_center_values_raise_value_error" \
  "make check" \
  "hostile mutations"; do
  if ! grep -Fq "$boolean_geocoder_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-boolean-geocoder-coordinates.md"; then
    printf '%s\n' "Boolean geocoder coordinate plan must preserve completion evidence: $boolean_geocoder_plan_contract" >&2
    exit 1
  fi
done

route_coordinate_helper=$(awk '
  /^def parse_coordinate\(value, name\):$/ { capture = 1 }
  /^def air_quality_payload\(lat, lng, air_quality_factory=AirQuality\):$/ { capture = 0 }
  capture { print }
' "$ROOT_DIR/app.py")

for route_coordinate_helper_contract in \
  'def parse_coordinate(value, name):' \
  'if isinstance(value, bool):' \
  'except (OverflowError, TypeError, ValueError):'; do
  if ! printf '%s\n' "$route_coordinate_helper" | \
    grep -Fq "$route_coordinate_helper_contract"; then
    printf '%s\n' "Route coordinate helper must keep contract: $route_coordinate_helper_contract" >&2
    exit 1
  fi
done

for route_coordinate_test_contract in \
  'test_parse_coordinate_rejects_boolean_and_overflowing_numeric_values' \
  'test_rejected_coordinate_types_do_not_construct_air_quality' \
  '(True, "lat")' \
  '(False, "lng")' \
  '(10**400, "lat")' \
  'self.assertEqual(FakeAirQuality.calls, [])'; do
  if ! grep -Fq "$route_coordinate_test_contract" "$ROOT_DIR/app_tests.py"; then
    printf '%s\n' "Route coordinate tests must keep contract: $route_coordinate_test_contract" >&2
    exit 1
  fi
done

for route_coordinate_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "Route coordinate validation rejects boolean and overflowing numeric values before AirQuality construction." \
    "$ROOT_DIR/$route_coordinate_document"; then
    printf '%s\n' "$route_coordinate_document must document route coordinate type guards." >&2
    exit 1
  fi
done

for route_coordinate_plan_contract in \
  'Status: Completed' \
  'test_parse_coordinate_rejects_boolean_and_overflowing_numeric_values' \
  'repository and external-directory `make check` passed' \
  'hostile mutations were rejected'; do
  if ! grep -Fq "$route_coordinate_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-route-coordinate-type-guards.md"; then
    printf '%s\n' "Route coordinate plan must preserve completion evidence: $route_coordinate_plan_contract" >&2
    exit 1
  fi
done

constructor_coordinate_helper=$(awk '
  /^def _normalize_coordinate\(value, name\):$/ { capture = 1 }
  /^def _require_https_data_url\(url\):$/ { capture = 0 }
  capture { print }
' "$ROOT_DIR/air.py")

for constructor_coordinate_helper_contract in \
  'def _normalize_coordinate(value, name):' \
  'if isinstance(value, bool):' \
  'except (OverflowError, TypeError, ValueError):' \
  'if not math.isfinite(coordinate):' \
  'lower, upper = COORDINATE_BOUNDS[name]'; do
  if ! printf '%s\n' "$constructor_coordinate_helper" | \
    grep -Fq "$constructor_coordinate_helper_contract"; then
    printf '%s\n' "AirQuality coordinate helper must keep contract: $constructor_coordinate_helper_contract" >&2
    exit 1
  fi
done

for constructor_coordinate_contract in \
  'self.lat = _normalize_coordinate(lat, "lat")' \
  'self.lng = _normalize_coordinate(lng, "lng")' \
  'test_constructor_rejects_invalid_coordinates' \
  'test_constructor_normalizes_boundary_coordinates_and_numeric_strings' \
  '(True, 0)' \
  '(0, False)' \
  '(-90.1, 0)' \
  '(0, 180.1)'; do
  if ! grep -Fq "$constructor_coordinate_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$constructor_coordinate_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "AirQuality constructor validation must keep contract: $constructor_coordinate_contract" >&2
    exit 1
  fi
done

for constructor_coordinate_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "Direct AirQuality construction rejects boolean, nonnumeric, non-finite, and out-of-range coordinates." \
    "$ROOT_DIR/$constructor_coordinate_document"; then
    printf '%s\n' "$constructor_coordinate_document must document direct constructor coordinate validation." >&2
    exit 1
  fi
done

for constructor_coordinate_plan_contract in \
  "status: completed" \
  "test_constructor_rejects_invalid_coordinates" \
  "make check" \
  "hostile mutations"; do
  if ! grep -Fq "$constructor_coordinate_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-constructor-coordinate-validation.md"; then
    printf '%s\n' "Constructor coordinate plan must preserve completion evidence: $constructor_coordinate_plan_contract" >&2
    exit 1
  fi
done

for constructor_reconciliation_contract in \
  'Status: Completed' \
  '35881343ba155428aafa41374f01267df80c1bb8' \
  '4f56e528394ec731ceb06eb679efa8c45009444b' \
  'test_constructor_rejects_invalid_coordinates' \
  'test_scoring_helpers_reject_nonfinite_values' \
  'test_linear_rejects_zero_width_concentration_range' \
  'test_linear_rejects_descending_concentration_range' \
  'all 78 tests' \
  'hostile mutations'; do
  if ! grep -Fq "$constructor_reconciliation_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-constructor-validation-stack-reconciliation.md"; then
    printf '%s\n' "Constructor stack reconciliation plan must preserve evidence: $constructor_reconciliation_contract" >&2
    exit 1
  fi
done

for overflowing_reading_contract in \
  'except (OverflowError, TypeError, ValueError):' \
  'test_overflowing_sensor_values_are_ignored' \
  'huge_integer = 10**400'; do
  if ! grep -Fq "$overflowing_reading_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$overflowing_reading_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Overflowing sensor reading handling must keep contract: $overflowing_reading_contract" >&2
    exit 1
  fi
done

for overflowing_reading_document in \
  "$README" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" \
  "$ROOT_DIR/AGENTS.md"; do
  if ! grep -Fq "overflowing upstream sensor values" "$overflowing_reading_document"; then
    printf '%s\n' "$overflowing_reading_document must document overflowing sensor value handling." >&2
    exit 1
  fi
done

for overflowing_reading_plan_contract in \
  'status: completed' \
  '## Status: Completed' \
  'python run_tests.py` passed all 64 tests' \
  'Three isolated hostile mutations were rejected'; do
  if ! grep -Fq "$overflowing_reading_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-14-air-quality-overflowing-reading-values.md"; then
    printf '%s\n' "Overflowing sensor reading plan must preserve completion evidence: $overflowing_reading_plan_contract" >&2
    exit 1
  fi
done

for boolean_sensor_contract in \
  'for field in ("Lat", "Lon", "PM2_5Value")' \
  'test_boolean_sensor_values_are_ignored' \
  '{"Lat": True, "Lon": 1, "PM2_5Value": "1.0"}' \
  '{"Lat": 1, "Lon": False, "PM2_5Value": "2.0"}' \
  '{"Lat": 1, "Lon": 1, "PM2_5Value": True}' \
  'self.assertEqual(quality.getData(), MODERATE_12_PAYLOAD)'; do
  if ! grep -Fq "$boolean_sensor_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$boolean_sensor_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Boolean sensor handling must keep contract: $boolean_sensor_contract" >&2
    exit 1
  fi
done

for boolean_sensor_doc in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "Boolean upstream sensor values are ignored before distance and AQI calculations." \
    "$ROOT_DIR/$boolean_sensor_doc"; then
    printf '%s\n' "$boolean_sensor_doc must document boolean upstream sensor rejection." >&2
    exit 1
  fi
done

for boolean_sensor_plan_contract in \
  'status: completed' \
  'test_boolean_sensor_values_are_ignored' \
  '70 tests' \
  'make check' \
  'Six isolated hostile mutations' \
  'suspicious-secret audits'; do
  if ! grep -Fq "$boolean_sensor_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-boolean-sensor-values.md"; then
    printf '%s\n' "Boolean sensor plan must preserve completion evidence: $boolean_sensor_plan_contract" >&2
    exit 1
  fi
done

for boolean_scoring_contract in \
  'if isinstance(raw_value, bool):' \
  'for value in (AQIhigh, AQIlow, Conchigh, Conclow, Concentration)' \
  'if isinstance(AQIndex, bool):' \
  'test_scoring_helpers_reject_boolean_values' \
  '"Linear AQI high"' \
  '"Linear concentration"' \
  'quality.AQIPM25("9.1")' \
  'quality.AQICategory("120")'; do
  if ! grep -Fq "$boolean_scoring_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$boolean_scoring_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Boolean scoring helpers must keep contract: $boolean_scoring_contract" >&2
    exit 1
  fi
done

for boolean_scoring_doc in AGENTS.md README.md SECURITY.md CHANGES.md; do
  if ! grep -Fq "Boolean scoring helper inputs are rejected before numeric conversion." \
    "$ROOT_DIR/$boolean_scoring_doc"; then
    printf '%s\n' "$boolean_scoring_doc must document boolean scoring input rejection." >&2
    exit 1
  fi
done

for boolean_scoring_plan_contract in \
  'status: completed' \
  'test_scoring_helpers_reject_boolean_values' \
  '71 tests' \
  'make check' \
  'Seven isolated hostile mutations' \
  'suspicious-secret audits'; do
  if ! grep -Fq "$boolean_scoring_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-boolean-scoring-inputs.md"; then
    printf '%s\n' "Boolean scoring input plan must preserve completion evidence: $boolean_scoring_plan_contract" >&2
    exit 1
  fi
done

for nonfinite_scoring_contract in \
  'normalized_values = tuple(' \
  'if not all(math.isfinite(value) for value in normalized_values):' \
  'raise ValueError("AQI interpolation values must be finite")' \
  'if not math.isfinite(AQI):' \
  'raise ValueError("AQI score must be finite")' \
  'test_scoring_helpers_reject_nonfinite_values' \
  'float("-inf")'; do
  if ! grep -Fq "$nonfinite_scoring_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$nonfinite_scoring_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Non-finite scoring helpers must keep contract: $nonfinite_scoring_contract" >&2
    exit 1
  fi
done

for nonfinite_scoring_doc in AGENTS.md README.md SECURITY.md CHANGES.md; do
  if ! grep -Fq "Non-finite scoring helper inputs are rejected before interpolation or" \
    "$ROOT_DIR/$nonfinite_scoring_doc"; then
    printf '%s\n' "$nonfinite_scoring_doc must document non-finite scoring input rejection." >&2
    exit 1
  fi
done

if ! grep -Fq "Reject non-finite scoring helper inputs before interpolation or category" \
  "$ROOT_DIR/VISION.md"; then
  printf '%s\n' 'VISION.md must document non-finite scoring input rejection.' >&2
  exit 1
fi

for nonfinite_scoring_plan_contract in \
  'status: completed' \
  'test_scoring_helpers_reject_nonfinite_values' \
  '74 tests' \
  'make check' \
  'isolated hostile mutations' \
  'suspicious-secret audits'; do
  if ! grep -Fq "$nonfinite_scoring_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-nonfinite-scoring-inputs.md"; then
    printf '%s\n' "Non-finite scoring input plan must preserve completion evidence: $nonfinite_scoring_plan_contract" >&2
    exit 1
  fi
done

for zero_width_linear_source_contract in \
  'if Conchigh == Conclow:' \
  'AQI interpolation concentration range must not be zero-width'; do
  if ! grep -Fq "$zero_width_linear_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Zero-width AQI interpolation source must keep contract: $zero_width_linear_source_contract" >&2
    exit 1
  fi
done

for zero_width_linear_test_contract in \
  'test_linear_rejects_zero_width_concentration_range' \
  '("1.0", "1.0")' \
  'quality.Linear(50, 0, 9.0, 0.0, "9.0")'; do
  if ! grep -Fq "$zero_width_linear_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Zero-width AQI interpolation tests must keep contract: $zero_width_linear_test_contract" >&2
    exit 1
  fi
done

for zero_width_linear_doc in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "Zero-width AQI interpolation ranges are rejected before division." \
    "$ROOT_DIR/$zero_width_linear_doc"; then
    printf '%s\n' "$zero_width_linear_doc must document zero-width AQI interpolation rejection." >&2
    exit 1
  fi
done

for zero_width_linear_plan_contract in \
  'status: completed' \
  'test_linear_rejects_zero_width_concentration_range' \
  '75 tests' \
  'make check' \
  'isolated hostile mutations' \
  'suspicious-secret audits'; do
  if ! grep -Fq "$zero_width_linear_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-zero-width-linear-range.md"; then
    printf '%s\n' "Zero-width AQI interpolation plan must preserve completion evidence: $zero_width_linear_plan_contract" >&2
    exit 1
  fi
done

for descending_linear_source_contract in \
  'if Conchigh < Conclow:' \
  'AQI interpolation concentration range must be ascending'; do
  if ! grep -Fq "$descending_linear_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Descending AQI interpolation source must keep contract: $descending_linear_source_contract" >&2
    exit 1
  fi
done

for descending_linear_test_contract in \
  'test_linear_rejects_descending_concentration_range' \
  '("0.0", "9.0")' \
  'quality.Linear(50, 0, 9.0, 0.0, "9.0")'; do
  if ! grep -Fq "$descending_linear_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Descending AQI interpolation tests must keep contract: $descending_linear_test_contract" >&2
    exit 1
  fi
done

for descending_linear_doc in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq "Descending AQI interpolation ranges are rejected before division." \
    "$ROOT_DIR/$descending_linear_doc"; then
    printf '%s\n' "$descending_linear_doc must document descending AQI interpolation rejection." >&2
    exit 1
  fi
done

for descending_linear_plan_contract in \
  'status: completed' \
  'test_linear_rejects_descending_concentration_range' \
  '76 tests' \
  'make check' \
  'isolated hostile mutations' \
  'credential-like value audits'; do
  if ! grep -Fq "$descending_linear_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-air-quality-descending-linear-range.md"; then
    printf '%s\n' "Descending AQI interpolation plan must preserve completion evidence: $descending_linear_plan_contract" >&2
    exit 1
  fi
done

for negative_aqi_category_contract in \
  'if 0 <= AQI <= 50:' \
  'test_category_handles_negative_out_of_range_score' \
  'for score in (-1, -0.5):' \
  '"category": "Out of Range"' \
  '"caution": "None"' \
  '"score": int(score)'; do
  if ! grep -Fq "$negative_aqi_category_contract" "$ROOT_DIR/air.py" && \
     ! grep -Fq "$negative_aqi_category_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Negative AQI category handling must keep contract: $negative_aqi_category_contract" >&2
    exit 1
  fi
done

for negative_aqi_category_doc in AGENTS.md README.md SECURITY.md CHANGES.md; do
  if ! grep -Fq "Negative AQI scores are classified as Out of Range instead of Good." \
    "$ROOT_DIR/$negative_aqi_category_doc"; then
    printf '%s\n' "$negative_aqi_category_doc must document negative AQI category handling." >&2
    exit 1
  fi
done

for negative_aqi_category_plan_contract in \
  'status: completed' \
  'test_category_handles_negative_out_of_range_score' \
  '72 tests' \
  'make check' \
  'Five isolated hostile mutations' \
  'suspicious-secret audits'; do
  if ! grep -Fq "$negative_aqi_category_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-negative-aqi-category.md"; then
    printf '%s\n' "Negative AQI category plan must preserve completion evidence: $negative_aqi_category_plan_contract" >&2
    exit 1
  fi
done

for media_type_source_contract in \
  'JSON_MEDIA_TYPE_ERROR = "AIRQUALITY_DATA response must use a JSON media type"' \
  'def _require_json_media_type(content_type):' \
  'if not isinstance(content_type, str) or "," in content_type:' \
  'top_level, separator, subtype = media_type.partition("/")' \
  'top_level != "application"' \
  'subtype.endswith("+json") and len(subtype) > 5' \
  '_require_json_media_type(response.headers.get("Content-Type"))'; do
  if ! grep -Fq "$media_type_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Response media-type validation must keep contract: $media_type_source_contract" >&2
    exit 1
  fi
done

for media_type_test_contract in \
  'test_default_http_get_accepts_json_media_types_with_parameters' \
  'test_default_http_get_rejects_non_json_media_types_before_streaming' \
  'self.assertFalse(hasattr(response, "chunk_size"))'; do
  if ! grep -Fq "$media_type_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Response media-type tests must keep contract: $media_type_test_contract" >&2
    exit 1
  fi
done

media_type_line=$(grep -n '_require_json_media_type(response.headers.get("Content-Type"))' "$ROOT_DIR/air.py" | cut -d: -f1)
content_length_line=$(grep -n 'content_length = response.headers.get("Content-Length")' "$ROOT_DIR/air.py" | cut -d: -f1)
stream_line=$(grep -n 'for chunk in response.iter_content' "$ROOT_DIR/air.py" | cut -d: -f1)
if [ -z "$media_type_line" ] || [ -z "$content_length_line" ] || [ -z "$stream_line" ] || \
   [ "$media_type_line" -ge "$content_length_line" ] || [ "$media_type_line" -ge "$stream_line" ]; then
  printf '%s\n' "Response media type must be validated before length checks and streaming." >&2
  exit 1
fi

for media_type_document in "$README" "$ROOT_DIR/SECURITY.md" "$ROOT_DIR/VISION.md" "$ROOT_DIR/AGENTS.md"; do
  if ! grep -Fq 'application/*+json' "$media_type_document"; then
    printf '%s\n' "$media_type_document must document the JSON response media-type boundary." >&2
    exit 1
  fi
done

for media_type_plan_contract in \
  'status: completed' \
  '## Status: Completed' \
  'python run_tests.py` passed all 63 tests' \
  'Six isolated hostile mutations were rejected'; do
  if ! grep -Fq "$media_type_plan_contract" "$ROOT_DIR/docs/plans/2026-06-14-air-quality-response-media-type.md"; then
    printf '%s\n' "Response media-type plan must preserve completion evidence: $media_type_plan_contract" >&2
    exit 1
  fi
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
  'def _require_json_utf8_encoding(encoding):' \
  'canonical_encoding = codecs.lookup(encoding or "utf-8").name' \
  'if canonical_encoding != "utf-8":' \
  '_require_json_utf8_encoding(response.encoding)' \
  'body.decode("utf-8")' \
  'raise RuntimeError("AIRQUALITY_DATA response must be valid JSON")'; do
  if ! grep -Fq "$response_encoding_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Upstream response encoding must keep source contract: $response_encoding_source_contract" >&2
    exit 1
  fi
done

for response_encoding_test_contract in \
  'test_default_http_get_accepts_utf8_encoding_aliases' \
  'test_default_http_get_rejects_non_utf8_json_before_streaming' \
  'test_default_http_get_normalizes_unknown_encoding_and_closes_response'; do
  if ! grep -Fq "$response_encoding_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Upstream response encoding tests must keep contract: $response_encoding_test_contract" >&2
    exit 1
  fi
done

for content_length_source_contract in \
  'CONTENT_LENGTH_DIGITS = re.compile(r"^[0-9]+$")' \
  'not CONTENT_LENGTH_DIGITS.fullmatch(' \
  'parsed_content_length = int(content_length)' \
  'AIRQUALITY_DATA Content-Length must be a non-negative integer'; do
  if ! grep -Fq "$content_length_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Content-Length validation must keep source contract: $content_length_source_contract" >&2
    exit 1
  fi
done

if ! grep -Fq \
  'test_default_http_get_rejects_negative_content_length' \
  "$ROOT_DIR/air_tests.py"; then
  printf '%s\n' 'Negative Content-Length regression must remain covered.' >&2
  exit 1
fi

for strict_content_length_test_contract in \
  'test_default_http_get_rejects_non_decimal_content_length_before_streaming' \
  'test_default_http_get_accepts_ascii_decimal_content_length' \
  '"1_0"' \
  '"1, 2"' \
  '"\u0661"' \
  'str(air.UPSTREAM_RESPONSE_MAX_BYTES)'; do
  if ! grep -Fq "$strict_content_length_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "Strict Content-Length tests must keep contract: $strict_content_length_test_contract" >&2
    exit 1
  fi
done

for content_length_document in \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md"; do
  if ! grep -Fq "non-negative Content-Length" "$content_length_document"; then
    printf '%s\n' "$content_length_document must document non-negative Content-Length validation." >&2
    exit 1
  fi
done

for strict_content_length_document in \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md"; do
  if ! grep -Fq "ASCII decimal digits" "$strict_content_length_document"; then
    printf '%s\n' "$strict_content_length_document must document strict Content-Length syntax." >&2
    exit 1
  fi
done

if ! grep -Fq \
  'Status: Completed' \
  "$ROOT_DIR/docs/plans/2026-06-14-air-quality-content-length-validation.md"; then
  printf '%s\n' 'Content-Length validation plan must record completed status.' >&2
  exit 1
fi

for strict_content_length_plan_contract in \
  'Status: Completed' \
  'Full `make check` passed' \
  'isolated mutations were rejected'; do
  if ! grep -Fq "$strict_content_length_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-14-strict-content-length-syntax.md"; then
    printf '%s\n' "Strict Content-Length plan must preserve completion evidence: $strict_content_length_plan_contract" >&2
    exit 1
  fi
done

for response_encoding_document in \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md"; do
  if ! grep -Fq "unsupported response encodings" "$response_encoding_document"; then
    printf '%s\n' "$response_encoding_document must document unsupported response encodings." >&2
    exit 1
  fi
done

for json_utf8_document in \
  "$ROOT_DIR/AGENTS.md" \
  "$ROOT_DIR/README.md" \
  "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md"; do
  if ! grep -Fq "network JSON must use UTF-8" "$json_utf8_document"; then
    printf '%s\n' "$json_utf8_document must document the network JSON UTF-8 boundary." >&2
    exit 1
  fi
done

for json_utf8_plan_contract in \
  'Status: Completed' \
  'Repository and external-directory `make check` both passed' \
  'isolated hostile mutations were rejected'; do
  if ! grep -Fq "$json_utf8_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-16-air-quality-json-utf8-boundary.md"; then
    printf '%s\n' "JSON UTF-8 plan must preserve completion evidence: $json_utf8_plan_contract" >&2
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
if function.count("raise RuntimeError(GEOCODER_ERROR_MESSAGE) from None") != 2:
    raise SystemExit("Transport and malformed payload failures must use the generic RuntimeError.")
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
    raise SystemExit("Payload validation must remain outside the geocoder transport boundary before separate normalization.")
PY

for geocoder_transport_test_contract in \
  "test_geocoder_request_failure_is_normalized_without_detail" \
  "test_geocoder_json_failure_is_normalized_without_detail" \
  "test_malformed_geocoder_payloads_are_normalized_as_service_errors"; do
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

for antipodal_source_contract in \
  'a = max(0.0, min(1.0, a))' \
  'return 12742 * asin(sqrt(a))'; do
  if ! grep -Fq "$antipodal_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "Antipodal distance handling must keep contract: $antipodal_source_contract" >&2
    exit 1
  fi
done

if ! grep -Fq 'test_near_antipodal_sensor_distance_clamps_rounding_drift' "$ROOT_DIR/air_tests.py"; then
  printf '%s\n' "Air tests must cover near-antipodal distance rounding." >&2
  exit 1
fi

for antipodal_doc in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq 'Near-antipodal sensor distances clamp floating-point drift' \
    "$ROOT_DIR/$antipodal_doc"; then
    printf '%s\n' "$antipodal_doc must document near-antipodal distance clamping." >&2
    exit 1
  fi
done

for antipodal_plan_contract in \
  'status: completed' \
  'test_near_antipodal_sensor_distance_clamps_rounding_drift' \
  'make check' \
  'hostile mutations' \
  'secret and generated-artifact audits'; do
  if ! grep -Fq "$antipodal_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-15-antipodal-distance-clamp.md"; then
    printf '%s\n' "Antipodal distance plan must preserve completion evidence: $antipodal_plan_contract" >&2
    exit 1
  fi
done

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

if ! grep -Fq 'run(host=host, port=port, debug=False)' "$ROOT_DIR/app.py"; then
  printf '%s\n' "Bottle startup must disable debug mode explicitly." >&2
  exit 1
fi

if grep -Eq 'run\([^)]*debug[[:space:]]*=[[:space:]]*True' "$ROOT_DIR/app.py"; then
  printf '%s\n' "Bottle startup must not enable debug mode." >&2
  exit 1
fi

for bottle_startup_test in \
  'test_main_uses_safe_local_server_defaults' \
  'test_main_uses_safe_heroku_server_defaults' \
  'test_main_requires_bottle'; do
  if ! grep -Fq "$bottle_startup_test" "$ROOT_DIR/app_tests.py"; then
    printf '%s\n' "App tests must preserve startup contract: $bottle_startup_test" >&2
    exit 1
  fi
done

for bottle_startup_doc in AGENTS.md README.md DEPLOYMENT.md SECURITY.md VISION.md; do
  if ! grep -Fq 'Bottle debug mode is disabled by default' \
    "$ROOT_DIR/$bottle_startup_doc"; then
    printf '%s\n' "$bottle_startup_doc must document disabled Bottle debug mode." >&2
    exit 1
  fi
done

for bottle_startup_plan_contract in \
  'Status: Completed' \
  'test_main_uses_safe_local_server_defaults' \
  'test_main_uses_safe_heroku_server_defaults' \
  'repository and external-directory `make check`' \
  'hostile mutations'; do
  if ! grep -Fq "$bottle_startup_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-16-disable-bottle-debug-default.md"; then
    printf '%s\n' "Bottle startup plan must preserve completion evidence: $bottle_startup_plan_contract" >&2
    exit 1
  fi
done

for server_port_source_contract in \
  'SERVER_PORT_ERROR_MESSAGE = "invalid server port configuration"' \
  'port_text = value.strip()' \
  'not port_text.isascii()' \
  'not port_text.isdecimal()' \
  'port < 1 or port > 65535' \
  'port = _parse_server_port(os.environ.get("PORT"))'; do
  if ! grep -Fq "$server_port_source_contract" "$ROOT_DIR/app.py"; then
    printf '%s\n' "Server port validation must keep contract: $server_port_source_contract" >&2
    exit 1
  fi
done

python - "$ROOT_DIR/app.py" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
parser = source.split("def _parse_server_port(value):", 1)[1].split("\n\n@route", 1)[0]
main = source.split("def main():", 1)[1].split('\n\nif __name__ == "__main__":', 1)[0]

for token in (
    "if value is None:",
    "return 5000",
    "raise RuntimeError(SERVER_PORT_ERROR_MESSAGE)",
    "port < 1 or port > 65535",
):
    if token not in parser:
        raise SystemExit("Server port parser must retain default, error, and bounds handling.")

parse_call = 'port = _parse_server_port(os.environ.get("PORT"))'
launch_call = "run(host=host, port=port, debug=False)"
if parse_call not in main or launch_call not in main or main.index(parse_call) >= main.index(launch_call):
    raise SystemExit("Server port validation must complete before Bottle launch.")
PY

for server_port_test_contract in \
  'test_main_uses_default_heroku_port_when_unconfigured' \
  'test_main_accepts_heroku_port_boundaries' \
  'test_main_rejects_invalid_heroku_ports_before_launch' \
  'self.assertEqual(calls, [])'; do
  if ! grep -Fq "$server_port_test_contract" "$ROOT_DIR/app_tests.py"; then
    printf '%s\n' "App tests must preserve server port validation: $server_port_test_contract" >&2
    exit 1
  fi
done

for server_port_document in AGENTS.md README.md DEPLOYMENT.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fq 'Heroku listener ports are validated' "$ROOT_DIR/$server_port_document"; then
    printf '%s\n' "$server_port_document must document Heroku listener port validation." >&2
    exit 1
  fi
done

for server_port_plan_contract in \
  'status: completed' \
  'all 99 tests' \
  'Ruff formatting and lint checks passed' \
  'Python compilation completed' \
  'Repository and external-directory `make check`' \
  'Eight isolated hostile mutations were rejected'; do
  if ! grep -Fq "$server_port_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-16-server-port-validation.md"; then
    printf '%s\n' "Server port validation plan must preserve completion evidence: $server_port_plan_contract" >&2
    exit 1
  fi
done

for geocoder_payload_source_contract in \
  'class _NoGeocodingResults(ValueError):' \
  'except _NoGeocodingResults:' \
  'except ValueError:' \
  'raise RuntimeError(GEOCODER_ERROR_MESSAGE) from None'; do
  if ! grep -Fq "$geocoder_payload_source_contract" "$ROOT_DIR/geocode.py"; then
    printf '%s\n' "Geocoder payload classification must keep contract: $geocoder_payload_source_contract" >&2
    exit 1
  fi
done

python - "$ROOT_DIR/geocode.py" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
method = source.split("    def getLatLng(self):", 1)[1].split(
    "\n    def cached_data", 1
)[0]
parse_call = "data = self.parse_first_feature_center(payload)"
no_results = "except _NoGeocodingResults:"
malformed = "except ValueError:"
normalized = "raise RuntimeError(GEOCODER_ERROR_MESSAGE) from None"

if not all(token in method for token in (parse_call, no_results, malformed, normalized)):
    raise SystemExit("Geocoder payload validation must retain both error classes.")
payload_normalized_index = method.index(normalized, method.index(malformed))
if not (
    method.index(parse_call)
    < method.index(no_results)
    < method.index(malformed)
    < payload_normalized_index
):
    raise SystemExit("Geocoder payload errors must preserve no-result before malformed normalization.")
PY

for geocoder_payload_test_contract in \
  'test_invalid_center_values_are_normalized_as_service_errors' \
  'test_overflowing_geocoder_center_values_are_service_errors' \
  'test_boolean_geocoder_center_values_are_service_errors' \
  'test_missing_geocoder_results_remain_a_client_error' \
  'test_malformed_geocoder_payloads_are_normalized_as_service_errors'; do
  if ! grep -Fq "$geocoder_payload_test_contract" "$ROOT_DIR/geocode_tests.py"; then
    printf '%s\n' "Geocoder payload tests must keep contract: $geocoder_payload_test_contract" >&2
    exit 1
  fi
done

for geocoder_payload_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fiq 'malformed Mapbox' "$ROOT_DIR/$geocoder_payload_document"; then
    printf '%s\n' "$geocoder_payload_document must document malformed Mapbox service errors." >&2
    exit 1
  fi
done

for geocoder_payload_plan_contract in \
  'Status: Completed' \
  'all 96 tests' \
  'Repository and external-directory `make check`' \
  'isolated hostile mutations were rejected'; do
  if ! grep -Fq "$geocoder_payload_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-16-air-quality-geocoder-payload-errors.md"; then
    printf '%s\n' "Geocoder payload plan must preserve completion evidence: $geocoder_payload_plan_contract" >&2
    exit 1
  fi
done

for aqi_rounding_source_contract in \
  'linear = math.floor(a + 0.5)' \
  'return linear'; do
  if ! grep -Fq "$aqi_rounding_source_contract" "$ROOT_DIR/air.py"; then
    printf '%s\n' "AQI interpolation must keep half-up rounding: $aqi_rounding_source_contract" >&2
    exit 1
  fi
done

if grep -Fq 'linear = round(a)' "$ROOT_DIR/air.py"; then
  printf '%s\n' "AQI interpolation must not restore Python ties-to-even rounding." >&2
  exit 1
fi

python - "$ROOT_DIR/air.py" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
method = source.split("    def Linear(", 1)[1].split("\n    @staticmethod", 1)[0]
calculation = "a = ((Conc - Conclow) / (Conchigh - Conclow))"
rounding = "linear = math.floor(a + 0.5)"
result = "return linear"
if not all(token in method for token in (calculation, rounding, result)):
    raise SystemExit("AQI interpolation must retain calculation, half-up rounding, and return.")
if not method.index(calculation) < method.index(rounding) < method.index(result):
    raise SystemExit("AQI half-up rounding must remain after interpolation and before return.")
PY

for aqi_rounding_test_contract in \
  'test_linear_rounds_nonnegative_half_values_up' \
  'quality.Linear(1, 0, 2, 0, 1), 1' \
  'quality.Linear(3, 0, 2, 0, 1), 2'; do
  if ! grep -Fq "$aqi_rounding_test_contract" "$ROOT_DIR/air_tests.py"; then
    printf '%s\n' "AQI tests must preserve half-up rounding: $aqi_rounding_test_contract" >&2
    exit 1
  fi
done

for aqi_rounding_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fiq 'half-up integer rounding' "$ROOT_DIR/$aqi_rounding_document"; then
    printf '%s\n' "$aqi_rounding_document must document half-up AQI rounding." >&2
    exit 1
  fi
done

for aqi_rounding_plan_contract in \
  'status: completed' \
  'all 100 tests' \
  'Repository and external-directory `make check`' \
  'Five isolated hostile mutations were rejected'; do
  if ! grep -Fq "$aqi_rounding_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-16-air-quality-aqi-half-up-rounding.md"; then
    printf '%s\n' "AQI half-up rounding plan must preserve completion evidence: $aqi_rounding_plan_contract" >&2
    exit 1
  fi
done

for search_control_source_contract in \
  'import unicodedata' \
  'unicodedata.category(character) == "Cc"' \
  'raise ValueError("query must not contain control characters")'; do
  if ! grep -Fq "$search_control_source_contract" "$ROOT_DIR/app.py"; then
    printf '%s\n' "Search queries must keep control-character guard: $search_control_source_contract" >&2
    exit 1
  fi
done

python - "$ROOT_DIR/app.py" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
method = source.split("def parse_search_query(query):", 1)[1].split(
    "\n\ndef search_payload", 1
)[0]
trim = "query_string = query.strip()"
length = "if len(query_string) > SEARCH_QUERY_MAX_LENGTH:"
control = 'unicodedata.category(character) == "Cc"'
result = "return query_string"
if not all(token in method for token in (trim, length, control, result)):
    raise SystemExit("Search query validation must keep trim, length, control, and return boundaries.")
if not method.index(trim) < method.index(length) < method.index(control) < method.index(result):
    raise SystemExit("Search control validation must run after trim/length and before return.")
PY

for search_control_test_contract in \
  'test_parse_search_query_rejects_unicode_control_characters' \
  'test_rejected_control_query_does_not_construct_geocoder' \
  'test_parse_search_query_preserves_internationalized_visible_text' \
  '"San\x00Francisco"' \
  '"San\u0085Francisco"' \
  '"São Paulo 東京"'; do
  if ! grep -Fq "$search_control_test_contract" "$ROOT_DIR/app_tests.py"; then
    printf '%s\n' "Search control-character tests must keep contract: $search_control_test_contract" >&2
    exit 1
  fi
done

for search_control_document in AGENTS.md README.md SECURITY.md VISION.md CHANGES.md; do
  if ! grep -Fiq 'Unicode control characters' "$ROOT_DIR/$search_control_document"; then
    printf '%s\n' "$search_control_document must document Unicode control-character rejection." >&2
    exit 1
  fi
done

for search_control_plan_contract in \
  'status: completed' \
  'all 103 tests' \
  'Repository and external-directory `make check`' \
  'Six isolated hostile mutations were rejected'; do
  if ! grep -Fq "$search_control_plan_contract" \
    "$ROOT_DIR/docs/plans/2026-06-16-search-query-control-character-guard.md"; then
    printf '%s\n' "Search control-character plan must preserve completion evidence: $search_control_plan_contract" >&2
    exit 1
  fi
done

printf '%s\n' "air-quality baseline checks passed."
