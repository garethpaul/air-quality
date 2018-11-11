import os

from bottle import route, template, redirect, static_file, error, run


@route('/')
def show_home():
    return "Hello World!"

if os.environ.get('APP_LOCATION') == 'heroku':
    run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
else:
    run(host='localhost', port=8080, debug=True)