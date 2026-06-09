import unittest

from app import (
    SEARCH_QUERY_MAX_LENGTH,
    air_quality_payload,
    parse_coordinate,
    parse_search_query,
    search_payload,
)


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

    def test_air_quality_payload_uses_validated_coordinates(self):
        payload = air_quality_payload(
            "37.7749", "-122.4194", air_quality_factory=FakeAirQuality
        )

        self.assertEqual(payload, {"category": "Good", "caution": "None", "score": 42})
        self.assertEqual(FakeAirQuality.calls, [(37.7749, -122.4194)])

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


if __name__ == "__main__":
    unittest.main()
