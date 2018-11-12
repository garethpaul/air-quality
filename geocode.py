import os
from mapbox import Geocoder
import redis
import json
r = redis.StrictRedis.from_url(os.environ.get("REDIS_URL"))

class GeoCode(object):

    def __init__(self, query):
        self.query = query
   
    def getLatLng(self):
        # Check Cache
        key = 'geocode_query_1_' + self.query
        cache = r.get(key)
        if cache is None:
            geocoder = Geocoder()
            response = geocoder.forward(self.query)
            collection = response.json()['features'][0]['center']
            data = {"lat": collection[1], "lng": collection[0]}
            r.set(key, json.dumps(data))
            return data
        else:
            return json.loads(cache)