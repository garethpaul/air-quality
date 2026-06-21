# Msgpack Security Audit

Status: Completed

## Problem

The direct runtime pins allowed the Mapbox/CacheControl dependency graph to
resolve `msgpack 1.1.2`, which is affected by `GHSA-6v7p-g79w-8964`.
Neither local verification nor hosted CI audited the resolved graph.

## Change

- Pin `msgpack 1.2.1`, the fixed release, as a direct runtime constraint.
- Pin `pip-audit 2.10.0` as a development verification dependency.
- Add `make audit` to the canonical `make check` gate used locally, in GitHub
  Actions, and in CircleCI.
- Bind the new dependency and audit commands in the baseline contract.

## Verification Results

- A fresh dependency installation completed from the reviewed pins.
- `make check` passed from the repository and an external working directory.
- `python -m pip_audit --index-url https://pypi.org/simple -r requirements.txt`
  reported no known vulnerabilities.
