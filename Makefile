override ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PYTHON_FILES := $(shell git -C "$(ROOT)" ls-files '*.py')

.PHONY: check lint test build

check: lint test build
	"$(ROOT)/scripts/check-baseline.sh"

lint:
	cd "$(ROOT)" && python -m ruff format --check .
	cd "$(ROOT)" && python -m ruff check .

test:
	cd "$(ROOT)" && python run_tests.py

build:
	cd "$(ROOT)" && python -m compileall -q $(PYTHON_FILES)
