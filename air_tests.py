import unittest
import sys
from types import SimpleNamespace

import air
from test_helpers import JsonResponse, MemoryCache


class AirQualityTest(unittest.TestCase):
    def test_default_http_get_uses_timeout(self):
        calls = []
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = SimpleNamespace(
            get=lambda url, **kwargs: calls.append((url, kwargs)) or JsonResponse({})
        )

        try:
            response = air._default_http_get("https://example.test/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertIsInstance(response, JsonResponse)
        self.assertEqual(
            calls,
            [
                (
                    "https://example.test/air.json",
                    {"timeout": air.REQUEST_TIMEOUT_SECONDS},
                )
            ],
        )

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

        self.assertEqual(first, {"category": "Good", "caution": "None", "score": 50})
        self.assertEqual(second, first)
        self.assertEqual(requested_urls, ["https://example.test/air.json"])

    def test_score(self):
        a = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())
        self.assertEqual(a.AQIPM25(120), 184.0)

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
                        {"Lat": 37.79, "Lon": -122.41, "PM2_5Value": "4.0"},
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

        self.assertEqual(
            quality.getData(), {"category": "Good", "caution": "None", "score": 50}
        )

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

        self.assertEqual(
            quality.getData(), {"category": "Good", "caution": "None", "score": 50}
        )

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
                        {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"},
                    ]
                }
            ),
        )

        self.assertEqual(
            quality.getData(), {"category": "Good", "caution": "None", "score": 50}
        )


if __name__ == "__main__":
    unittest.main()
