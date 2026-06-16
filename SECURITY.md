# Security Policy

## Supported Versions

The supported security scope for `air-quality` is the current default branch, `master`. Older commits, tags, branches, forks, demos, and generated artifacts are not actively supported unless the repository explicitly marks them as maintained.

Project summary: Python Bottle API for Getting Air Quality based on Lat/Lng or Query String

## Reporting a Vulnerability

Please report suspected vulnerabilities through GitHub's private vulnerability reporting or by opening a draft GitHub Security Advisory for `garethpaul/air-quality` when that option is available. If GitHub does not show a private reporting option for this repository, contact the repository owner through GitHub and avoid posting exploit details publicly until the issue can be assessed.

Do not open a public issue that includes exploit code, secrets, personal data, or detailed reproduction steps for an unpatched vulnerability.

## What to Include

Helpful reports include:

- the affected file, endpoint, permission, dependency, or workflow
- a concise impact statement explaining what an attacker could do
- reproduction steps using test data and accounts you control
- the branch, commit SHA, platform version, device, runtime, or dependency versions used
- logs, screenshots, or proof-of-concept snippets that demonstrate impact without exposing private data

## Project Security Posture

- This repository appears to be a Python web API or service project. The active security scope is the code and documentation on the default branch.
- Review found network clients, sockets, web APIs, or service endpoints; changes in those areas should receive security-focused review before merge.
- Review found mobile permission or privacy-sensitive data handling; changes in those areas should receive security-focused review before merge.
- Review found file, document, data, or media parsing flows; changes in those areas should receive security-focused review before merge.
- Review found database, model, query, or persistence-related code; changes in those areas should receive security-focused review before merge.
- Review found infrastructure, deployment, proxy, or cloud configuration; changes in those areas should receive security-focused review before merge.
- Dependency manifests detected: requirements.txt, pyproject.toml. Dependency updates should preserve lockfiles when present and avoid introducing packages without a clear maintenance reason.

## Service and API Notes

For web services, APIs, sockets, or scraping workflows, prioritize reports involving authentication bypass, authorization errors, injection, server-side request forgery, unsafe deserialization, credential leakage, data exposure, or denial-of-service conditions. Use test accounts and minimal proof-of-concept traffic only.

Cached upstream and geocode data should be validated before reuse. Corrupt
geocode cache entries should be refreshed from Mapbox rather than returned to
callers or used as coordinates.
Overflowing cached numeric values are ignored and refreshed before conversion
errors can escape the cache validation boundary.
Cached AQI guidance is accepted only when its 0-500 score, category, and
caution match the canonical response.

The default sensor-data client uses a timeout and a 1 MiB streamed response
limit, checked before extending the retained response buffer. HTTP failures,
oversized bodies, malformed JSON, and supplied values
that violate non-negative Content-Length syntax (ASCII decimal digits only)
should fail before sensor payload processing, as should missing or non-JSON
`application/json` or `application/*+json` response media types and
unsupported response encodings.
Non-finite and overflowing upstream sensor values are ignored before distance
or AQI calculations.
Boolean upstream sensor values are ignored before distance and AQI calculations.
Boolean scoring helper inputs are rejected before numeric conversion.
Non-finite scoring helper inputs are rejected before interpolation or category
construction.
Zero-width AQI interpolation ranges are rejected before division.
Descending AQI interpolation ranges are rejected before division.
Negative AQI scores are classified as Out of Range instead of Good.
Near-antipodal sensor distances clamp floating-point drift to the haversine
domain instead of turning valid coordinates into a service failure.
Direct AirQuality construction rejects boolean, nonnumeric, non-finite, and out-of-range coordinates.
Route coordinate validation rejects boolean and overflowing numeric values before AirQuality construction.
Accepted signed-zero coordinates normalize to positive zero so equivalent requests share one cache key.
Mapbox and cached geocoder signed-zero coordinates normalize to positive zero
before use or cache serialization.
Overflowing Mapbox center values are rejected before coordinate caching.
Boolean Mapbox and cached geocoder coordinates are rejected instead of being
normalized to numeric locations.
The response is closed after successful reads and all validation failures so
pooled connections are not retained indefinitely.
Requests transport failures are normalized to a generic local service error
without preserving provider URLs, status text, or exception details in the
public error path.
Geocoder transport failures during Mapbox client creation, request dispatch,
or JSON decoding are normalized to a generic local service error without
preserving provider, token, or exception details in the public error path.
Cache command failures are normalized to the same generic service boundary
without retrying, bypassing Redis, or preserving Redis URLs and dependency
exception details in the public error path.
The default `AIRQUALITY_DATA` client enforces an HTTPS-only data source before
the request, before each redirect is followed, and on the final response URL.
Plaintext endpoints and redirect downgrades fail with a generic local error
while created responses are still closed. Credential-bearing URL authorities
are rejected before DNS resolution. Literal and DNS-resolved targets also fail
unless every IPv4 or IPv6 address is globally reachable. This policy
additionally rejects multicast targets, which Python classifies as global but
which are not valid unicast service endpoints. This preflight does not pin the
subsequent Requests connection to a validated address, so deployment DNS
remains part of the trusted infrastructure boundary.

## Dependency and Supply Chain Security

Dependency updates should come from trusted package managers and should keep lockfiles in sync when lockfiles exist. Do not commit credentials, private keys, tokens, generated secrets, or machine-local configuration. If a vulnerability depends on a compromised package, typosquatting risk, insecure transitive dependency, or unsafe build step, include the package name, affected version, and the path through which it is used.

The maintained dependency baseline uses exact direct pins and is exercised on
Python 3.12 and 3.14 in immutable, read-only GitHub Actions jobs with checkout
credential persistence disabled. AWS SDK
packages are resolved through Mapbox instead of being duplicated as
application-level pins.

## Safe Research Guidelines

Good-faith research is welcome when it stays within these boundaries:

- use only accounts, devices, data, and infrastructure that you own or have explicit permission to test
- avoid destructive actions, persistence, spam, phishing, social engineering, or denial-of-service testing
- minimize access to personal data and stop testing immediately if private data is exposed
- do not exfiltrate secrets or third-party data; report the minimum evidence needed to verify impact
- keep vulnerability details confidential until the maintainer has assessed the report

## Maintainer Response

The maintainer will review complete reports as availability allows, prioritize issues by exploitability and impact, and coordinate a fix or mitigation when the affected code is still maintained. For sample, archived, or educational repositories, the likely remediation may be documentation, dependency updates, or clearly marking unsupported code rather than a production-style patch release.

## Automated Analysis

GitHub Actions runs immutable-pinned CodeQL analysis for workflow and Python
sources. Public route errors use stable messages and do not serialize caught
exception details, environment values, provider responses, or stack traces.
