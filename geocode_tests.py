import unittest
import json
import os
from unittest.mock import patch

from geocode import GeoCode
from test_helpers import FailingCache, JsonResponse, MemoryCache


class FakeGeocoder(object):
    def __init__(self, payload):
        self.payload = payload
        self.queries = []

    def forward(self, query):
        self.queries.append(query)
        return JsonResponse(self.payload)


class FailingGeocoder(object):
    def __init__(self, error):
        self.error = error
        self.queries = []

    def forward(self, query):
        self.queries.append(query)
        raise self.error


class InvalidJsonGeocoder(object):
    def __init__(self):
        self.queries = []

    def forward(self, query):
        self.queries.append(query)

        class InvalidJsonResponse(object):
            def json(self):
                raise ValueError("private Mapbox response detail")

        return InvalidJsonResponse()


class GeoCodeTest(unittest.TestCase):
    def test_geocoder_request_failure_is_normalized_without_detail(self):
        geocoder = FailingGeocoder(
            ConnectionError("private Mapbox token and transport detail")
        )
        geo = GeoCode(
            "San Francisco, CA", cache_client=MemoryCache(), geocoder=geocoder
        )

        with self.assertRaisesRegex(
            RuntimeError, "^geocoder request failed$"
        ) as raised:
            geo.getLatLng()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("private", str(raised.exception))
        self.assertEqual(geocoder.queries, ["San Francisco, CA"])

    def test_geocoder_json_failure_is_normalized_without_detail(self):
        geocoder = InvalidJsonGeocoder()
        geo = GeoCode(
            "San Francisco, CA", cache_client=MemoryCache(), geocoder=geocoder
        )

        with self.assertRaisesRegex(
            RuntimeError, "^geocoder request failed$"
        ) as raised:
            geo.getLatLng()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("private", str(raised.exception))
        self.assertEqual(geocoder.queries, ["San Francisco, CA"])

    def test_cache_read_failure_is_normalized_before_geocoder_request(self):
        cache = FailingCache("get")
        geocoder = FakeGeocoder({"features": [{"center": [-122.41143, 37.794678]}]})
        geo = GeoCode("San Francisco, CA", cache_client=cache, geocoder=geocoder)

        with self.assertRaisesRegex(RuntimeError, "^cache request failed$") as raised:
            geo.getLatLng()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(geocoder.queries, [])
        self.assertEqual(cache.calls, [("get", ("geocode_query_1_San Francisco, CA",))])

    def test_missing_cache_configuration_remains_a_configuration_error(self):
        geo = GeoCode("San Francisco, CA")

        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(
                RuntimeError, "^REDIS_URL must be set when geocode is not cached$"
            ):
                geo.getLatLng()

    def test_cache_write_failure_is_normalized_after_valid_geocoder_response(self):
        cache = FailingCache("set")
        geocoder = FakeGeocoder({"features": [{"center": [-122.41143, 37.794678]}]})
        geo = GeoCode("San Francisco, CA", cache_client=cache, geocoder=geocoder)

        with self.assertRaisesRegex(RuntimeError, "^cache request failed$") as raised:
            geo.getLatLng()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(geocoder.queries, ["San Francisco, CA"])
        self.assertEqual([command for command, _args in cache.calls], ["get", "set"])

    def test_check_center_uses_first_mapbox_feature_and_caches_response(self):
        cache = MemoryCache()
        geocoder = FakeGeocoder({"features": [{"center": [-122.41143, 37.794678]}]})

        geo = GeoCode("San Francisco, CA", cache_client=cache, geocoder=geocoder)

        first = geo.getLatLng()
        second = geo.getLatLng()

        self.assertEqual(first, {"lat": 37.794678, "lng": -122.41143})
        self.assertEqual(second, first)
        self.assertEqual(geocoder.queries, ["San Francisco, CA"])

    def test_check_center_accepts_numeric_string_values(self):
        cache = MemoryCache()
        geocoder = FakeGeocoder({"features": [{"center": ["-122.41143", "37.794678"]}]})

        geo = GeoCode("San Francisco, CA", cache_client=cache, geocoder=geocoder)

        self.assertEqual(geo.getLatLng(), {"lat": 37.794678, "lng": -122.41143})

    def test_corrupt_cached_geocode_is_ignored_and_refreshed(self):
        invalid_cached_values = [
            "not-json",
            json.dumps(["not", "a", "coordinate"]),
            json.dumps({"lat": 37.794678}),
            json.dumps({"lat": "nan", "lng": -122.41143}),
            json.dumps({"lat": 91, "lng": -122.41143}),
        ]

        for cached_value in invalid_cached_values:
            with self.subTest(cached_value=cached_value):
                cache = MemoryCache()
                geocoder = FakeGeocoder(
                    {"features": [{"center": [-122.41143, 37.794678]}]}
                )
                geo = GeoCode(
                    "San Francisco, CA", cache_client=cache, geocoder=geocoder
                )
                key = "geocode_query_1_San Francisco, CA"
                cache.set(key, cached_value)

                refreshed = geo.getLatLng()

                self.assertEqual(refreshed, {"lat": 37.794678, "lng": -122.41143})
                self.assertEqual(geocoder.queries, ["San Francisco, CA"])
                self.assertEqual(cache.decoded(key), refreshed)

    def test_center_must_be_finite_and_in_coordinate_bounds(self):
        invalid_centers = [
            ["nan", "37.794678"],
            ["-122.41143", "inf"],
            ["-181", "37.794678"],
            ["-122.41143", "91"],
        ]

        for center in invalid_centers:
            with self.subTest(center=center):
                geo = GeoCode(
                    "Invalid coordinates",
                    cache_client=MemoryCache(),
                    geocoder=FakeGeocoder({"features": [{"center": center}]}),
                )

                with self.assertRaises(ValueError):
                    geo.getLatLng()

    def test_overflowing_geocoder_center_values_raise_value_error(self):
        huge_integer = 10**400
        invalid_centers = [
            [huge_integer, "37.794678"],
            ["-122.41143", huge_integer],
        ]

        for center in invalid_centers:
            with self.subTest(center=center):
                geo = GeoCode(
                    "Overflowing coordinates",
                    cache_client=MemoryCache(),
                    geocoder=FakeGeocoder({"features": [{"center": center}]}),
                )

                with self.assertRaisesRegex(
                    ValueError, "^geocoder center values must be numeric$"
                ):
                    geo.getLatLng()

    def test_missing_geocoder_results_raise_value_error(self):
        geo = GeoCode(
            "Not a real place",
            cache_client=MemoryCache(),
            geocoder=FakeGeocoder({"features": []}),
        )

        with self.assertRaises(ValueError):
            geo.getLatLng()

    def test_malformed_geocoder_payloads_raise_value_error(self):
        invalid_payloads = [
            None,
            [],
            {"features": None},
            {"features": {}},
            {"features": ["not-a-feature"]},
            {"features": [{"center": None}]},
            {"features": [{"center": []}]},
            {"features": [{"center": ["-122.41143"]}]},
            {"features": [{"center": ["not-lng", "37.794678"]}]},
            {"features": [{"center": ["-122.41143", "not-lat"]}]},
        ]

        for payload in invalid_payloads:
            with self.subTest(payload=payload):
                geo = GeoCode(
                    "Malformed place",
                    cache_client=MemoryCache(),
                    geocoder=FakeGeocoder(payload),
                )

                with self.assertRaises(ValueError):
                    geo.getLatLng()


if __name__ == "__main__":
    unittest.main()
