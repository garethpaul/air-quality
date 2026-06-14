# Make Root Override Protection

Status: Planned

## Problem

The Makefile-derived repository root anchors Ruff, runtime tests, compilation,
and the baseline contract script, but an ordinary assignment can be replaced
by a command-line `ROOT` value. Verification can therefore be redirected away
from the reviewed checkout.

## Requirements

1. Protect the Makefile-derived root with GNU Make's `override` directive.
2. Preserve every existing lint, test, build, and baseline command.
3. Require the exact protected root and rooted command paths in the shell
   baseline checker.
4. Pass local, external-working-directory, and hostile-root full gates under
   the exact development dependency set.
5. Reject focused mutations covering root derivation, rooted commands, and
   completed-plan status.

## Verification

- Run the focused shell contract before the full package gate.
- Run bounded local, external-working-directory, and hostile `ROOT` full
  `make check` gates.
- Run the exact dependency integrity and vulnerability audits.
- Run focused mutations and structured workflow/config checks.
- Inspect the exact diff and scan changed lines for credentials and generated
  artifacts before committing only intended paths.

## Scope Boundaries

- Do not change API behavior, dependencies, provider configuration, workflows,
  or public response formats.
- Do not merge or close any pull request without explicit owner authorization.
