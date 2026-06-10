import json
import math
import os
from math import cos, asin, sqrt

CACHE_TTL_SECONDS = 180
AQI_CACHE_VERSION = 2
REQUEST_TIMEOUT_SECONDS = 10
UPSTREAM_RESPONSE_MAX_BYTES = 1024 * 1024
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


def _default_http_get(url):
    import requests

    response = requests.get(url, timeout=REQUEST_TIMEOUT_SECONDS, stream=True)
    response.raise_for_status()

    content_length = response.headers.get("Content-Length")
    if content_length is not None:
        try:
            if int(content_length) > UPSTREAM_RESPONSE_MAX_BYTES:
                raise RuntimeError("AIRQUALITY_DATA response is too large")
        except ValueError:
            raise RuntimeError("AIRQUALITY_DATA Content-Length must be an integer")

    body = bytearray()
    for chunk in response.iter_content(chunk_size=64 * 1024):
        if not chunk:
            continue
        body.extend(chunk)
        if len(body) > UPSTREAM_RESPONSE_MAX_BYTES:
            raise RuntimeError("AIRQUALITY_DATA response is too large")

    try:
        return json.loads(body.decode(response.encoding or "utf-8"))
    except (UnicodeDecodeError, ValueError):
        raise RuntimeError("AIRQUALITY_DATA response must be valid JSON")


class AirQuality(object):
    """AirQuality Class

    Attributes:
        lat: latitude of user
        lng: longitude of user
    """

    def __init__(self, lat, lng, cache_client=None, data_url=None, http_get=None):
        """Return a new AirQuality object."""
        self.lat = float(lat)
        self.lng = float(lng)
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
        payload = response.json() if hasattr(response, "json") else response
        if not isinstance(payload, dict) or not isinstance(
            payload.get("results"), list
        ):
            raise RuntimeError("AIRQUALITY_DATA response must include a results list")

        results = payload["results"]
        reading = self.nearest_reading(results)
        pm25 = float(reading["PM2_5Value"])
        data = self.AQICategory(self.AQIPM25(pm25))
        self.cache().setex(key, CACHE_TTL_SECONDS, json.dumps(data))
        return data

    def cached_data(self, key):
        cache = self.cache().get(key)
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

        if not math.isfinite(float(score)):
            return None

        normalized_score = int(score)
        if normalized_score != score or normalized_score < 0:
            return None

        return {"category": category, "caution": caution, "score": normalized_score}

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

            try:
                pm25 = float(item["PM2_5Value"])
                lat = float(item["Lat"])
                lon = float(item["Lon"])
            except (TypeError, ValueError):
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
            raise ValueError("No valid PM2.5 readings were returned")

        return nearest

    def distance(self, lat1, lon1, lat2, lon2):
        p = 0.017453292519943295
        a = (
            0.5
            - cos((lat2 - lat1) * p) / 2
            + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2
        )
        return 12742 * asin(sqrt(a))

    def AQIPM25(self, raw_value):
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
        Conc = float(Concentration)
        a = ((Conc - Conclow) / (Conchigh - Conclow)) * (AQIhigh - AQIlow) + AQIlow
        linear = round(a)
        return linear

    @staticmethod
    def AQICategory(AQIndex):
        AQI = float(AQIndex)
        if AQI <= 50:
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
