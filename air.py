import codecs
import ipaddress
import json
import math
import os
import re
import socket
from math import cos, asin, sqrt
from urllib.parse import urljoin, urlsplit

CACHE_TTL_SECONDS = 180
AQI_CACHE_VERSION = 2
REQUEST_TIMEOUT_SECONDS = 10
UPSTREAM_RESPONSE_MAX_BYTES = 1024 * 1024
CACHE_ERROR_MESSAGE = "cache request failed"
HTTPS_DATA_URL_ERROR = "AIRQUALITY_DATA URL must use HTTPS"
PUBLIC_DATA_HOST_ERROR = "AIRQUALITY_DATA host must resolve to public addresses"
JSON_MEDIA_TYPE_ERROR = "AIRQUALITY_DATA response must use a JSON media type"
MEDIA_TYPE_TOKEN = re.compile(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$")
CONTENT_LENGTH_DIGITS = re.compile(r"^[0-9]+$")
COORDINATE_BOUNDS = {
    "lat": (-90.0, 90.0),
    "lng": (-180.0, 180.0),
}
PM25_AQI_BREAKPOINTS = (
    (0.0, 9.0, 0, 50),
    (9.1, 35.4, 51, 100),
    (35.5, 55.4, 101, 150),
    (55.5, 125.4, 151, 200),
    (125.5, 225.4, 201, 300),
    (225.5, 325.4, 301, 500),
)


def _missing(value):
    return value is None or value == ""


def _canonicalize_zero(value):
    return 0.0 if value == 0.0 else value


def _normalize_coordinate(value, name):
    if isinstance(value, bool):
        raise ValueError("{0} must be a number".format(name))

    try:
        coordinate = float(value)
    except (OverflowError, TypeError, ValueError):
        raise ValueError("{0} must be a number".format(name)) from None

    if not math.isfinite(coordinate):
        raise ValueError("{0} must be a finite number".format(name))

    lower, upper = COORDINATE_BOUNDS[name]
    if coordinate < lower or coordinate > upper:
        raise ValueError("{0} must be between {1} and {2}".format(name, lower, upper))

    return _canonicalize_zero(coordinate)


def _require_https_data_url(url):
    try:
        parsed = urlsplit(url)
        hostname = parsed.hostname
        port = parsed.port if parsed.port is not None else 443
    except (AttributeError, TypeError, ValueError):
        raise RuntimeError(HTTPS_DATA_URL_ERROR) from None
    if (
        parsed.scheme.lower() != "https"
        or not parsed.netloc
        or not hostname
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise RuntimeError(HTTPS_DATA_URL_ERROR)
    _require_public_data_host(hostname, port)


def _require_public_data_host(hostname, port):
    try:
        addresses = [ipaddress.ip_address(hostname)]
    except ValueError:
        try:
            results = socket.getaddrinfo(
                hostname,
                port,
                family=socket.AF_UNSPEC,
                type=socket.SOCK_STREAM,
            )
            addresses = [ipaddress.ip_address(result[4][0]) for result in results]
        except (IndexError, OSError, TypeError, ValueError):
            raise RuntimeError(PUBLIC_DATA_HOST_ERROR) from None

    if not addresses or any(
        not address.is_global or address.is_multicast for address in addresses
    ):
        raise RuntimeError(PUBLIC_DATA_HOST_ERROR)


def _require_https_redirect(response, *args, **kwargs):
    if response.is_redirect:
        redirect_url = urljoin(response.url, response.headers["Location"])
        try:
            _require_https_data_url(redirect_url)
        except RuntimeError:
            response.close()
            raise
    return response


def _require_json_media_type(content_type):
    if not isinstance(content_type, str) or "," in content_type:
        raise RuntimeError(JSON_MEDIA_TYPE_ERROR)

    media_type = content_type.split(";", 1)[0].strip().lower()
    top_level, separator, subtype = media_type.partition("/")
    if (
        separator != "/"
        or top_level != "application"
        or not MEDIA_TYPE_TOKEN.fullmatch(subtype)
        or (subtype != "json" and not (subtype.endswith("+json") and len(subtype) > 5))
    ):
        raise RuntimeError(JSON_MEDIA_TYPE_ERROR)


def _require_json_utf8_encoding(encoding):
    try:
        canonical_encoding = codecs.lookup(encoding or "utf-8").name
    except LookupError:
        raise RuntimeError("AIRQUALITY_DATA response must be valid JSON") from None

    if canonical_encoding != "utf-8":
        raise RuntimeError("AIRQUALITY_DATA response must be valid JSON")


def _decode_response_payload(response):
    if not hasattr(response, "json"):
        return response

    try:
        return response.json()
    except Exception:
        raise RuntimeError("AIRQUALITY_DATA response must be valid JSON") from None


def _default_http_get(url):
    import requests

    _require_https_data_url(url)

    try:
        response = requests.get(
            url,
            timeout=REQUEST_TIMEOUT_SECONDS,
            stream=True,
            hooks={"response": _require_https_redirect},
        )
    except requests.exceptions.RequestException:
        raise RuntimeError("AIRQUALITY_DATA request failed") from None

    try:
        _require_https_data_url(response.url)
        response.raise_for_status()
        _require_json_media_type(response.headers.get("Content-Type"))
        _require_json_utf8_encoding(response.encoding)

        content_length = response.headers.get("Content-Length")
        if content_length is not None:
            if not isinstance(
                content_length, str
            ) or not CONTENT_LENGTH_DIGITS.fullmatch(content_length):
                raise RuntimeError(
                    "AIRQUALITY_DATA Content-Length must be a non-negative integer"
                )
            parsed_content_length = int(content_length)
            if parsed_content_length > UPSTREAM_RESPONSE_MAX_BYTES:
                raise RuntimeError("AIRQUALITY_DATA response is too large")

        body = bytearray()
        for chunk in response.iter_content(chunk_size=64 * 1024):
            if not chunk:
                continue
            if len(body) + len(chunk) > UPSTREAM_RESPONSE_MAX_BYTES:
                raise RuntimeError("AIRQUALITY_DATA response is too large")
            body.extend(chunk)

        try:
            return json.loads(body.decode("utf-8"))
        except (UnicodeDecodeError, ValueError):
            raise RuntimeError("AIRQUALITY_DATA response must be valid JSON")
    except requests.exceptions.RequestException:
        raise RuntimeError("AIRQUALITY_DATA request failed") from None
    finally:
        response.close()


class AirQuality(object):
    """AirQuality Class

    Attributes:
        lat: latitude of user
        lng: longitude of user
    """

    def __init__(self, lat, lng, cache_client=None, data_url=None, http_get=None):
        """Return a new AirQuality object."""
        self.lat = _normalize_coordinate(lat, "lat")
        self.lng = _normalize_coordinate(lng, "lng")
        self.r = cache_client
        self.data_url = data_url
        self.http_get = http_get or _default_http_get

    def getData(self):
        key = self.cache_key()
        cache = self.cached_data(key)
        if cache is not None:
            return cache

        data_url = self.data_url or os.environ.get("AIRQUALITY_DATA")
        if not data_url:
            raise RuntimeError("AIRQUALITY_DATA must be set when data is not cached")

        response = self.http_get(data_url)
        payload = _decode_response_payload(response)
        if not isinstance(payload, dict) or not isinstance(
            payload.get("results"), list
        ):
            raise RuntimeError("AIRQUALITY_DATA response must include a results list")

        results = payload["results"]
        reading = self.nearest_reading(results)
        pm25 = float(reading["PM2_5Value"])
        data = self.AQICategory(self.AQIPM25(pm25))
        self.cache_setex(key, CACHE_TTL_SECONDS, json.dumps(data))
        return data

    def cached_data(self, key):
        cache = self.cache_get(key)
        if cache is None:
            return None

        try:
            data = json.loads(cache)
        except (TypeError, ValueError):
            return None

        if not isinstance(data, dict):
            return None

        required_fields = {"category", "caution", "score"}
        if not required_fields.issubset(data):
            return None

        category = data["category"]
        caution = data["caution"]
        score = data["score"]
        if not isinstance(category, str) or not isinstance(caution, str):
            return None

        if isinstance(score, bool) or not isinstance(score, (int, float)):
            return None

        try:
            finite_score = math.isfinite(float(score))
        except OverflowError:
            return None

        if not finite_score:
            return None

        normalized_score = int(score)
        if normalized_score != score or normalized_score < 0 or normalized_score > 500:
            return None

        normalized_data = self.AQICategory(normalized_score)
        if (
            category != normalized_data["category"]
            or caution != normalized_data["caution"]
        ):
            return None

        return normalized_data

    def cache_get(self, key):
        cache = self.cache()
        try:
            return cache.get(key)
        except Exception:
            raise RuntimeError(CACHE_ERROR_MESSAGE) from None

    def cache_setex(self, key, ttl, value):
        cache = self.cache()
        try:
            cache.setex(key, ttl, value)
        except Exception:
            raise RuntimeError(CACHE_ERROR_MESSAGE) from None

    def cache(self):
        if self.r is None:
            redis_url = os.environ.get("REDIS_URL")
            if not redis_url:
                raise RuntimeError("REDIS_URL must be set when data is not cached")

            import redis

            self.r = redis.StrictRedis.from_url(redis_url)
        return self.r

    def cache_key(self):
        return "a_q_{0}_{1}_{2}".format(AQI_CACHE_VERSION, self.lat, self.lng)

    def nearest_reading(self, results):
        nearest = None
        nearest_distance = float("inf")

        for item in results:
            if not isinstance(item, dict):
                continue

            if (
                _missing(item.get("Lat"))
                or _missing(item.get("Lon"))
                or _missing(item.get("PM2_5Value"))
            ):
                continue

            if any(
                isinstance(item.get(field), bool)
                for field in ("Lat", "Lon", "PM2_5Value")
            ):
                continue

            try:
                pm25 = float(item["PM2_5Value"])
                lat = float(item["Lat"])
                lon = float(item["Lon"])
            except (OverflowError, TypeError, ValueError):
                continue

            if not all(math.isfinite(value) for value in (pm25, lat, lon)):
                continue

            if pm25 < 0 or lat < -90 or lat > 90 or lon < -180 or lon > 180:
                continue

            distance = self.distance(self.lat, self.lng, lat, lon)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest = item

        if nearest is None:
            raise RuntimeError(
                "AIRQUALITY_DATA response contains no valid PM2.5 readings"
            )

        return nearest

    def distance(self, lat1, lon1, lat2, lon2):
        p = 0.017453292519943295
        a = (
            0.5
            - cos((lat2 - lat1) * p) / 2
            + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2
        )
        a = max(0.0, min(1.0, a))
        return 12742 * asin(sqrt(a))

    def AQIPM25(self, raw_value):
        if isinstance(raw_value, bool):
            raise ValueError("PM2.5 concentration must be a finite non-negative number")

        conc = float(raw_value)
        if not math.isfinite(conc) or conc < 0:
            raise ValueError("PM2.5 concentration must be a finite non-negative number")

        c = (math.floor(10 * conc)) / 10
        for (
            concentration_low,
            concentration_high,
            aqi_low,
            aqi_high,
        ) in PM25_AQI_BREAKPOINTS:
            if concentration_low <= c <= concentration_high:
                return self.Linear(
                    aqi_high,
                    aqi_low,
                    concentration_high,
                    concentration_low,
                    c,
                )

        return 500

    @staticmethod
    def Linear(AQIhigh, AQIlow, Conchigh, Conclow, Concentration):
        if any(
            isinstance(value, bool)
            for value in (AQIhigh, AQIlow, Conchigh, Conclow, Concentration)
        ):
            raise ValueError("AQI interpolation values must be numeric")

        normalized_values = tuple(
            float(value)
            for value in (AQIhigh, AQIlow, Conchigh, Conclow, Concentration)
        )
        if not all(math.isfinite(value) for value in normalized_values):
            raise ValueError("AQI interpolation values must be finite")

        AQIhigh, AQIlow, Conchigh, Conclow, Conc = normalized_values
        if Conchigh == Conclow:
            raise ValueError(
                "AQI interpolation concentration range must not be zero-width"
            )
        if Conchigh < Conclow:
            raise ValueError("AQI interpolation concentration range must be ascending")

        a = ((Conc - Conclow) / (Conchigh - Conclow)) * (AQIhigh - AQIlow) + AQIlow
        linear = math.floor(a + 0.5)
        return linear

    @staticmethod
    def AQICategory(AQIndex):
        if isinstance(AQIndex, bool):
            raise ValueError("AQI score must be numeric")

        AQI = float(AQIndex)
        if not math.isfinite(AQI):
            raise ValueError("AQI score must be finite")

        if 0 <= AQI <= 50:
            AQICategory = "Good"
            C = "None"
        elif AQI > 50 and AQI <= 100:
            AQICategory = "Moderate"
            C = "Unusually sensitive people should consider reducing prolonged or heavy exertion."
        elif AQI > 100 and AQI <= 150:
            AQICategory = "Unhealthy for Sensitive Groups"
            C = "People with respiratory or heart disease, the elderly and children should limit prolonged exertion."
        elif AQI > 150 and AQI <= 200:
            AQICategory = "Unhealthy"
            C = "People with respiratory or heart disease, the elderly and children should avoid prolonged exertion; everyone else should limit prolonged exertion."
        elif AQI > 200 and AQI <= 300:
            AQICategory = "Very Unhealthy"
            C = "People with respiratory or heart disease, the elderly and children should avoid any outdoor activity; everyone else should avoid prolonged exertion."
        elif AQI > 300 and AQI <= 400:
            AQICategory = "Hazardous"
            C = "Everyone should avoid any outdoor exertion; people with respiratory or heart disease, the elderly and children should remain indoors."
        elif AQI > 400 and AQI <= 500:
            AQICategory = "Hazardous"
            C = "Everyone should avoid any outdoor exertion; people with respiratory or heart disease, the elderly and children should remain indoors."
        else:
            AQICategory = "Out of Range"
            C = "None"
        return {"category": AQICategory, "caution": C, "score": int(AQI)}
