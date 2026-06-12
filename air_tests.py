import json
import sys
import unittest
from types import SimpleNamespace

import air
from test_helpers import JsonResponse, MemoryCache

MODERATE_12_PAYLOAD = {
    "category": "Moderate",
    "caution": "Unusually sensitive people should consider reducing prolonged or heavy exertion.",
    "score": 56,
}


class AirQualityTest(unittest.TestCase):
    class StreamingResponse(object):
        def __init__(self, chunks, headers=None, encoding="utf-8", status_error=None):
            self.chunks = chunks
            self.headers = headers or {}
            self.encoding = encoding
            self.status_error = status_error
            self.status_checked = False
            self.close_calls = 0

        def raise_for_status(self):
            self.status_checked = True
            if self.status_error is not None:
                raise self.status_error

        def iter_content(self, chunk_size):
            self.chunk_size = chunk_size
            return iter(self.chunks)

        def close(self):
            self.close_calls += 1

    def test_upstream_response_limit_is_one_mebibyte(self):
        self.assertEqual(air.UPSTREAM_RESPONSE_MAX_BYTES, 1024 * 1024)

    def test_cache_key_versions_current_epa_breakpoints(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())

        self.assertEqual(quality.cache_key(), "a_q_2_37.794678_-122.41143")

    def test_default_http_get_uses_timeout(self):
        calls = []
        streaming_response = self.StreamingResponse([b'{"results": []}'])
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = SimpleNamespace(
            get=lambda url, **kwargs: calls.append((url, kwargs)) or streaming_response
        )

        try:
            payload = air._default_http_get("https://example.test/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(payload, {"results": []})
        self.assertEqual(
            calls,
            [
                (
                    "https://example.test/air.json",
                    {"timeout": air.REQUEST_TIMEOUT_SECONDS, "stream": True},
                )
            ],
        )
        self.assertTrue(streaming_response.status_checked)
        self.assertEqual(streaming_response.chunk_size, 64 * 1024)
        self.assertEqual(streaming_response.close_calls, 1)

    def test_default_http_get_rejects_oversized_streamed_responses(self):
        response = self.StreamingResponse(
            [b"x" * air.UPSTREAM_RESPONSE_MAX_BYTES, b"x"]
        )
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = SimpleNamespace(get=lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(RuntimeError, "response is too large"):
                air._default_http_get("https://example.test/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_oversized_content_length(self):
        response = self.StreamingResponse(
            [], headers={"Content-Length": str(air.UPSTREAM_RESPONSE_MAX_BYTES + 1)}
        )
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = SimpleNamespace(get=lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(RuntimeError, "response is too large"):
                air._default_http_get("https://example.test/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_closes_response_after_status_failure(self):
        response = self.StreamingResponse([], status_error=OSError("upstream failed"))
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = SimpleNamespace(get=lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(OSError, "upstream failed"):
                air._default_http_get("https://example.test/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_closes_response_after_invalid_json(self):
        response = self.StreamingResponse([b"not-json"])
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = SimpleNamespace(get=lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(RuntimeError, "must be valid JSON"):
                air._default_http_get("https://example.test/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_getting_data_uses_nearest_valid_sensor_and_caches_it(self):
        cache = MemoryCache()
        requested_urls = []

        def http_get(url):
            requested_urls.append(url)
            return JsonResponse(
                {
                    "results": [
                        {"Lat": 50.0, "Lon": -120.0, "PM2_5Value": "80"},
                        {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"},
                        {"Lat": 37.79, "Lon": -122.41, "PM2_5Value": "4.0"},
                        {"Lat": None, "Lon": -122.41, "PM2_5Value": "25.0"},
                    ]
                }
            )

        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=cache,
            data_url="https://example.test/air.json",
            http_get=http_get,
        )

        first = quality.getData()
        second = quality.getData()

        self.assertEqual(first, {"category": "Good", "caution": "None", "score": 22})
        self.assertEqual(second, first)
        self.assertEqual(requested_urls, ["https://example.test/air.json"])

    def test_corrupt_cached_data_is_ignored_and_refreshed(self):
        invalid_cached_values = [
            "not-json",
            json.dumps(["not", "an", "air-quality", "payload"]),
            json.dumps({"category": "Good"}),
            json.dumps({"category": 42, "caution": "None", "score": 50}),
            json.dumps({"category": "Good", "caution": None, "score": 50}),
            json.dumps({"category": "Good", "caution": "None", "score": "50"}),
            json.dumps({"category": "Good", "caution": "None", "score": True}),
            json.dumps({"category": "Good", "caution": "None", "score": float("nan")}),
            json.dumps({"category": "Good", "caution": "None", "score": -1}),
            json.dumps({"category": "Good", "caution": "None", "score": 50.5}),
        ]

        for cached_value in invalid_cached_values:
            with self.subTest(cached_value=cached_value):
                cache = MemoryCache()
                requested_urls = []
                quality = air.AirQuality(
                    37.794678,
                    -122.41143,
                    cache_client=cache,
                    data_url="https://example.test/air.json",
                    http_get=lambda url: (
                        requested_urls.append(url)
                        or JsonResponse(
                            {
                                "results": [
                                    {
                                        "Lat": 37.8,
                                        "Lon": -122.41,
                                        "PM2_5Value": "12.0",
                                    }
                                ]
                            }
                        )
                    ),
                )
                cache.set(quality.cache_key(), cached_value)

                refreshed = quality.getData()

                self.assertEqual(refreshed, MODERATE_12_PAYLOAD)
                self.assertEqual(requested_urls, ["https://example.test/air.json"])
                self.assertEqual(cache.decoded(quality.cache_key()), refreshed)

    def test_valid_cached_data_is_normalized_without_fetching(self):
        cache = MemoryCache()
        quality = air.AirQuality(37.794678, -122.41143, cache_client=cache)
        cache.set(
            quality.cache_key(),
            json.dumps(
                {
                    "category": "Good",
                    "caution": "None",
                    "score": 50.0,
                    "raw_provider_payload": {"do": "not return"},
                }
            ),
        )

        self.assertEqual(
            quality.getData(), {"category": "Good", "caution": "None", "score": 50}
        )

    def test_score_uses_current_epa_breakpoints(self):
        a = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())
        expected_scores = {
            0.0: 0,
            9.0: 50,
            9.1: 51,
            35.4: 100,
            35.5: 101,
            55.4: 150,
            55.5: 151,
            125.4: 200,
            125.5: 201,
            225.4: 300,
            225.5: 301,
            325.4: 500,
            400.0: 500,
        }

        for concentration, expected_score in expected_scores.items():
            with self.subTest(concentration=concentration):
                self.assertEqual(a.AQIPM25(concentration), expected_score)

    def test_score_rejects_negative_and_nonfinite_concentrations(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())

        for concentration in (-0.1, float("nan"), float("inf")):
            with self.subTest(concentration=concentration):
                with self.assertRaises(ValueError):
                    quality.AQIPM25(concentration)

    def test_category(self):
        d = air.AirQuality.AQICategory(120)
        self.assertIsNotNone(d)
        self.assertIsNotNone(d["category"])
        self.assertEqual(d["category"], "Unhealthy for Sensitive Groups")

    def test_category_handles_out_of_range_score(self):
        self.assertEqual(
            air.AirQuality.AQICategory(501),
            {"category": "Out of Range", "caution": "None", "score": 501},
        )

    def test_no_valid_sensor_raises_value_error(self):
        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: JsonResponse(
                {
                    "results": [
                        {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": ""},
                        {"Lat": 37.79, "Lon": -122.41, "PM2_5Value": "-0.1"},
                    ]
                }
            ),
        )

        with self.assertRaises(ValueError):
            quality.getData()

    def test_missing_results_list_raises_runtime_error(self):
        invalid_payloads = [
            {},
            {"results": None},
            {"results": {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"}},
        ]

        for payload in invalid_payloads:
            with self.subTest(payload=payload):
                quality = air.AirQuality(
                    37.794678,
                    -122.41143,
                    cache_client=MemoryCache(),
                    data_url="https://example.test/air.json",
                    http_get=lambda _url, payload=payload: JsonResponse(payload),
                )

                with self.assertRaises(RuntimeError):
                    quality.getData()

    def test_malformed_result_items_are_ignored(self):
        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: JsonResponse(
                {
                    "results": [
                        "not-a-reading",
                        ["also", "not", "a", "reading"],
                        {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"},
                    ]
                }
            ),
        )

        self.assertEqual(quality.getData(), MODERATE_12_PAYLOAD)

    def test_zero_coordinate_sensor_is_valid(self):
        quality = air.AirQuality(
            0,
            0,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: JsonResponse(
                {"results": [{"Lat": 0.0, "Lon": 0.0, "PM2_5Value": "12.0"}]}
            ),
        )

        self.assertEqual(quality.getData(), MODERATE_12_PAYLOAD)

    def test_nonfinite_sensor_values_are_ignored(self):
        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: JsonResponse(
                {
                    "results": [
                        {"Lat": "inf", "Lon": -122.41, "PM2_5Value": "12.0"},
                        {"Lat": 37.8, "Lon": "nan", "PM2_5Value": "12.0"},
                        {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "nan"},
                        {"Lat": 91, "Lon": -122.41, "PM2_5Value": "12.0"},
                        {"Lat": 37.8, "Lon": -181, "PM2_5Value": "12.0"},
                        {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"},
                    ]
                }
            ),
        )

        self.assertEqual(quality.getData(), MODERATE_12_PAYLOAD)


if __name__ == "__main__":
    unittest.main()
