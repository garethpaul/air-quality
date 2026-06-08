# Air Quality

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

Small Bottle app that returns the nearest PM2.5 air quality category for a
latitude and longitude, or for a search query resolved through Mapbox.

## Requirements

- Python 3.8
- Redis
- Mapbox credentials available to the `mapbox` package
- An `AIRQUALITY_DATA` URL that returns a JSON document with a `results` array

## Setup

```sh
python -m venv venv
. venv/bin/activate
python -m pip install -r requirements.txt -r requirements-dev.txt
```

## Run

```sh
export REDIS_URL=redis://localhost:6379/0
export AIRQUALITY_DATA=https://example.com/air-quality.json
python app.py
```

Query by coordinates:

```sh
curl 'http://localhost:8080/?lat=37.794678&lng=-122.41143'
```

Query by place name:

```sh
curl 'http://localhost:8080/s?query=San%20Francisco%2C%20CA'
```

## Quality Gates

Run these before pushing changes:

```sh
make lint
make test
make build
```
