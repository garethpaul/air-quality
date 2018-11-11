import os

from bottle import route, template, request, response, redirect, static_file, error, run
from json import dumps
from test import AirQuality


@route('/')
def show_data():
    lat = float(request.query['lat'])
    lng = float(request.query['lng'])
    a = AirQuality(lat, lng).getData()
    response.content_type = 'application/json'
    return dumps(a)

if os.environ.get('APP_LOCATION') == 'heroku':
    run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
else:
    run(host='localhost', port=8080, debug=True)