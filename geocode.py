import json
import math
import os
from collections.abc import Mapping

from air import _canonicalize_zero

CACHE_ERROR_MESSAGE = "cache request failed"
GEOCODER_ERROR_MESSAGE = "geocoder request failed"
MAPBOX_PERMANENT_DATASET = "mapbox.places-permanent"


class _NoGeocodingResults(ValueError):
    pass


class GeoCode(object):
    def __init__(self, query, cache_client=None, geocoder=None):
        self.query = query
        self.r = cache_client
        self.geocoder = geocoder

    def getLatLng(self):
        key = "geocode_query_1_" + self.query
        data = self.cached_data(key)
        if data is not None:
            return data

        try:
            response = self.geocoder_client().forward(self.query)
            payload = response.json()
        except Exception:
            raise RuntimeError(GEOCODER_ERROR_MESSAGE) from None

        try:
            data = self.parse_first_feature_center(payload)
        except _NoGeocodingResults:
            raise
        except ValueError:
            raise RuntimeError(GEOCODER_ERROR_MESSAGE) from None
        self.cache_set(key, json.dumps(data))
        return data

    def cached_data(self, key):
        cache = self.cache_get(key)
        if cache is None:
            return None

        try:
            data = json.loads(cache)
        except (TypeError, ValueError):
            return None

        if not isinstance(data, Mapping):
            return None

        if isinstance(data.get("lat"), bool) or isinstance(data.get("lng"), bool):
            return None

        try:
            lat = float(data["lat"])
            lng = float(data["lng"])
        except (KeyError, OverflowError, TypeError, ValueError):
            return None

        if not math.isfinite(lat) or not math.isfinite(lng):
            return None

        if lat < -90 or lat > 90 or lng < -180 or lng > 180:
            return None

        normalized = {
            "lat": _canonicalize_zero(lat),
            "lng": _canonicalize_zero(lng),
        }
        if any(isinstance(data[field], str) for field in ("lat", "lng")) or any(
            value == 0.0 and math.copysign(1.0, value) < 0 for value in (lat, lng)
        ):
            self.cache_set(key, json.dumps(normalized))
        return normalized

    def cache_get(self, key):
        cache = self.cache()
        try:
            return cache.get(key)
        except Exception:
            raise RuntimeError(CACHE_ERROR_MESSAGE) from None

    def cache_set(self, key, value):
        cache = self.cache()
        try:
            cache.set(key, value)
        except Exception:
            raise RuntimeError(CACHE_ERROR_MESSAGE) from None

    @staticmethod
    def parse_first_feature_center(payload):
        if not isinstance(payload, Mapping):
            raise ValueError("geocoder response must be a JSON object")

        features = payload.get("features", [])
        if not isinstance(features, list) or not features:
            if isinstance(features, list):
                raise _NoGeocodingResults("No geocoding results were returned")
            raise ValueError("geocoder features must be a list")

        first_feature = features[0]
        if not isinstance(first_feature, Mapping):
            raise ValueError("geocoder feature must be a JSON object")

        center = first_feature.get("center")
        if not isinstance(center, list) or len(center) < 2:
            raise ValueError("geocoder feature must include lng/lat center")

        if isinstance(center[0], bool) or isinstance(center[1], bool):
            raise ValueError("geocoder center values must be numeric")

        try:
            lng = float(center[0])
            lat = float(center[1])
        except (OverflowError, TypeError, ValueError):
            raise ValueError("geocoder center values must be numeric")

        if not math.isfinite(lat) or not math.isfinite(lng):
            raise ValueError("geocoder center values must be finite")

        if lat < -90 or lat > 90 or lng < -180 or lng > 180:
            raise ValueError("geocoder center values must be valid coordinates")

        return {
            "lat": _canonicalize_zero(lat),
            "lng": _canonicalize_zero(lng),
        }

    def cache(self):
        if self.r is None:
            redis_url = os.environ.get("REDIS_URL")
            if not redis_url:
                raise RuntimeError("REDIS_URL must be set when geocode is not cached")

            import redis

            self.r = redis.StrictRedis.from_url(redis_url)
        return self.r

    def geocoder_client(self):
        if self.geocoder is None:
            from mapbox import Geocoder

            self.geocoder = Geocoder(name=MAPBOX_PERMANENT_DATASET)
        return self.geocoder
