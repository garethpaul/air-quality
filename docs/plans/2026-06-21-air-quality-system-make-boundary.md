# Air Quality System Make Boundary

Status: Completed

## Problem

Hosted and documented verification invoked `make` through `PATH`. A caller or
runner image could therefore select a different executable before the checked-in
Makefile had any opportunity to enforce repository verification behavior.

## Work Completed

- Bound both GitHub repository gates and all CircleCI target steps to
  `/usr/bin/make`.
- Froze literal Python and Git selections, `/bin/sh`, and the canonical
  repository root across every public target.
- Rejected startup files, replaced Makefile lists, unsafe execution modes,
  executable Make syntax, PATH-selected Git, and later single-colon recipe
  replacement.
- Added an executable adversarial authority harness to `make check`.
- Updated contributor and deployment commands to use the same executable.
- Extended the portable baseline contract to reject workflow or README drift
  back to a PATH-selected Make invocation.

## Verification

- Run `/usr/bin/make check` from the repository root.
- Run `/usr/bin/make -f <checkout>/Makefile check` from an unrelated directory.
- Run the baseline checker against hostile workflow mutations that replace the
  trusted executable with `make`.
- Run `scripts/test-makefile-root.sh` to cover 30 target/authority cases, six
  raw Make-syntax controls, startup and list boundaries, six later single-colon
  recipe replacements, explicit caller-added recipe and override-shell boundary
  controls, PATH boundaries, and ten unsupported modes.

## Scope Boundary

This change does not alter API behavior, dependencies, deployment
configuration, credentials, or Redis/Mapbox integration. Explicit literal
Python and Git selections remain supported caller authority.
Caller-supplied additional makefiles remain outside the repository-controlled boundary: GNU Make still executes appended double-colon recipes and target-specific override directives from later `-f` files.
