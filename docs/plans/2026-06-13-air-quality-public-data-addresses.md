---
title: Air Quality Public Data Addresses
date: 2026-06-13
type: implementation-plan
---

# Air Quality Public Data Addresses

Status: Completed

## Summary

Require the default `AIRQUALITY_DATA` transport to resolve only globally
reachable unicast IPv4 or IPv6 addresses before the initial request and every
redirect, without changing injected clients or public route behavior.

## Problem Frame

The existing transport requires HTTPS and rejects redirect downgrades, but an
HTTPS URL can still name loopback, link-local, private, shared, reserved, or
otherwise non-global infrastructure. That leaves the configured fetch path able
to cross an unintended network boundary.

## Requirements

- R1. Reject literal IP hosts unless Python classifies the address as globally
  reachable and non-multicast, and reject credential-bearing URL authorities
  before host resolution.
- R2. Resolve DNS hostnames before dispatch and reject the host if resolution
  fails, returns no addresses, or returns any non-global address.
- R3. Apply the address policy before the initial request, before Requests
  follows each redirect, and before final response processing.
- R4. Close redirect responses rejected by the address policy and retain exact
  cleanup for every returned final response.
- R5. Return stable local errors without exposing configured hostnames,
  resolved addresses, or resolver diagnostics.
- R6. Preserve HTTPS, timeout, streaming, size, JSON, cache, AQI, Redis,
  Mapbox, and injected-client behavior.
- R7. Add no-network tests and mutation-sensitive portable contracts for IPv4,
  IPv6, mixed DNS answers, resolution failures, ordering, cleanup, docs, and
  completed verification evidence.

## Key Technical Decisions

- **Fail closed on every DNS answer:** accepting a hostname only when every
  returned address is global avoids nondeterministically connecting to a
  private answer from a mixed result set.
- **Use standard-library classification:** `socket.getaddrinfo` supplies IPv4
  and IPv6 candidates; `ipaddress` supplies maintained global and multicast
  classification without a new dependency.
- **Keep injected clients unchanged:** the policy belongs to the repository's
  default network transport; deterministic callers that inject `http_get`
  retain their existing contract.

## Assumptions

- Production `AIRQUALITY_DATA` hosts are intended to resolve exclusively to
  globally reachable addresses.
- A preflight DNS policy materially reduces SSRF exposure but cannot eliminate
  DNS rebinding between validation and Requests' connection-time resolution.

## Implementation Units

### U1. Validate Public Data Addresses

- **Files:** `air.py`
- **Goal:** Extend URL validation with literal-address and DNS-result checks,
  using a generic failure boundary and the existing redirect/final URL gates.
- **Test scenarios:** A public IPv4 literal passes; loopback and private IPv4
  literals fail; loopback IPv6 fails; a hostname with public answers passes;
  mixed public/private answers, empty answers, malformed answers, and resolver
  failures fail before request dispatch.

### U2. Prove Dispatch And Redirect Ordering

- **Files:** `air_tests.py`
- **Goal:** Use resolver and Requests fakes to prove the policy runs before the
  initial request, before redirect following, and before final status/body
  handling while preserving response cleanup.
- **Test scenarios:** A private initial host makes no request; a private
  redirect closes its response; a private final URL is rejected before status
  validation; public initial and relative redirect URLs retain the bounded JSON
  path.

### U3. Preserve The Durable Contract

- **Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`,
  `VISION.md`, `CHANGES.md`,
  `docs/plans/2026-06-13-air-quality-public-data-addresses.md`
- **Goal:** Require the address classifier, all three validation positions,
  generic errors, regression tests, operational guidance, and completed
  verification evidence.
- **Verification:** Focused tests, full local and external-directory checks,
  hostile mutations, syntax/workflow parsing, exact-diff artifact and secret
  scans, and whitespace validation must pass without live provider access.

## Scope Boundaries

- Do not add retries, change timeout or response-size limits, or alter cache and
  public route contracts.
- Do not pin Requests to a pre-resolved address or claim protection against DNS
  rebinding between validation and connection.
- Do not add a configurable host allowlist in this unit.
- Do not exercise live Redis, Mapbox, or `AIRQUALITY_DATA` services without
  deployment credentials.

## Verification Completed

- Focused default-transport coverage passed 40 no-network tests, including
  public literals and hostnames, credential-bearing authorities, private and
  multicast IPv4/IPv6 literals, mixed and empty DNS results, resolver failures,
  redirect rejection, final-URL ordering, and exact response cleanup.
- The full behavior gate passed 57 tests; Ruff formatting and lint checks plus
  Python compilation also passed.
- The portable checker requires the public-address classifier, fail-closed DNS
  handling, all three existing URL-validation positions, regression tests,
  completed plan evidence, and documentation of the trusted-DNS boundary.
- Thirteen isolated hostile mutations were rejected across the generic error,
  any-answer quantifier, multicast exclusion, empty-result handling, resolver
  exception boundary, validation call, userinfo rejection, required tests,
  documentation, and completed plan status.
- Live Redis, Mapbox, and `AIRQUALITY_DATA` integrations were not exercised;
  resolver and Requests behavior used deterministic fakes without credentials.

## Sources

- Python `ipaddress` documentation:
  https://docs.python.org/3/library/ipaddress.html
- Python `socket.getaddrinfo` documentation:
  https://docs.python.org/3/library/socket.html#socket.getaddrinfo
- Requests event-hook documentation:
  https://requests.readthedocs.io/en/latest/user/advanced/#event-hooks
