#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKOUT_BLOCK = """      - name: Check out repository
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false"""


def checkout_credentials_are_isolated(workflow):
    return (
        workflow.count(CHECKOUT_BLOCK) == 1
        and workflow.count("actions/checkout@") == 1
        and workflow.count("persist-credentials:") == 1
    )


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def verify_contract_mutations():
    require(
        checkout_credentials_are_isolated(CHECKOUT_BLOCK),
        "canonical checkout block must pass",
    )
    mutations = {
        "writable credentials": CHECKOUT_BLOCK.replace("false", "true"),
        "missing with block": CHECKOUT_BLOCK.replace(
            "        with:\n          persist-credentials: false", ""
        ),
        "decoy setting": CHECKOUT_BLOCK.replace(
            "          persist-credentials: false", ""
        )
        + "\n      - run: echo 'persist-credentials: false'",
    }
    for name, mutation in mutations.items():
        require(
            not checkout_credentials_are_isolated(mutation),
            f"checkout contract accepted {name}",
        )


def main():
    verify_contract_mutations()
    for relative_path in (
        ".github/workflows/check.yml",
        ".github/workflows/codeql.yml",
    ):
        workflow = (ROOT / relative_path).read_text(encoding="utf-8")
        require(
            checkout_credentials_are_isolated(workflow),
            f"{relative_path} must contain exactly one canonical credential-free "
            "checkout step",
        )
    print("workflow checkout credential contracts passed")


if __name__ == "__main__":
    main()
