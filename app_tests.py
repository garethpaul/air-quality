import json
import math
import unittest
from types import SimpleNamespace
from unittest.mock import patch

import app as app_module
from air import AirQuality
from app import (
    SEARCH_QUERY_MAX_LENGTH,
    air_quality_payload,
    parse_coordinate,
    parse_search_query,
    search_payload,
)
from test_helpers import MemoryCache


class FakeAirQuality(object):
    calls = []

    def __init__(self, lat, lng):
        self.lat = lat
        self.lng = lng
        FakeAirQuality.calls.append((lat, lng))

    def getData(self):
        return {"category": "Good", "caution": "None", "score": 42}


class FakeGeoCode(object):
    calls = []

    def __init__(self, query):
        self.query = query
        FakeGeoCode.calls.append(query)

    def getLatLng(self):
        return {"lat": 37.7749, "lng": -122.4194}


class AppRouteHelperTest(unittest.TestCase):
    def setUp(self):
        FakeAirQuality.calls = []
        FakeGeoCode.calls = []

    def test_parse_coordinate_accepts_valid_lat_lng(self):
        self.assertEqual(parse_coordinate("37.7749", "lat"), 37.7749)
        self.assertEqual(parse_coordinate("-122.4194", "lng"), -122.4194)

    def test_parse_coordinate_canonicalizes_signed_zero(self):
        for value in (0.0, -0.0, "0", "-0", "0.0", "-0.0"):
            for name in ("lat", "lng"):
                with self.subTest(value=value, name=name):
                    coordinate = parse_coordinate(value, name)

                    self.assertEqual(coordinate, 0.0)
                    self.assertEqual(math.copysign(1.0, coordinate), 1.0)

    def test_parse_coordinate_rejects_missing_non_numeric_and_out_of_range(self):
        invalid_values = [
            (None, "lat"),
            ("", "lat"),
            ("not-a-number", "lat"),
            ("nan", "lat"),
            ("inf", "lng"),
            ("91", "lat"),
            ("-181", "lng"),
        ]

        for value, name in invalid_values:
            with self.subTest(value=value, name=name):
                with self.assertRaises(ValueError):
                    parse_coordinate(value, name)

    def test_parse_coordinate_rejects_boolean_and_overflowing_numeric_values(self):
        invalid_values = [
            (True, "lat"),
            (False, "lat"),
            (True, "lng"),
            (False, "lng"),
            (10**400, "lat"),
            (-(10**400), "lng"),
        ]

        for value, name in invalid_values:
            with self.subTest(value=value, name=name):
                with self.assertRaisesRegex(
                    ValueError, "^{0} must be a number$".format(name)
                ):
                    parse_coordinate(value, name)

    def test_rejected_coordinate_types_do_not_construct_air_quality(self):
        invalid_coordinates = [
            (True, "-122.4194"),
            ("37.7749", False),
            (10**400, "-122.4194"),
            ("37.7749", -(10**400)),
        ]

        for lat, lng in invalid_coordinates:
            with self.subTest(lat=lat, lng=lng):
                with self.assertRaises(ValueError):
                    air_quality_payload(lat, lng, air_quality_factory=FakeAirQuality)

        self.assertEqual(FakeAirQuality.calls, [])

    def test_air_quality_payload_uses_validated_coordinates(self):
        payload = air_quality_payload(
            "37.7749", "-122.4194", air_quality_factory=FakeAirQuality
        )

        self.assertEqual(payload, {"category": "Good", "caution": "None", "score": 42})
        self.assertEqual(FakeAirQuality.calls, [(37.7749, -122.4194)])

    def test_air_quality_payload_passes_canonical_zero_coordinates(self):
        payload = air_quality_payload("-0.0", -0.0, air_quality_factory=FakeAirQuality)

        self.assertEqual(payload, {"category": "Good", "caution": "None", "score": 42})
        self.assertEqual(FakeAirQuality.calls, [(0.0, 0.0)])
        self.assertEqual(math.copysign(1.0, FakeAirQuality.calls[0][0]), 1.0)
        self.assertEqual(math.copysign(1.0, FakeAirQuality.calls[0][1]), 1.0)

    def test_search_payload_trims_query_and_uses_geocode_result(self):
        payload = search_payload(
            "  San Francisco  ",
            geocode_factory=FakeGeoCode,
            air_quality_factory=FakeAirQuality,
        )

        self.assertEqual(payload, {"category": "Good", "caution": "None", "score": 42})
        self.assertEqual(FakeGeoCode.calls, ["San Francisco"])
        self.assertEqual(FakeAirQuality.calls, [(37.7749, -122.4194)])

    def test_parse_search_query_rejects_missing_empty_non_string_and_long_query(self):
        invalid_queries = [
            None,
            "   ",
            94105,
            ["San Francisco"],
            "a" * (SEARCH_QUERY_MAX_LENGTH + 1),
        ]

        for query in invalid_queries:
            with self.subTest(query=query):
                with self.assertRaises(ValueError):
                    parse_search_query(query)

        self.assertEqual(FakeGeoCode.calls, [])

    def test_parse_search_query_accepts_max_length_trimmed_text(self):
        query = " " + ("a" * SEARCH_QUERY_MAX_LENGTH) + " "

        self.assertEqual(parse_search_query(query), "a" * SEARCH_QUERY_MAX_LENGTH)

    def test_parse_search_query_rejects_unicode_control_characters(self):
        for query in ("San\x00Francisco", "San\nFrancisco", "San\u0085Francisco"):
            with self.subTest(query=repr(query)):
                with self.assertRaisesRegex(
                    ValueError, "^query must not contain control characters$"
                ):
                    parse_search_query(query)

    def test_rejected_control_query_does_not_construct_geocoder(self):
        with self.assertRaisesRegex(
            ValueError, "^query must not contain control characters$"
        ):
            search_payload(
                "San\x00Francisco",
                geocode_factory=FakeGeoCode,
                air_quality_factory=FakeAirQuality,
            )

        self.assertEqual(FakeGeoCode.calls, [])
        self.assertEqual(FakeAirQuality.calls, [])

    def test_parse_search_query_preserves_internationalized_visible_text(self):
        self.assertEqual(parse_search_query("  São Paulo 東京  "), "São Paulo 東京")

    def test_parse_search_query_normalizes_canonical_unicode(self):
        self.assertEqual(parse_search_query("  Cafe\u0301  "), "Café")

    def test_search_payload_uses_normalized_query(self):
        search_payload(
            "Cafe\u0301",
            geocode_factory=FakeGeoCode,
            air_quality_factory=FakeAirQuality,
        )

        self.assertEqual(FakeGeoCode.calls, ["Café"])

    def test_show_data_does_not_expose_exception_details(self):
        cases = [
            (ValueError("private validation detail"), 400, "invalid request"),
            (
                RuntimeError("AIRQUALITY_DATA=https://secret"),
                503,
                "service unavailable",
            ),
        ]

        for error, expected_status, expected_message in cases:
            with self.subTest(error=type(error).__name__):
                fake_response = SimpleNamespace(status=None, content_type=None)
                fake_request = SimpleNamespace(query={"lat": "1", "lng": "2"})
                with (
                    patch.object(app_module, "response", fake_response),
                    patch.object(app_module, "request", fake_request),
                    patch.object(app_module, "air_quality_payload", side_effect=error),
                ):
                    payload = json.loads(app_module.show_data())

                self.assertEqual(fake_response.status, expected_status)
                self.assertEqual(payload, {"error": expected_message})
                self.assertNotIn(str(error), json.dumps(payload))

    def test_show_data_classifies_upstream_json_failure_as_service_unavailable(self):
        class BrokenJsonResponse(object):
            def json(self):
                raise ValueError("provider payload contained account detail")

        def air_quality_factory(lat, lng):
            return AirQuality(
                lat,
                lng,
                cache_client=MemoryCache(),
                data_url="https://example.test/air.json",
                http_get=lambda _url: BrokenJsonResponse(),
            )

        def upstream_payload(lat, lng):
            return air_quality_payload(
                lat, lng, air_quality_factory=air_quality_factory
            )

        fake_response = SimpleNamespace(status=None, content_type=None)
        fake_request = SimpleNamespace(query={"lat": "37.7749", "lng": "-122.4194"})
        with (
            patch.object(app_module, "response", fake_response),
            patch.object(app_module, "request", fake_request),
            patch.object(
                app_module, "air_quality_payload", side_effect=upstream_payload
            ),
        ):
            payload = json.loads(app_module.show_data())

        self.assertEqual(fake_response.status, 503)
        self.assertEqual(payload, {"error": "service unavailable"})
        self.assertNotIn("account detail", json.dumps(payload))

    def test_search_does_not_expose_exception_details(self):
        cases = [
            (ValueError("private geocoder detail"), 400, "invalid request"),
            (RuntimeError("REDIS_URL=redis://secret"), 503, "service unavailable"),
        ]

        for error, expected_status, expected_message in cases:
            with self.subTest(error=type(error).__name__):
                fake_response = SimpleNamespace(status=None, content_type=None)
                fake_request = SimpleNamespace(query={"query": "San Francisco"})
                with (
                    patch.object(app_module, "response", fake_response),
                    patch.object(app_module, "request", fake_request),
                    patch.object(app_module, "search_payload", side_effect=error),
                ):
                    payload = json.loads(app_module.search())

                self.assertEqual(fake_response.status, expected_status)
                self.assertEqual(payload, {"error": expected_message})
                self.assertNotIn(str(error), json.dumps(payload))

    def test_main_uses_safe_local_server_defaults(self):
        calls = []

        with (
            patch.object(
                app_module, "run", side_effect=lambda **kwargs: calls.append(kwargs)
            ),
            patch.dict(app_module.os.environ, {}, clear=True),
        ):
            app_module.main()

        self.assertEqual(
            calls,
            [{"host": "localhost", "port": 8080, "debug": False}],
        )

    def test_main_uses_safe_heroku_server_defaults(self):
        calls = []

        with (
            patch.object(
                app_module, "run", side_effect=lambda **kwargs: calls.append(kwargs)
            ),
            patch.dict(
                app_module.os.environ,
                {"APP_LOCATION": "heroku", "PORT": "4321"},
                clear=True,
            ),
        ):
            app_module.main()

        self.assertEqual(
            calls,
            [{"host": "0.0.0.0", "port": 4321, "debug": False}],
        )

    def test_main_uses_default_heroku_port_when_unconfigured(self):
        calls = []

        with (
            patch.object(
                app_module, "run", side_effect=lambda **kwargs: calls.append(kwargs)
            ),
            patch.dict(app_module.os.environ, {"APP_LOCATION": "heroku"}, clear=True),
        ):
            app_module.main()

        self.assertEqual(
            calls,
            [{"host": "0.0.0.0", "port": 5000, "debug": False}],
        )

    def test_main_accepts_heroku_port_boundaries(self):
        for configured_port in ("1", "65535"):
            calls = []
            with (
                self.subTest(configured_port=configured_port),
                patch.object(
                    app_module, "run", side_effect=lambda **kwargs: calls.append(kwargs)
                ),
                patch.dict(
                    app_module.os.environ,
                    {"APP_LOCATION": "heroku", "PORT": configured_port},
                    clear=True,
                ),
            ):
                app_module.main()

            self.assertEqual(
                calls,
                [{"host": "0.0.0.0", "port": int(configured_port), "debug": False}],
            )

    def test_main_rejects_invalid_heroku_ports_before_launch(self):
        for configured_port in ("", "not-a-port", "0", "-1", "65536"):
            calls = []
            with (
                self.subTest(configured_port=configured_port),
                patch.object(
                    app_module, "run", side_effect=lambda **kwargs: calls.append(kwargs)
                ),
                patch.dict(
                    app_module.os.environ,
                    {"APP_LOCATION": "heroku", "PORT": configured_port},
                    clear=True,
                ),
                self.assertRaisesRegex(
                    RuntimeError,
                    "^invalid server port configuration$",
                ),
            ):
                app_module.main()

            self.assertEqual(calls, [])

    def test_main_requires_bottle(self):
        with patch.object(app_module, "run", None):
            with self.assertRaisesRegex(
                RuntimeError,
                "^Bottle must be installed to run the web service$",
            ):
                app_module.main()


if __name__ == "__main__":
    unittest.main()
