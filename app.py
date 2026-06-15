import math
import os
from json import dumps

from air import AirQuality
from geocode import GeoCode

SEARCH_QUERY_MAX_LENGTH = 200
INVALID_REQUEST_MESSAGE = "invalid request"
SERVICE_UNAVAILABLE_MESSAGE = "service unavailable"

try:
    from bottle import request, response, route, run
except ImportError:
    request = None
    response = None
    run = None

    def route(_path):
        def decorator(handler):
            return handler

        return decorator


def parse_coordinate(value, name):
    if value is None or str(value).strip() == "":
        raise ValueError("{0} is required".format(name))

    if isinstance(value, bool):
        raise ValueError("{0} must be a number".format(name))

    try:
        coordinate = float(value)
    except (OverflowError, TypeError, ValueError):
        raise ValueError("{0} must be a number".format(name))

    if not math.isfinite(coordinate):
        raise ValueError("{0} must be a finite number".format(name))

    bounds = {
        "lat": (-90.0, 90.0),
        "lng": (-180.0, 180.0),
    }
    if name not in bounds:
        raise ValueError("unsupported coordinate name: {0}".format(name))

    lower, upper = bounds[name]
    if coordinate < lower or coordinate > upper:
        raise ValueError("{0} must be between {1} and {2}".format(name, lower, upper))

    return coordinate


def air_quality_payload(lat, lng, air_quality_factory=AirQuality):
    latitude = parse_coordinate(lat, "lat")
    longitude = parse_coordinate(lng, "lng")
    return air_quality_factory(latitude, longitude).getData()


def parse_search_query(query):
    if query is None:
        raise ValueError("query is required")

    if not isinstance(query, str):
        raise ValueError("query must be a string")

    query_string = query.strip()
    if not query_string:
        raise ValueError("query is required")

    if len(query_string) > SEARCH_QUERY_MAX_LENGTH:
        raise ValueError(
            "query must be {0} characters or fewer".format(SEARCH_QUERY_MAX_LENGTH)
        )

    return query_string


def search_payload(query, geocode_factory=GeoCode, air_quality_factory=AirQuality):
    query_string = parse_search_query(query)
    query_data = geocode_factory(query_string).getLatLng()
    try:
        return air_quality_payload(
            query_data["lat"], query_data["lng"], air_quality_factory
        )
    except KeyError:
        raise ValueError("geocoder result must include lat and lng")


def json_response(payload, status=200):
    response.status = status
    response.content_type = "application/json"
    return dumps(payload)


def json_error(message, status=400):
    return json_response({"error": message}, status=status)


@route("/")
def show_data():
    try:
        return json_response(
            air_quality_payload(request.query.get("lat"), request.query.get("lng"))
        )
    except ValueError:
        return json_error(INVALID_REQUEST_MESSAGE, status=400)
    except RuntimeError:
        return json_error(SERVICE_UNAVAILABLE_MESSAGE, status=503)


@route("/s")
def search():
    try:
        return json_response(search_payload(request.query.get("query")))
    except ValueError:
        return json_error(INVALID_REQUEST_MESSAGE, status=400)
    except RuntimeError:
        return json_error(SERVICE_UNAVAILABLE_MESSAGE, status=503)


def main():
    if run is None:
        raise RuntimeError("Bottle must be installed to run the web service")

    if os.environ.get("APP_LOCATION") == "heroku":
        run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
    else:
        run(host="localhost", port=8080, debug=True)


if __name__ == "__main__":
    main()
