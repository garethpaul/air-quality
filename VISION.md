## Air Quality Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

Air Quality is a small Bottle API for answering a focused question: what is the
nearest PM2.5 air quality category for a location?

It accepts latitude/longitude coordinates directly, or resolves a search query
through Mapbox before looking up the nearest reading. Project overview and setup
details live in [`README.md`](README.md).

The goal is a dependable, easy-to-run service that can sit behind small apps,
demos, or automations that need a simple air-quality answer without adopting a
larger data platform.

The current focus is:

Priority:

- Keep the API behavior predictable for coordinate and search-query requests
- Maintain clear local setup with Python, Redis, Mapbox credentials, and the
  `AIRQUALITY_DATA` source
- Keep a provider-neutral small-instance deployment runbook with explicit
  preflight, TLS proxy, health-probe, secret, and rollback boundaries
- Preserve test, lint, and build commands that work in a fresh checkout
- Keep `make check` and `scripts/check-baseline.sh` green before pushing
  changes
- Make failure modes explicit when data, Redis, upstream payloads, or geocoding
  inputs are missing
- Convert malformed provider response shapes into controlled route errors
  before serializing responses
- Keep upstream HTTP calls bounded by default
- Bound upstream sensor response bytes before JSON decoding
- Require a non-negative Content-Length when the upstream supplies one
- Require a final `application/json` or `application/*+json` response media type
- Normalize unsupported response encodings before sensor payload processing
- Keep PM2.5 AQI calculations aligned with current EPA breakpoints
- Accept valid nonnegative PM2.5 readings and reject invalid sensor coordinates
- Bound search-query inputs before cache-key construction or Mapbox lookup
- Normalize geocoder transport failures without exposing provider details
- Ignore non-finite upstream sensor values before distance and AQI calculations
- Ignore overflowing upstream sensor values before distance and AQI calculations
- Reject non-finite or out-of-range geocoder coordinates before caching
- Overflowing Mapbox center values are rejected before coordinate caching.
- Ignore corrupt cached air-quality payloads before returning API data
- Keep cached air-quality responses limited to validated public response fields
- Ignore corrupt cached geocode coordinates before search lookups
- Keep current direct dependencies verified on Python 3.12 and 3.14

Next priorities:

- Continue improving data-source validation and error reporting
- Exercise the deployment runbook on an authorized hosted instance without
  committing provider-specific credentials or configuration
- Keep dependencies current enough to run on supported Python versions
- Expand tests around distinct empty datasets and invalid coordinate shapes

Contribution rules:

- One PR = one focused change. Do not bundle data ingestion, API behavior, and
  deployment changes together.
- Run `make check` before pushing changes.
- Update `scripts/check-baseline.sh` when required files or verification docs
  intentionally change.
- Keep API responses simple and documented; callers should not need to infer
  hidden service state.
- Prefer small fixes that preserve the current API over rewrites without a
  migration path.

## Security

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

This service depends on external credentials and URLs. Mapbox credentials,
Redis connection strings, and private data-source URLs must stay in environment
configuration and out of git.

Network-facing changes should fail closed when required configuration is
missing. Do not add request paths that expose raw credentials, Redis internals,
or unvalidated upstream data.

Streamed upstream responses should be closed deterministically on success and
failure so repeated requests do not retain connection resources.

The default sensor client should retain an HTTPS-only data source boundary
before requests, before following redirects, and on final response URLs so
deployment configuration cannot silently downgrade transport security.
It should also require globally reachable unicast literal and DNS-resolved
targets while documenting that deployment DNS remains trusted between
preflight and connect.

## What We Will Not Merge (For Now)

- Large framework rewrites that do not preserve the existing endpoint behavior
- New geocoding or air-quality providers without tests and configuration docs
- UI features that belong in a client application rather than this API
- Silent fallbacks that hide missing data, credentials, or upstream failures

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
