## Air Quality Vision

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
- Preserve test, lint, and build commands that work in a fresh checkout
- Make failure modes explicit when data, Redis, or geocoding inputs are missing

Next priorities:

- Improve data-source validation and error reporting
- Add clearer deployment guidance for small hosted instances
- Keep dependencies current enough to run on supported Python versions
- Expand tests around empty datasets, invalid coordinates, and Mapbox failures

Contribution rules:

- One PR = one focused change. Do not bundle data ingestion, API behavior, and
  deployment changes together.
- Run `make lint`, `make test`, and `make build` before pushing changes.
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

## What We Will Not Merge (For Now)

- Large framework rewrites that do not preserve the existing endpoint behavior
- New geocoding or air-quality providers without tests and configuration docs
- UI features that belong in a client application rather than this API
- Silent fallbacks that hide missing data, credentials, or upstream failures

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
