import os
from json import dumps

from bottle import request, response, route, run

from air import AirQuality
from geocode import GeoCode
from request_validation import QueryParameterError, required_finite_float


def json_response(payload, status=None):
    response.content_type = "application/json"
    if status is not None:
        response.status = status
    return dumps(payload)


@route("/")
def show_data():
    try:
        lat = required_finite_float(request.query, "lat")
        lng = required_finite_float(request.query, "lng")
    except QueryParameterError as error:
        return json_response({"error": str(error)}, status=400)

    a = AirQuality(lat, lng).getData()
    return json_response(a)


@route("/s")
def search():
    query_string = request.query["query"]
    if query_string:
        query_data = GeoCode(query_string).getLatLng()
        print(query_data)
        a = AirQuality(query_data["lat"], query_data["lng"]).getData()
        return json_response(a)

    else:
        return "No query string provided"


if os.environ.get("APP_LOCATION") == "heroku":
    run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
else:
    run(host="localhost", port=8080, debug=True)
