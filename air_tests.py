import json
import math
import os
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import patch

import air
from test_helpers import FailingCache, JsonResponse, MemoryCache

MODERATE_12_PAYLOAD = {
    "category": "Moderate",
    "caution": "Unusually sensitive people should consider reducing prolonged or heavy exertion.",
    "score": 56,
}


class AirQualityTest(unittest.TestCase):
    class FakeRequestException(Exception):
        pass

    class StreamingResponse(object):
        def __init__(
            self,
            chunks,
            headers=None,
            encoding="utf-8",
            url="https://93.184.216.34/air.json",
            is_redirect=False,
            status_error=None,
            stream_error=None,
        ):
            self.chunks = chunks
            self.headers = {"Content-Type": "application/json"}
            if headers is not None:
                self.headers.update(headers)
            self.encoding = encoding
            self.url = url
            self.is_redirect = is_redirect
            self.status_error = status_error
            self.stream_error = stream_error
            self.status_checked = False
            self.close_calls = 0

        def raise_for_status(self):
            self.status_checked = True
            if self.status_error is not None:
                raise self.status_error

        def iter_content(self, chunk_size):
            self.chunk_size = chunk_size
            if self.stream_error is not None:
                raise self.stream_error
            return iter(self.chunks)

        def close(self):
            self.close_calls += 1

    def requests_module(self, get):
        return SimpleNamespace(
            get=get,
            exceptions=SimpleNamespace(RequestException=self.FakeRequestException),
        )

    def address_results(self, *addresses):
        return [(None, None, None, None, (address, 0)) for address in addresses]

    def call_with_requests_module(
        self,
        requests_module,
        url="https://example.test/air.json",
        resolver=None,
    ):
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = requests_module
        try:
            resolver = resolver or (
                lambda *_args, **_kwargs: self.address_results("93.184.216.34")
            )
            with patch.object(air.socket, "getaddrinfo", side_effect=resolver):
                return air._default_http_get(url)
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

    def test_cache_read_failure_is_normalized_before_upstream_request(self):
        requested_urls = []
        cache = FailingCache("get")
        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=cache,
            data_url="https://example.test/air.json",
            http_get=lambda url: requested_urls.append(url),
        )

        with self.assertRaisesRegex(RuntimeError, "^cache request failed$") as raised:
            quality.getData()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(requested_urls, [])
        self.assertEqual(cache.calls, [("get", (quality.cache_key(),))])

    def test_missing_cache_configuration_remains_a_configuration_error(self):
        quality = air.AirQuality(37.794678, -122.41143)

        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(
                RuntimeError, "^REDIS_URL must be set when data is not cached$"
            ):
                quality.getData()

    def test_cache_write_failure_is_normalized_after_valid_upstream_response(self):
        requested_urls = []
        cache = FailingCache("setex")
        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=cache,
            data_url="https://example.test/air.json",
            http_get=lambda url: (
                requested_urls.append(url)
                or JsonResponse(
                    {"results": [{"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"}]}
                )
            ),
        )

        with self.assertRaisesRegex(RuntimeError, "^cache request failed$") as raised:
            quality.getData()

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(requested_urls, ["https://example.test/air.json"])
        self.assertEqual([command for command, _args in cache.calls], ["get", "setex"])

    def test_upstream_response_limit_is_one_mebibyte(self):
        self.assertEqual(air.UPSTREAM_RESPONSE_MAX_BYTES, 1024 * 1024)

    def test_default_http_get_rejects_plaintext_url_before_request(self):
        calls = []
        requests_module = self.requests_module(
            lambda url, **kwargs: calls.append((url, kwargs))
        )

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA URL must use HTTPS$"
        ) as raised:
            self.call_with_requests_module(
                requests_module, url="http://secret.example/air.json"
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret.example", str(raised.exception))
        self.assertEqual(calls, [])

    def test_default_http_get_normalizes_malformed_url_without_request(self):
        calls = []

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA URL must use HTTPS$"
        ) as raised:
            self.call_with_requests_module(
                self.requests_module(lambda url, **kwargs: calls.append((url, kwargs))),
                url="https://[invalid",
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertEqual(calls, [])

    def test_default_http_get_rejects_url_userinfo_before_resolution(self):
        request_calls = []
        resolver_calls = []

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA URL must use HTTPS$"
        ) as raised:
            self.call_with_requests_module(
                self.requests_module(
                    lambda url, **kwargs: request_calls.append((url, kwargs))
                ),
                url="https://secret@example.test/air.json",
                resolver=lambda *args, **kwargs: resolver_calls.append((args, kwargs)),
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(resolver_calls, [])
        self.assertEqual(request_calls, [])

    def test_default_http_get_rejects_redirect_downgrade_and_closes_response(self):
        response = self.StreamingResponse(
            [b'{"results": []}'], url="http://secret.example/air.json"
        )

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA URL must use HTTPS$"
        ) as raised:
            self.call_with_requests_module(
                self.requests_module(lambda _url, **_kwargs: response)
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret.example", str(raised.exception))
        self.assertFalse(response.status_checked)
        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_plaintext_redirect_before_following(self):
        redirect_response = self.StreamingResponse(
            [],
            headers={"Location": "http://secret.example/air.json"},
            url="https://example.test/air.json",
            is_redirect=True,
        )

        def get(_url, **kwargs):
            return kwargs["hooks"]["response"](redirect_response)

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA URL must use HTTPS$"
        ) as raised:
            self.call_with_requests_module(self.requests_module(get))

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret.example", str(raised.exception))
        self.assertEqual(redirect_response.close_calls, 1)

    def test_default_http_get_allows_relative_https_redirect_target(self):
        redirect_response = self.StreamingResponse(
            [],
            headers={"Location": "/new-air.json"},
            url="https://example.test/air.json",
            is_redirect=True,
        )

        with patch.object(
            air.socket,
            "getaddrinfo",
            return_value=self.address_results("93.184.216.34"),
        ):
            self.assertIs(
                air._require_https_redirect(redirect_response), redirect_response
            )
        self.assertEqual(redirect_response.close_calls, 0)

    def test_default_http_get_rejects_private_literal_before_request(self):
        calls = []

        with self.assertRaisesRegex(
            RuntimeError,
            "^AIRQUALITY_DATA host must resolve to public addresses$",
        ) as raised:
            self.call_with_requests_module(
                self.requests_module(lambda url, **kwargs: calls.append((url, kwargs))),
                url="https://127.0.0.1/air.json",
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertEqual(calls, [])

    def test_default_http_get_rejects_private_ipv6_literal_before_request(self):
        calls = []

        with self.assertRaisesRegex(
            RuntimeError,
            "^AIRQUALITY_DATA host must resolve to public addresses$",
        ):
            self.call_with_requests_module(
                self.requests_module(lambda url, **kwargs: calls.append((url, kwargs))),
                url="https://[::1]/air.json",
            )

        self.assertEqual(calls, [])

    def test_default_http_get_rejects_multicast_literals_before_request(self):
        for url in ("https://224.0.0.1/air.json", "https://[ff02::1]/air.json"):
            with self.subTest(url=url):
                calls = []

                with self.assertRaisesRegex(
                    RuntimeError,
                    "^AIRQUALITY_DATA host must resolve to public addresses$",
                ):
                    self.call_with_requests_module(
                        self.requests_module(
                            lambda request_url, **kwargs: calls.append(
                                (request_url, kwargs)
                            )
                        ),
                        url=url,
                    )

                self.assertEqual(calls, [])

    def test_default_http_get_rejects_mixed_public_private_dns_answers(self):
        calls = []

        with self.assertRaisesRegex(
            RuntimeError,
            "^AIRQUALITY_DATA host must resolve to public addresses$",
        ) as raised:
            self.call_with_requests_module(
                self.requests_module(lambda url, **kwargs: calls.append((url, kwargs))),
                resolver=lambda *_args, **_kwargs: self.address_results(
                    "93.184.216.34", "10.0.0.8"
                ),
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertEqual(calls, [])

    def test_default_http_get_rejects_empty_dns_answers(self):
        calls = []

        with self.assertRaisesRegex(
            RuntimeError,
            "^AIRQUALITY_DATA host must resolve to public addresses$",
        ):
            self.call_with_requests_module(
                self.requests_module(lambda url, **kwargs: calls.append((url, kwargs))),
                resolver=lambda *_args, **_kwargs: [],
            )

        self.assertEqual(calls, [])

    def test_default_http_get_normalizes_dns_resolution_failure(self):
        calls = []

        def resolver(*_args, **_kwargs):
            raise OSError("secret resolver diagnostic")

        with self.assertRaisesRegex(
            RuntimeError,
            "^AIRQUALITY_DATA host must resolve to public addresses$",
        ) as raised:
            self.call_with_requests_module(
                self.requests_module(lambda url, **kwargs: calls.append((url, kwargs))),
                resolver=resolver,
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("secret", str(raised.exception))
        self.assertEqual(calls, [])

    def test_default_http_get_rejects_private_redirect_before_following(self):
        redirect_response = self.StreamingResponse(
            [],
            headers={"Location": "https://internal.example/air.json"},
            url="https://example.test/air.json",
            is_redirect=True,
        )

        def resolver(hostname, *_args, **_kwargs):
            address = "10.0.0.8" if hostname == "internal.example" else "93.184.216.34"
            return self.address_results(address)

        def get(_url, **kwargs):
            return kwargs["hooks"]["response"](redirect_response)

        with self.assertRaisesRegex(
            RuntimeError,
            "^AIRQUALITY_DATA host must resolve to public addresses$",
        ) as raised:
            self.call_with_requests_module(self.requests_module(get), resolver=resolver)

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("internal.example", str(raised.exception))
        self.assertEqual(redirect_response.close_calls, 1)

    def test_default_http_get_rejects_private_final_url_before_status(self):
        response = self.StreamingResponse(
            [b'{"results": []}'], url="https://internal.example/air.json"
        )

        def resolver(hostname, *_args, **_kwargs):
            address = "10.0.0.8" if hostname == "internal.example" else "93.184.216.34"
            return self.address_results(address)

        with self.assertRaisesRegex(
            RuntimeError,
            "^AIRQUALITY_DATA host must resolve to public addresses$",
        ):
            self.call_with_requests_module(
                self.requests_module(lambda _url, **_kwargs: response),
                resolver=resolver,
            )

        self.assertFalse(response.status_checked)
        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_resolves_hostname_for_stream_connections(self):
        resolver_calls = []
        request_calls = []
        response = self.StreamingResponse([b'{"results": []}'])

        def resolver(*args, **kwargs):
            resolver_calls.append((args, kwargs))
            return self.address_results("93.184.216.34")

        payload = self.call_with_requests_module(
            self.requests_module(
                lambda url, **kwargs: request_calls.append((url, kwargs)) or response
            ),
            resolver=resolver,
        )

        self.assertEqual(payload, {"results": []})
        self.assertEqual(
            resolver_calls,
            [
                (
                    ("example.test", 443),
                    {"family": air.socket.AF_UNSPEC, "type": air.socket.SOCK_STREAM},
                )
            ],
        )
        self.assertEqual(len(request_calls), 1)

    def test_cache_key_versions_current_epa_breakpoints(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())

        self.assertEqual(quality.cache_key(), "a_q_2_37.794678_-122.41143")

    def test_constructor_rejects_invalid_coordinates(self):
        invalid_coordinates = (
            (True, 0),
            (0, False),
            ("north", 0),
            (0, "west"),
            (float("nan"), 0),
            (0, float("nan")),
            (float("inf"), 0),
            (0, float("-inf")),
            (10**400, 0),
            (0, -(10**400)),
            (-90.1, 0),
            (90.1, 0),
            (0, -180.1),
            (0, 180.1),
        )

        for latitude, longitude in invalid_coordinates:
            with self.subTest(latitude=latitude, longitude=longitude):
                with self.assertRaises(ValueError):
                    air.AirQuality(latitude, longitude, cache_client=MemoryCache())

    def test_constructor_normalizes_boundary_coordinates_and_numeric_strings(self):
        cases = (
            (-90, -180, -90.0, -180.0),
            (90, 180, 90.0, 180.0),
            ("37.794678", "-122.41143", 37.794678, -122.41143),
        )

        for latitude, longitude, expected_latitude, expected_longitude in cases:
            with self.subTest(latitude=latitude, longitude=longitude):
                quality = air.AirQuality(
                    latitude, longitude, cache_client=MemoryCache()
                )

                self.assertEqual(quality.lat, expected_latitude)
                self.assertEqual(quality.lng, expected_longitude)

    def test_constructor_canonicalizes_signed_zero_coordinates_and_cache_keys(self):
        zero_values = (0.0, -0.0, "0", "-0", "0.0", "-0.0")

        for latitude in zero_values:
            for longitude in zero_values:
                with self.subTest(latitude=latitude, longitude=longitude):
                    quality = air.AirQuality(
                        latitude, longitude, cache_client=MemoryCache()
                    )

                    self.assertEqual(quality.lat, 0.0)
                    self.assertEqual(quality.lng, 0.0)
                    self.assertEqual(math.copysign(1.0, quality.lat), 1.0)
                    self.assertEqual(math.copysign(1.0, quality.lng), 1.0)
                    self.assertEqual(quality.cache_key(), "a_q_2_0.0_0.0")

        positive = air.AirQuality(0.0, 0.0, cache_client=MemoryCache())
        negative = air.AirQuality(-0.0, -0.0, cache_client=MemoryCache())
        self.assertEqual(positive.cache_key(), negative.cache_key())

    def test_default_http_get_uses_timeout(self):
        calls = []
        streaming_response = self.StreamingResponse([b'{"results": []}'])
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = self.requests_module(
            lambda url, **kwargs: calls.append((url, kwargs)) or streaming_response
        )

        try:
            payload = air._default_http_get("https://93.184.216.34/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(payload, {"results": []})
        self.assertEqual(len(calls), 1)
        requested_url, request_options = calls[0]
        self.assertEqual(requested_url, "https://93.184.216.34/air.json")
        self.assertEqual(request_options["timeout"], air.REQUEST_TIMEOUT_SECONDS)
        self.assertTrue(request_options["stream"])
        self.assertIs(request_options["hooks"]["response"], air._require_https_redirect)
        self.assertTrue(streaming_response.status_checked)
        self.assertEqual(streaming_response.chunk_size, 64 * 1024)
        self.assertEqual(streaming_response.close_calls, 1)

    def test_default_http_get_accepts_json_media_types_with_parameters(self):
        for content_type in (
            "application/json",
            "Application/JSON; Charset=UTF-8",
            "application/vnd.air-quality+json; version=1",
        ):
            with self.subTest(content_type=content_type):
                response = self.StreamingResponse(
                    [b'{"results": []}'], headers={"Content-Type": content_type}
                )

                payload = self.call_with_requests_module(
                    self.requests_module(lambda _url, **_kwargs: response)
                )

                self.assertEqual(payload, {"results": []})
                self.assertEqual(response.close_calls, 1)

    def test_default_http_get_accepts_utf8_encoding_aliases(self):
        for encoding in (None, "utf-8", "UTF8", "utf_8"):
            with self.subTest(encoding=encoding):
                response = self.StreamingResponse(
                    ['{"label":"caf\u00e9"}'.encode("utf-8")], encoding=encoding
                )

                payload = self.call_with_requests_module(
                    self.requests_module(lambda _url, **_kwargs: response)
                )

                self.assertEqual(payload, {"label": "caf\u00e9"})
                self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_non_utf8_json_before_streaming(self):
        response = self.StreamingResponse(
            [b'{"label":"caf\xe9"}'], encoding="iso-8859-1"
        )

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA response must be valid JSON$"
        ) as raised:
            self.call_with_requests_module(
                self.requests_module(lambda _url, **_kwargs: response)
            )

        self.assertIsNone(raised.exception.__cause__)
        self.assertNotIn("iso-8859-1", str(raised.exception))
        self.assertFalse(hasattr(response, "chunk_size"))
        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_non_json_media_types_before_streaming(self):
        for content_type in (
            None,
            "text/json",
            "application/xml",
            "application/+json",
            "application/json, text/html",
            123,
        ):
            with self.subTest(content_type=content_type):
                headers = {}
                if content_type is not None:
                    headers["Content-Type"] = content_type
                response = self.StreamingResponse([b'{"results": []}'], headers=headers)
                if content_type is None:
                    response.headers.pop("Content-Type")

                with self.assertRaisesRegex(
                    RuntimeError,
                    "^AIRQUALITY_DATA response must use a JSON media type$",
                ):
                    self.call_with_requests_module(
                        self.requests_module(lambda _url, **_kwargs: response)
                    )

                self.assertFalse(hasattr(response, "chunk_size"))
                self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_oversized_streamed_responses(self):
        response = self.StreamingResponse(
            [b"x" * air.UPSTREAM_RESPONSE_MAX_BYTES, b"x"]
        )
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = self.requests_module(lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(RuntimeError, "response is too large"):
                air._default_http_get("https://93.184.216.34/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_oversized_chunk_before_buffer_extension(self):
        class TrackingBytearray(bytearray):
            extend_calls = 0

            def extend(self, value):
                type(self).extend_calls += 1
                super().extend(value)

        response = self.StreamingResponse(
            [b"x" * (air.UPSTREAM_RESPONSE_MAX_BYTES + 1)]
        )

        with patch.object(air, "bytearray", TrackingBytearray, create=True):
            with self.assertRaisesRegex(RuntimeError, "response is too large"):
                self.call_with_requests_module(
                    self.requests_module(lambda _url, **_kwargs: response),
                    url="https://93.184.216.34/air.json",
                )

        self.assertEqual(TrackingBytearray.extend_calls, 0)
        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_oversized_content_length(self):
        response = self.StreamingResponse(
            [], headers={"Content-Length": str(air.UPSTREAM_RESPONSE_MAX_BYTES + 1)}
        )
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = self.requests_module(lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(RuntimeError, "response is too large"):
                air._default_http_get("https://93.184.216.34/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_negative_content_length(self):
        response = self.StreamingResponse([], headers={"Content-Length": "-1"})

        with self.assertRaisesRegex(RuntimeError, "non-negative integer"):
            self.call_with_requests_module(
                self.requests_module(lambda _url, **_kwargs: response)
            )

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_rejects_non_decimal_content_length_before_streaming(self):
        for content_length in (
            "",
            "+1",
            " 1",
            "1 ",
            "1_0",
            "1.0",
            "1, 2",
            "\u0661",
            1,
        ):
            with self.subTest(content_length=content_length):
                response = self.StreamingResponse(
                    [], headers={"Content-Length": content_length}
                )

                with self.assertRaisesRegex(
                    RuntimeError,
                    "^AIRQUALITY_DATA Content-Length must be a non-negative integer$",
                ):
                    self.call_with_requests_module(
                        self.requests_module(lambda _url, **_kwargs: response)
                    )

                self.assertFalse(hasattr(response, "chunk_size"))
                self.assertEqual(response.close_calls, 1)

    def test_default_http_get_accepts_ascii_decimal_content_length(self):
        payload = b'{"results": []}'
        for content_length in (
            "0",
            str(len(payload)),
            str(air.UPSTREAM_RESPONSE_MAX_BYTES),
        ):
            with self.subTest(content_length=content_length):
                response = self.StreamingResponse(
                    [payload], headers={"Content-Length": content_length}
                )

                result = self.call_with_requests_module(
                    self.requests_module(lambda _url, **_kwargs: response)
                )

                self.assertEqual(result, {"results": []})
                self.assertEqual(response.close_calls, 1)

    def test_default_http_get_closes_response_after_status_failure(self):
        response = self.StreamingResponse([], status_error=OSError("upstream failed"))
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = self.requests_module(lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(OSError, "upstream failed"):
                air._default_http_get("https://93.184.216.34/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_normalizes_connection_failure(self):
        def fail_connection(_url, **_kwargs):
            raise self.FakeRequestException("https://secret.example/provider")

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA request failed$"
        ) as raised:
            self.call_with_requests_module(self.requests_module(fail_connection))

        self.assertIsNone(raised.exception.__cause__)
        self.assertTrue(raised.exception.__suppress_context__)
        self.assertNotIn("secret.example", str(raised.exception))

    def test_default_http_get_normalizes_status_failure_and_closes_response(self):
        response = self.StreamingResponse(
            [], status_error=self.FakeRequestException("503 provider-secret")
        )

        with self.assertRaisesRegex(RuntimeError, "^AIRQUALITY_DATA request failed$"):
            self.call_with_requests_module(
                self.requests_module(lambda _url, **_kwargs: response)
            )

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_normalizes_stream_failure_and_closes_response(self):
        response = self.StreamingResponse(
            [], stream_error=self.FakeRequestException("stream provider-secret")
        )

        with self.assertRaisesRegex(RuntimeError, "^AIRQUALITY_DATA request failed$"):
            self.call_with_requests_module(
                self.requests_module(lambda _url, **_kwargs: response)
            )

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_closes_response_after_invalid_json(self):
        response = self.StreamingResponse([b"not-json"])
        original_requests = sys.modules.get("requests")
        sys.modules["requests"] = self.requests_module(lambda _url, **_kwargs: response)

        try:
            with self.assertRaisesRegex(RuntimeError, "must be valid JSON"):
                air._default_http_get("https://93.184.216.34/air.json")
        finally:
            if original_requests is None:
                sys.modules.pop("requests", None)
            else:
                sys.modules["requests"] = original_requests

        self.assertEqual(response.close_calls, 1)

    def test_default_http_get_normalizes_unknown_encoding_and_closes_response(self):
        response = self.StreamingResponse(
            [b'{"results": []}'], encoding="unknown-provider-charset"
        )

        with self.assertRaisesRegex(RuntimeError, "must be valid JSON"):
            self.call_with_requests_module(
                self.requests_module(lambda _url, **_kwargs: response)
            )

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
            json.dumps({"category": "Good", "caution": "None", "score": 10**400}),
            json.dumps({"category": "Out of Range", "caution": "None", "score": 501}),
            json.dumps({"category": "Hazardous", "caution": "None", "score": 50}),
            json.dumps(
                {
                    "category": "Good",
                    "caution": "Everyone should remain indoors.",
                    "score": 50,
                }
            ),
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

    def test_scoring_helpers_reject_boolean_values(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())
        helper_calls = {
            "AQIPM25": quality.AQIPM25,
            "Linear AQI high": lambda value: quality.Linear(value, 0, 9.0, 0.0, 1.0),
            "Linear AQI low": lambda value: quality.Linear(50, value, 9.0, 0.0, 1.0),
            "Linear concentration high": lambda value: quality.Linear(
                50, 0, value, 0.0, 1.0
            ),
            "Linear concentration low": lambda value: quality.Linear(
                50, 0, 9.0, value, 1.0
            ),
            "Linear concentration": lambda value: quality.Linear(
                50, 0, 9.0, 0.0, value
            ),
            "AQICategory": quality.AQICategory,
        }

        for helper_name, helper_call in helper_calls.items():
            for boolean_value in (False, True):
                with self.subTest(helper=helper_name, value=boolean_value):
                    with self.assertRaises(ValueError):
                        helper_call(boolean_value)

        self.assertEqual(quality.AQIPM25("9.1"), 51)
        self.assertEqual(quality.Linear(50, 0, 9.0, 0.0, "9.0"), 50)
        self.assertEqual(
            quality.AQICategory("120"),
            {
                "category": "Unhealthy for Sensitive Groups",
                "caution": "People with respiratory or heart disease, the elderly and children should limit prolonged exertion.",
                "score": 120,
            },
        )

    def test_scoring_helpers_reject_nonfinite_values(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())
        helper_calls = {
            "Linear AQI high": lambda value: quality.Linear(value, 0, 9.0, 0.0, 1.0),
            "Linear AQI low": lambda value: quality.Linear(50, value, 9.0, 0.0, 1.0),
            "Linear concentration high": lambda value: quality.Linear(
                50, 0, value, 0.0, 1.0
            ),
            "Linear concentration low": lambda value: quality.Linear(
                50, 0, 9.0, value, 1.0
            ),
            "Linear concentration": lambda value: quality.Linear(
                50, 0, 9.0, 0.0, value
            ),
            "AQICategory": quality.AQICategory,
        }

        for helper_name, helper_call in helper_calls.items():
            for nonfinite_value in (float("nan"), float("inf"), float("-inf")):
                with self.subTest(helper=helper_name, value=nonfinite_value):
                    with self.assertRaises(ValueError):
                        helper_call(nonfinite_value)

    def test_linear_rejects_zero_width_concentration_range(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())

        for concentration_high, concentration_low in ((1.0, 1.0), ("1.0", "1.0")):
            with self.subTest(
                concentration_high=concentration_high,
                concentration_low=concentration_low,
            ):
                with self.assertRaisesRegex(
                    ValueError,
                    "^AQI interpolation concentration range must not be zero-width$",
                ):
                    quality.Linear(
                        50,
                        0,
                        concentration_high,
                        concentration_low,
                        1.0,
                    )

        self.assertEqual(quality.Linear(50, 0, 9.0, 0.0, "9.0"), 50)

    def test_linear_rejects_descending_concentration_range(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())

        for concentration_high, concentration_low in ((0.0, 9.0), ("0.0", "9.0")):
            with self.subTest(
                concentration_high=concentration_high,
                concentration_low=concentration_low,
            ):
                with self.assertRaisesRegex(
                    ValueError,
                    "^AQI interpolation concentration range must be ascending$",
                ):
                    quality.Linear(
                        50,
                        0,
                        concentration_high,
                        concentration_low,
                        1.0,
                    )

        self.assertEqual(quality.Linear(50, 0, 9.0, 0.0, "9.0"), 50)

    def test_linear_rounds_nonnegative_half_values_up(self):
        quality = air.AirQuality(37.794678, -122.41143, cache_client=MemoryCache())

        self.assertEqual(quality.Linear(49, 0, 100, 0, 1), 0)
        self.assertEqual(quality.Linear(1, 0, 2, 0, 1), 1)
        self.assertEqual(quality.Linear(3, 0, 2, 0, 1), 2)
        self.assertEqual(quality.Linear(51, 0, 100, 0, 1), 1)

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

    def test_category_handles_negative_out_of_range_score(self):
        for score in (-1, -0.5):
            with self.subTest(score=score):
                self.assertEqual(
                    air.AirQuality.AQICategory(score),
                    {
                        "category": "Out of Range",
                        "caution": "None",
                        "score": int(score),
                    },
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

    def test_response_json_failure_is_normalized_without_detail(self):
        class BrokenJsonResponse(object):
            def json(self):
                raise LookupError("provider payload contained account detail")

        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: BrokenJsonResponse(),
        )

        with self.assertRaisesRegex(
            RuntimeError, "^AIRQUALITY_DATA response must be valid JSON$"
        ) as raised:
            quality.getData()

        self.assertIsNone(raised.exception.__cause__)
        self.assertTrue(raised.exception.__suppress_context__)
        self.assertNotIn("account detail", str(raised.exception))

    def test_direct_mapping_http_adapter_remains_supported(self):
        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: {
                "results": [{"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"}]
            },
        )

        self.assertEqual(quality.getData(), MODERATE_12_PAYLOAD)

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

    def test_boolean_sensor_values_are_ignored(self):
        quality = air.AirQuality(
            1,
            1,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: JsonResponse(
                {
                    "results": [
                        {"Lat": True, "Lon": 1, "PM2_5Value": "1.0"},
                        {"Lat": 1, "Lon": False, "PM2_5Value": "2.0"},
                        {"Lat": 1, "Lon": 1, "PM2_5Value": True},
                        {"Lat": 2, "Lon": 2, "PM2_5Value": "12.0"},
                    ]
                }
            ),
        )

        self.assertEqual(quality.getData(), MODERATE_12_PAYLOAD)

    def test_overflowing_sensor_values_are_ignored(self):
        huge_integer = 10**400
        quality = air.AirQuality(
            37.794678,
            -122.41143,
            cache_client=MemoryCache(),
            data_url="https://example.test/air.json",
            http_get=lambda _url: JsonResponse(
                {
                    "results": [
                        {
                            "Lat": huge_integer,
                            "Lon": -122.41,
                            "PM2_5Value": "12.0",
                        },
                        {
                            "Lat": 37.8,
                            "Lon": huge_integer,
                            "PM2_5Value": "12.0",
                        },
                        {
                            "Lat": 37.8,
                            "Lon": -122.41,
                            "PM2_5Value": huge_integer,
                        },
                        {"Lat": 37.8, "Lon": -122.41, "PM2_5Value": "12.0"},
                    ]
                }
            ),
        )

        self.assertEqual(quality.getData(), MODERATE_12_PAYLOAD)

    def test_near_antipodal_sensor_distance_clamps_rounding_drift(self):
        quality = air.AirQuality(
            58.38473355304356,
            -114.00513984238154,
            cache_client=MemoryCache(),
        )
        reading = {
            "Lat": -58.384733569713255,
            "Lon": 65.9948601649641,
            "PM2_5Value": "12.0",
        }

        self.assertIs(quality.nearest_reading([reading]), reading)
        self.assertAlmostEqual(
            quality.distance(quality.lat, quality.lng, reading["Lat"], reading["Lon"]),
            20015.086796020572,
        )


if __name__ == "__main__":
    unittest.main()
