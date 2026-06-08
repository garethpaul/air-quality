import json


class JsonResponse(object):
    def __init__(self, payload):
        self.payload = payload

    def json(self):
        return self.payload


class MemoryCache(object):
    def __init__(self):
        self.values = {}

    def get(self, key):
        return self.values.get(key)

    def set(self, key, value):
        self.values[key] = value

    def setex(self, key, _ttl, value):
        self.set(key, value)

    def decoded(self, key):
        return json.loads(self.values[key])
