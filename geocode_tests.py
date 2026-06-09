import unittest

from geocode import GeoCode
from test_helpers import JsonResponse, MemoryCache


class FakeGeocoder(object):
    def __init__(self, payload):
        self.payload = payload
        self.queries = []

    def forward(self, query):
        self.queries.append(query)
        return JsonResponse(self.payload)


class GeoCodeTest(unittest.TestCase):
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
