import unittest

from request_validation import QueryParameterError, required_finite_float


class RequestValidationTest(unittest.TestCase):
    def test_required_finite_float_returns_numeric_query_value(self):
        self.assertEqual(required_finite_float({"lat": "37.794678"}, "lat"), 37.794678)

    def test_required_finite_float_rejects_missing_value(self):
        with self.assertRaisesRegex(
            QueryParameterError, "Missing required query parameter: lat"
        ):
            required_finite_float({}, "lat")

    def test_required_finite_float_rejects_empty_value(self):
        with self.assertRaisesRegex(
            QueryParameterError, "Missing required query parameter: lng"
        ):
            required_finite_float({"lng": ""}, "lng")

    def test_required_finite_float_rejects_malformed_value(self):
        with self.assertRaisesRegex(
            QueryParameterError, "Invalid query parameter: lat must be a number"
        ):
            required_finite_float({"lat": "not-a-number"}, "lat")

    def test_required_finite_float_rejects_non_finite_value(self):
        for raw_value in ("nan", "inf", "-inf"):
            with self.subTest(raw_value=raw_value):
                with self.assertRaisesRegex(
                    QueryParameterError,
                    "Invalid query parameter: lat must be a finite number",
                ):
                    required_finite_float({"lat": raw_value}, "lat")


if __name__ == "__main__":
    unittest.main()
