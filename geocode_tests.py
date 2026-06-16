import unittest
import json
import math
import os
import sys
from types import ModuleType
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
    def test_default_geocoder_uses_permanent_dataset_before_caching(self):
        events = []
        payload = {"features": [{"center": [-122.41143, 37.794678]}]}

        class RecordingCache(MemoryCache):
            def set(self, key, value):
                events.append(("cache", key, json.loads(value)))
                super().set(key, value)

        class RecordingSession(object):
            def __init__(self):
                self.params = {"access_token": "configured"}
                self.headers = {"User-Agent": "mapbox-sdk-py/test"}

            def get(self, url, **kwargs):
                events.append(("request", url, kwargs))
                return JsonResponse(payload)

        class RecordingGeocoder(object):
            def __init__(self):
                self.session = RecordingSession()

            def forward(self, query):
                events.append(("forward", query))
                return self.session.get(
                    "https://api.mapbox.com/geocoding/v5", params={"query": query}
                )

        geocoder = RecordingGeocoder()
        original_session = geocoder.session
        mapbox = ModuleType("mapbox")

        def geocoder_factory(**kwargs):
            events.append(("construct", kwargs))
            return geocoder

        mapbox.Geocoder = geocoder_factory
        cache = RecordingCache()

        with patch.dict(sys.modules, {"mapbox": mapbox}):
            result = GeoCode("San Francisco, CA", cache_client=cache).getLatLng()

        self.assertEqual(result, {"lat": 37.794678, "lng": -122.41143})
        self.assertEqual(
            events,
            [
                ("construct", {"name": "mapbox.places-permanent"}),
                ("forward", "San Francisco, CA"),
                (
                    "request",
                    "https://api.mapbox.com/geocoding/v5",
                    {"params": {"query": "San Francisco, CA"}, "timeout": 5.0},
                ),
                (
                    "cache",
                    "geocode_query_1_San Francisco, CA",
                    {"lat": 37.794678, "lng": -122.41143},
                ),
            ],
        )
        self.assertIs(geocoder.session.params, original_session.params)
        self.assertIs(geocoder.session.headers, original_session.headers)
        self.assertEqual(
            cache.decoded("geocode_query_1_San Francisco, CA"),
            {"lat": 37.794678, "lng": -122.41143},
        )

    def test_injected_geocoder_session_is_not_wrapped(self):
        geocoder = FakeGeocoder({"features": [{"center": [-122.41143, 37.794678]}]})
        session = object()
        geocoder.session = session
        geo = GeoCode(
            "San Francisco, CA", cache_client=MemoryCache(), geocoder=geocoder
        )

        self.assertEqual(geo.getLatLng(), {"lat": 37.794678, "lng": -122.41143})
        self.assertIs(geo.geocoder_client(), geocoder)
        self.assertIs(geocoder.session, session)

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

    def test_fresh_geocoder_center_canonicalizes_and_caches_signed_zero(self):
        signed_zero_values = [0.0, -0.0, "0", "-0", "0.0", "-0.0"]

        for value in signed_zero_values:
            with self.subTest(value=value):
                cache = MemoryCache()
                geocoder = FakeGeocoder({"features": [{"center": [value, value]}]})
                geo = GeoCode("Zero", cache_client=cache, geocoder=geocoder)

                result = geo.getLatLng()
                cached = cache.decoded("geocode_query_1_Zero")

                self.assertEqual(result, {"lat": 0.0, "lng": 0.0})
                self.assertEqual(math.copysign(1.0, result["lat"]), 1.0)
                self.assertEqual(math.copysign(1.0, result["lng"]), 1.0)
                self.assertEqual(math.copysign(1.0, cached["lat"]), 1.0)
                self.assertEqual(math.copysign(1.0, cached["lng"]), 1.0)

    def test_cached_geocoder_coordinates_canonicalize_signed_zero(self):
        cache = MemoryCache()
        key = "geocode_query_1_Zero"
        cache.set(key, json.dumps({"lat": -0.0, "lng": -0.0}))
        geocoder = FakeGeocoder({"features": [{"center": [1.0, 1.0]}]})
        geo = GeoCode("Zero", cache_client=cache, geocoder=geocoder)

        result = geo.getLatLng()

        self.assertEqual(result, {"lat": 0.0, "lng": 0.0})
        self.assertEqual(math.copysign(1.0, result["lat"]), 1.0)
        self.assertEqual(math.copysign(1.0, result["lng"]), 1.0)
        self.assertEqual(math.copysign(1.0, cache.decoded(key)["lat"]), 1.0)
        self.assertEqual(math.copysign(1.0, cache.decoded(key)["lng"]), 1.0)
        self.assertEqual(geocoder.queries, [])

    def test_signed_zero_cache_repair_failure_is_normalized(self):
        class FailingRepairCache(MemoryCache):
            def set(self, key, value):
                raise RuntimeError("redis://user:secret@example.test unavailable")

        cache = FailingRepairCache()
        key = "geocode_query_1_Zero"
        cache.values[key] = json.dumps({"lat": -0.0, "lng": -0.0})
        geocoder = FakeGeocoder({"features": [{"center": [1.0, 1.0]}]})
        geo = GeoCode("Zero", cache_client=cache, geocoder=geocoder)

        with self.assertRaisesRegex(RuntimeError, "^cache request failed$") as raised:
            geo.getLatLng()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(geocoder.queries, [])

    def test_positive_zero_cache_hit_does_not_rewrite(self):
        class RewriteRejectingCache(MemoryCache):
            def set(self, key, value):
                raise AssertionError("canonical cache hit must not be rewritten")

        cache = RewriteRejectingCache()
        key = "geocode_query_1_Zero"
        cache.values[key] = json.dumps({"lat": 0.0, "lng": 0.0})
        geocoder = FakeGeocoder({"features": [{"center": [1.0, 1.0]}]})
        geo = GeoCode("Zero", cache_client=cache, geocoder=geocoder)

        self.assertEqual(geo.getLatLng(), {"lat": 0.0, "lng": 0.0})
        self.assertEqual(geocoder.queries, [])

    def test_cached_numeric_strings_are_rewritten_as_canonical_numbers(self):
        cached_values = [
            (
                {"lat": "37.794678", "lng": -122.41143},
                {"lat": 37.794678, "lng": -122.41143},
            ),
            (
                {"lat": 37.794678, "lng": "-122.41143"},
                {"lat": 37.794678, "lng": -122.41143},
            ),
            (
                {"lat": "37.794678", "lng": "-122.41143"},
                {"lat": 37.794678, "lng": -122.41143},
            ),
            ({"lat": "-0.0", "lng": "0.0"}, {"lat": 0.0, "lng": 0.0}),
        ]

        for cached_value, expected in cached_values:
            with self.subTest(cached_value=cached_value):
                cache = MemoryCache()
                key = "geocode_query_1_Canonical"
                cache.set(key, json.dumps(cached_value))
                geocoder = FakeGeocoder({"features": [{"center": [1.0, 1.0]}]})
                geo = GeoCode("Canonical", cache_client=cache, geocoder=geocoder)

                result = geo.getLatLng()
                cached = cache.decoded(key)

                self.assertEqual(result, expected)
                self.assertEqual(cached, expected)
                self.assertIsInstance(cached["lat"], float)
                self.assertIsInstance(cached["lng"], float)
                if cached["lat"] == 0.0:
                    self.assertEqual(math.copysign(1.0, cached["lat"]), 1.0)
                if cached["lng"] == 0.0:
                    self.assertEqual(math.copysign(1.0, cached["lng"]), 1.0)
                self.assertEqual(geocoder.queries, [])

    def test_canonical_numeric_cache_hit_does_not_rewrite(self):
        class RewriteRejectingCache(MemoryCache):
            def set(self, key, value):
                if key in self.values:
                    raise AssertionError(
                        "canonical numeric cache hit must not be rewritten"
                    )
                super().set(key, value)

        for cached_value in (
            {"lat": 37, "lng": -122},
            {"lat": 37.794678, "lng": -122.41143},
        ):
            with self.subTest(cached_value=cached_value):
                cache = RewriteRejectingCache()
                key = "geocode_query_1_Canonical"
                cache.values[key] = json.dumps(cached_value)
                geocoder = FakeGeocoder({"features": [{"center": [1.0, 1.0]}]})

                result = GeoCode(
                    "Canonical", cache_client=cache, geocoder=geocoder
                ).getLatLng()

                self.assertEqual(result, cached_value)
                self.assertIsInstance(result["lat"], float)
                self.assertIsInstance(result["lng"], float)
                self.assertEqual(geocoder.queries, [])

    def test_numeric_string_cache_repair_failure_is_normalized(self):
        class FailingRepairCache(MemoryCache):
            def set(self, key, value):
                raise RuntimeError("redis://user:secret@example.test unavailable")

        cache = FailingRepairCache()
        key = "geocode_query_1_Canonical"
        cache.values[key] = json.dumps({"lat": "37.794678", "lng": "-122.41143"})
        geocoder = FakeGeocoder({"features": [{"center": [1.0, 1.0]}]})
        geo = GeoCode("Canonical", cache_client=cache, geocoder=geocoder)

        with self.assertRaisesRegex(RuntimeError, "^cache request failed$") as raised:
            geo.getLatLng()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(geocoder.queries, [])

    def test_corrupt_cached_geocode_is_ignored_and_refreshed(self):
        invalid_cached_values = [
            "not-json",
            json.dumps(["not", "a", "coordinate"]),
            json.dumps({"lat": 37.794678}),
            json.dumps({"lat": "nan", "lng": -122.41143}),
            json.dumps({"lat": 91, "lng": -122.41143}),
            json.dumps({"lat": 10**400, "lng": -122.41143}),
            json.dumps({"lat": 37.794678, "lng": 10**400}),
            json.dumps({"lat": True, "lng": -122.41143}),
            json.dumps({"lat": 37.794678, "lng": False}),
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

    def test_invalid_center_values_are_normalized_as_service_errors(self):
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

                with self.assertRaisesRegex(
                    RuntimeError, "^geocoder request failed$"
                ) as raised:
                    geo.getLatLng()

                self.assertIsNone(raised.exception.__cause__)

    def test_overflowing_geocoder_center_values_are_service_errors(self):
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
                    RuntimeError, "^geocoder request failed$"
                ) as raised:
                    geo.getLatLng()

                self.assertIsNone(raised.exception.__cause__)

    def test_boolean_geocoder_center_values_are_service_errors(self):
        invalid_centers = [
            [True, "37.794678"],
            ["-122.41143", False],
        ]

        for center in invalid_centers:
            with self.subTest(center=center):
                geo = GeoCode(
                    "Boolean coordinates",
                    cache_client=MemoryCache(),
                    geocoder=FakeGeocoder({"features": [{"center": center}]}),
                )

                with self.assertRaisesRegex(
                    RuntimeError, "^geocoder request failed$"
                ) as raised:
                    geo.getLatLng()

                self.assertIsNone(raised.exception.__cause__)

    def test_missing_geocoder_results_remain_a_client_error(self):
        geo = GeoCode(
            "Not a real place",
            cache_client=MemoryCache(),
            geocoder=FakeGeocoder({"features": []}),
        )

        with self.assertRaisesRegex(
            ValueError, "^No geocoding results were returned$"
        ) as raised:
            geo.getLatLng()

        self.assertNotIsInstance(raised.exception, RuntimeError)

    def test_malformed_geocoder_payloads_are_normalized_as_service_errors(self):
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

                with self.assertRaisesRegex(
                    RuntimeError, "^geocoder request failed$"
                ) as raised:
                    geo.getLatLng()

                self.assertIsNone(raised.exception.__cause__)
                self.assertNotIn("Malformed place", str(raised.exception))


if __name__ == "__main__":
    unittest.main()
