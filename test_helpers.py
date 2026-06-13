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


class FailingCache(object):
    def __init__(self, fail_command):
        self.fail_command = fail_command
        self.calls = []

    def _call(self, command, *args):
        self.calls.append((command, args))
        if command == self.fail_command:
            raise RuntimeError("redis://user:secret@example.test cache unavailable")
        return None

    def get(self, key):
        return self._call("get", key)

    def set(self, key, value):
        return self._call("set", key, value)

    def setex(self, key, ttl, value):
        return self._call("setex", key, ttl, value)
