# Make Root Override Protection

Status: Completed

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

## Work Completed

- Protected the Makefile-derived root while preserving every existing package
  and baseline command.
- Added exact shell contracts for the protected root, rooted Python file list,
  four rooted package commands, rooted baseline script, and this completed
  plan.

## Verification Completed

- The focused shell baseline contract passed.
- Local, external-working-directory, and hostile `ROOT` full `make check`
  gates each passed Ruff formatting/lint, 59 runtime tests, Python compilation,
  and the shell baseline contracts under the exact dependency set.
- `uv pip check` passed for 20 installed packages, and `pip-audit==2.10.0`
  reported no known vulnerabilities in either requirements file.
- Eight focused root, command-path, and plan-status mutations were rejected.
- Workflow/config, whitespace, explicit-artifact, exact-diff, and changed-line
  credential audits passed before shipment.
