# Verify Runner Execution And Verdicts

Status: Completed

## Problem

Every contract binding a runner into `make check` was a substring text pin, so
the pins were satisfied by text that never executes. Probing the gate proved
seven ways to disable verification while `make check` stayed green:

- Commenting out the `scripts/test-makefile-root.sh` recipe line, or moving it
  verbatim into an unused target, silently removed all 30 Make authority cases.
  The harness is its own only oracle, so a neutered `root-test` recipe cannot be
  detected by the harness itself.
- Commenting out the `scripts/test-baseline-python-selection.sh` recipe line
  silently removed the reviewed-interpreter contract.
- Commenting out the `scripts/check-workflow-checkout.py` invocation inside
  `scripts/check-baseline.sh` silently removed the checkout credential contract;
  the substring pin matched the commented-out line.
- Reducing `scripts/test-makefile-root.sh` to its own closing success `printf`
  satisfied all ten pinned vocabulary strings, which occur only on that one
  line, and printed the usual reassuring success message.
- Reducing `scripts/test-baseline-python-selection.sh` to a stub that prints its
  success message satisfied both of the harness's re-invocations of it.
- Replacing `scripts/check-workflow-checkout.py` with a stub that prints its
  success message satisfied every contract on it.
- Dropping `air_tests` from `run_tests.py` silently reduced the suite from 111
  tests to 47.
- Dropping the result check from `run_tests.py` left `make check` green while
  its own output reported `FAILED (failures=1)`.

Text pins cannot close this: a whole-line pin is still satisfied by the same
line relocated into an unused target or an unreachable branch. Only observing
execution, and planting defects a stub cannot detect, closes it.

## Work Completed

- Required `make check` to dispatch `run_tests.py`,
  `scripts/test-baseline-python-selection.sh`, and `scripts/check-baseline.sh`,
  matching the sandbox dispatch log whole-line so a neutered recipe that merely
  mentions a runner cannot satisfy it.
- Required `make check` to dispatch `scripts/test-makefile-root.sh`, observed
  from `scripts/check-baseline.sh` because the harness cannot witness its own
  invocation.
- Required the Make authority harness to reject a no-op Makefile and a Makefile
  whose `ROOT` the caller can override, so its vocabulary contracts describe a
  harness that still tests something.
- Required the baseline Python selection harness to reject a missing and a
  non-executable `REPOSITORY_PYTHON`.
- Required the workflow checkout checker to accept the canonical workflows
  copied verbatim and to reject a planted `persist-credentials: true` defect.
- Required `run_tests.py` to exit nonzero for a planted failing suite, and to
  execute every discovered `*_tests.py` module.
- Surfaced the captured output when the selection harness case fails, so a
  nested contract failure reports its message instead of a bare exit status.

## Verification

- Run `/usr/bin/make check` from the repository root.
- Run `/usr/bin/make -f <checkout>/Makefile check` from an unrelated directory.
- Re-apply each mutation above and confirm the named contract fails.
- Remove any single added contract, re-apply its mutation, and confirm the gate
  returns to green, proving each contract is load-bearing.

## Scope Boundary

This change does not alter API behavior, dependencies, deployment
configuration, credentials, or Redis/Mapbox integration. It adds no new runner
and changes no existing verification command.

The pinned harness vocabulary strings remain satisfiable by the harness's own
success `printf`; the planted-defect controls, not the vocabulary pins, are what
make that harness load-bearing. The whole-line pin on the workflow checkout
invocation remains satisfiable by the same line relocated into an unreachable
branch; the planted-defect control covers that contract's substance by checking
verbatim copies of the real workflows.
