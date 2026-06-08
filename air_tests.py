import sys
import unittest
from types import SimpleNamespace

import air
from test_helpers import JsonResponse, MemoryCache


class AirQualityTest(unittest.TestCase):
    def with_fake_requests(self, fake_requests, callback):
        sentinel = object()
        original = sys.modules.get("requests", sentinel)
        sys.modules["requests"] = fake_requests

        try:
            callback()
        finally:
            if original is sentinel:
                del sys.modules["requests"]
            else:
                sys.modules["requests"] = original

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

    def test_default_http_get_uses_bounded_timeout(self):
        calls = []
        response = object()

        def fake_get(url, timeout=None):
            calls.append((url, timeout))
            return response

        fake_requests = SimpleNamespace(
            get=fake_get,
            exceptions=SimpleNamespace(Timeout=TimeoutError),
        )

        def assertion():
            self.assertIs(
                air._default_http_get("https://example.test/air.json"), response
            )

        self.with_fake_requests(fake_requests, assertion)
        self.assertEqual(
            calls, [("https://example.test/air.json", air.HTTP_TIMEOUT)]
        )

    def test_default_http_get_wraps_request_timeouts(self):
        class FakeTimeout(Exception):
            pass

        def fake_get(_url, timeout=None):
            raise FakeTimeout("stalled")

        fake_requests = SimpleNamespace(
            get=fake_get,
            exceptions=SimpleNamespace(Timeout=FakeTimeout),
        )

        def assertion():
            with self.assertRaisesRegex(
                RuntimeError, "Timed out fetching air quality data"
            ):
                air._default_http_get("https://example.test/air.json")

        self.with_fake_requests(fake_requests, assertion)

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


if __name__ == "__main__":
    unittest.main()
