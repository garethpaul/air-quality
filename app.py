import os
from bottle import route, template, request, response, redirect, static_file, error, run

from json import dumps
from air import AirQuality
from geocode import GeoCode

@route('/')
def show_data():
    lat = float(request.query['lat'])
    lng = float(request.query['lng'])
    a = AirQuality(lat, lng).getData()
    response.content_type = 'application/json'
    return dumps(a)

@route('/s')
def search():
    query_string = request.query['query']
    if query_string:
        query_data = GeoCode(query_string).getLatLng()
        print(query_data)
        a = AirQuality(query_data['lat'], query_data['lng']).getData()
        response.content_type = 'application/json'
        return dumps(a)
        
    else:
        return "No query string provided"

if os.environ.get('APP_LOCATION') == 'heroku':
    run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
else:
    run(host='localhost', port=8080, debug=True)