# Air Quality Checkout Credential Contract

Status: Completed

## Scope

Keep the Check and CodeQL workflows verification-only by binding their
credential-isolation setting to the immutable checkout step.

## Baseline

Both workflows already set `persist-credentials: false`, but the portable
baseline searched each complete workflow for that text. A decoy comment or
command could therefore hide checkout with default or writable credentials.

## Implementation

- Add a dependency-free workflow checkout contract helper.
- Require exactly one canonical checkout block and one credential setting in
  each workflow.
- Reject writable credentials, a missing `with` block, and decoy-only text.
- Run the helper from the existing baseline and document the guarantee.

## Verification

- Install the exact runtime and development requirements in an isolated Python
  3.12 environment and run the package compatibility check.
- Run `make check` from the repository root and through the absolute Makefile
  from an external working directory.
- Confirm all three hostile checkout mutations fail the helper contract.
- Run `git diff --check`, strict repository integrity checks, and a changed-file
  credential-shape scan.
