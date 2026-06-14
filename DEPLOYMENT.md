# Small-Instance Deployment

This runbook describes a single Air Quality process on a small hosted instance
behind a TLS-terminating reverse proxy. It is provider-neutral and does not add
an infrastructure stack to the repository.

## Runtime Boundary

- Run a supported Python version from `.python-version` as an unprivileged
  service account.
- Expose the application port only to the local reverse proxy or private
  network. Do not publish the Bottle listener directly to the internet.
- Terminate HTTPS at the reverse proxy and forward requests to the configured
  local `PORT`.
- Run one application process per instance. This service has no background
  workers or repository-managed database migrations.

## Required Configuration

Supply configuration through the host's secret manager or service environment.
Do not write values into the checkout, process command line, shell history, or
unit files committed to git.

| Variable | Purpose |
| --- | --- |
| `APP_LOCATION` | Set to `heroku` to bind the Bottle process to `0.0.0.0`. |
| `PORT` | Internal application listener forwarded to by the reverse proxy. |
| `REDIS_URL` | Redis connection used by air-quality and geocode caches. |
| `MAPBOX_ACCESS_TOKEN` | Mapbox credential used by search requests. |
| `AIRQUALITY_DATA` | HTTPS URL for the upstream JSON sensor feed. |

The `AIRQUALITY_DATA` host and every redirect must resolve only to globally
reachable unicast addresses. The final response must use an
`application/json` or `application/*+json` media type and fit within the
service's 1 MiB response limit.

## Preflight

From a fresh release checkout:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install --requirement requirements.txt
.venv/bin/python -m pip check
.venv/bin/python run_tests.py
make check
```

Confirm separately that:

1. the reverse proxy certificate and hostname are correct;
2. only the proxy can reach the application port;
3. Redis accepts a connection from the service network;
4. the Mapbox token is scoped and active; and
5. `AIRQUALITY_DATA` returns the documented JSON schema over HTTPS.

## Launch

Start the repository's existing process command after injecting the required
environment through the service manager:

```sh
python app.py
```

`Procfile` contains the same process command. Keep restart policy, resource
limits, log routing, and environment injection in the host service manager.
Never run the process as root.

## Health Probe

After the proxy is serving the release, issue a bounded request with known
valid coordinates:

```sh
curl --fail --silent --show-error --max-time 15 \
  'https://service.example/?lat=37.794678&lng=-122.41143'
```

A successful JSON response verifies the proxy, application process, Redis, and
sensor-feed path. Also probe `/s?query=San%20Francisco%2C%20CA` when validating
the Mapbox path. Treat `503` as a dependency or configuration failure and
investigate service-manager, proxy, and dependency logs without printing secret
values.

## Release And Rollback

1. Record the deployed commit SHA and keep the previous release checkout
   available until the health probe passes.
2. Deploy immutable source from a reviewed commit; do not edit the live
   checkout.
3. Restart the service, run the bounded health probe, and inspect error rates.
4. On failure, restore the previous release checkout and its known-compatible
   environment, restart the service, and repeat the same probe.
5. Rotate any credential that appears in logs, shell history, or an exposed
   environment dump before returning the instance to service.

Redis is a cache, not the source of record. Backup and retention policy belongs
to the upstream sensor source and deployment platform; a rollback must not
depend on restoring cached entries.

## Verification Boundary

Repository checks validate this runbook's required operational contracts. They
do not prove a live Redis service, Mapbox account, sensor feed, TLS proxy,
firewall, service manager, or deployed instance. Those checks must be completed
in the target environment for every release.
