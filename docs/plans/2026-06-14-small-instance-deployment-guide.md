# Small-Instance Deployment Guide

Status: Completed

## Problem

The repository documents local development but does not provide one operational
path for running the API on a small hosted instance. An operator currently has
to infer the required environment, public binding mode, TLS boundary, health
probe, and rollback procedure from source files.

## Requirements

1. Add a provider-neutral deployment guide for a single process behind a TLS
   reverse proxy.
2. Name every required runtime variable without including real credentials or
   copy-paste secret values.
3. Define preflight, launch, bounded health-probe, log, backup, rollback, and
   incident-response steps.
4. Keep deployment commands aligned with the existing `Procfile`, application
   binding behavior, and canonical `make check` gate.
5. Add mutation-sensitive portable contracts for the guide and its completion
   evidence.

## Scope Boundaries

- Do not add a cloud provider, container image, process supervisor, proxy
  configuration, or infrastructure-as-code stack.
- Do not change application behavior, environment variable names, ports,
  dependencies, routes, or public response formats.
- Do not claim live Redis, Mapbox, upstream sensor, TLS, or deployed-service
  verification.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- `sh -n scripts/check-baseline.sh`, `python run_tests.py`,
  `python -m ruff format --check .`, and `python -m ruff check .` passed; the
  runtime suite executed all 65 tests.
- Repository-root and external-working-directory `make check` passed Ruff,
  all 65 tests, bytecode compilation, and the portable baseline contracts.
- Twelve hostile mutations were rejected for removing the guide, a required
  runtime variable, non-root execution, the bounded health probe, rollback,
  the live-verification boundary, README links, or completion evidence.
- No live Redis, Mapbox, sensor-feed, TLS-proxy, or deployed-instance verification is claimed.
