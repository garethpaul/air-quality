import json
import os


class GeoCode(object):
    def __init__(self, query, cache_client=None, geocoder=None):
        self.query = query
        self.r = cache_client
        self.geocoder = geocoder

    def getLatLng(self):
        key = "geocode_query_1_" + self.query
        cache = self.cache().get(key)
        if cache is None:
            response = self.geocoder_client().forward(self.query)
            features = response.json().get("features", [])
            if not features:
                raise ValueError("No geocoding results were returned")

            collection = features[0]["center"]
            data = {"lat": collection[1], "lng": collection[0]}
            self.cache().set(key, json.dumps(data))
            return data
        return json.loads(cache)

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

            self.geocoder = Geocoder()
        return self.geocoder
