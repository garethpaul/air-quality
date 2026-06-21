.DEFAULT_GOAL := check
.PHONY: __repository-make-authority audit build check lint root-test test
.SECONDEXPANSION:

override SHELL := /bin/sh
override .SHELLFLAGS := -c
audit build check lint root-test test __repository-make-authority: override SHELL := /bin/sh
audit build check lint root-test test __repository-make-authority: override .SHELLFLAGS := -c

ifeq ($(origin PYTHON),undefined)
override PYTHON := $(shell /bin/sh -c 'command -v python')
else
override PYTHON := $(value PYTHON)
endif
export PYTHON
GIT ?= /usr/bin/git
override GIT := $(value GIT)
export GIT

override REPOSITORY_MAKE_DOLLAR := $$
override REPOSITORY_MAKE_OPEN := (
override REPOSITORY_MAKE_OPEN_BRACE := {
define REPOSITORY_REJECT_MAKE_SYNTAX
ifneq ($$(findstring $$(REPOSITORY_MAKE_DOLLAR)$$(REPOSITORY_MAKE_OPEN),$$(value $(1))),)
$$(error $(1) must be a literal value, not Make syntax)
endif
ifneq ($$(findstring $$(REPOSITORY_MAKE_DOLLAR)$$(REPOSITORY_MAKE_OPEN_BRACE),$$(value $(1))),)
$$(error $(1) must be a literal value, not Make syntax)
endif
endef
$(foreach variable,PYTHON GIT,$(eval $(call REPOSITORY_REJECT_MAKE_SYNTAX,$(variable))))

ifeq ($(strip $(PYTHON)),)
$(error python is unavailable; activate the supported environment or set PYTHON to a literal executable)
endif
ifeq ($(strip $(GIT)),)
$(error git is unavailable; set GIT to a literal executable)
endif

ifneq ($(filter command line,$(origin MAKEFLAGS)),)
$(error MAKEFLAGS must not be overridden for repository verification)
endif
override REPOSITORY_MAKE_FIRST_FLAGS := $(firstword $(MAKEFLAGS))
ifneq ($(filter -%,$(REPOSITORY_MAKE_FIRST_FLAGS)),)
override REPOSITORY_MAKE_FIRST_FLAGS :=
endif
override REPOSITORY_MAKE_SHORT_FLAGS := $(REPOSITORY_MAKE_FIRST_FLAGS) $(filter-out --%,$(filter -%,$(MAKEFLAGS)))
ifneq ($(findstring n,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring t,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring q,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring i,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(filter --just-print --dry-run --recon --touch --question --ignore-errors,$(MAKEFLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif

override ROOT := $(shell path='$(subst ','"'"',$(value MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /usr/bin/sed 's/^ //'); [ -f "$$path" ] || exit 1; directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)
export ROOT
ifeq ($(strip $(ROOT)),)
$(error repository Makefile path could not be resolved)
endif

override REPOSITORY_SHELL_LITERAL = $(subst $$,$$$$,$(subst ','"'"',$1))
override REPOSITORY_ROOT_LITERAL := $(call REPOSITORY_SHELL_LITERAL,$(ROOT))
override REPOSITORY_PYTHON_LITERAL := $(call REPOSITORY_SHELL_LITERAL,$(PYTHON))
override REPOSITORY_GIT_LITERAL := $(call REPOSITORY_SHELL_LITERAL,$(GIT))
override PYTHON_FILES := $(shell '$(REPOSITORY_GIT_LITERAL)' -C '$(REPOSITORY_ROOT_LITERAL)' ls-files '*.py')

audit build check lint root-test test:: $$(if $$(filter file,$$(origin MAKEFILE_LIST)),,$$(error MAKEFILE_LIST must not be overridden))
audit build check lint root-test test:: $$(if $$(shell path=$$$$(/usr/bin/printf '%s' '$$(subst ','"'"',$$(MAKEFILE_LIST))' | /usr/bin/sed 's/^ //') && [ -f "$$$$path" ] && /usr/bin/printf '%s' ok),,$$(error repository Makefile must be loaded alone))
audit build check lint root-test test:: __repository-make-authority

__repository-make-authority::
	@:

define REPOSITORY_PUBLIC_RECIPES
lint::
	cd '$(REPOSITORY_ROOT_LITERAL)' && '$(REPOSITORY_PYTHON_LITERAL)' -I -B -m ruff format --check .
	cd '$(REPOSITORY_ROOT_LITERAL)' && '$(REPOSITORY_PYTHON_LITERAL)' -I -B -m ruff check .

audit::
	cd '$(REPOSITORY_ROOT_LITERAL)' && '$(REPOSITORY_PYTHON_LITERAL)' -I -B -m pip_audit --index-url https://pypi.org/simple -r requirements.txt

test::
	cd '$(REPOSITORY_ROOT_LITERAL)' && '$(REPOSITORY_PYTHON_LITERAL)' -I -B run_tests.py

build::
	cd '$(REPOSITORY_ROOT_LITERAL)' && '$(REPOSITORY_PYTHON_LITERAL)' -I -B -m compileall -q $(PYTHON_FILES)

root-test::
	/bin/sh '$(REPOSITORY_ROOT_LITERAL)/scripts/test-makefile-root.sh'

check:: root-test lint audit test build
	/bin/sh '$(REPOSITORY_ROOT_LITERAL)/scripts/check-baseline.sh'
endef

$(eval $(REPOSITORY_PUBLIC_RECIPES))
