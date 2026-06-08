PYTHON_FILES := $(shell git ls-files '*.py')

.PHONY: check lint test build

check: lint test build

lint:
	python -m ruff format --check .
	python -m ruff check .

test:
	python run_tests.py

build:
	python -m compileall -q $(PYTHON_FILES)
