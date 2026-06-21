#!/usr/bin/env sh
set -eu

PATH=/usr/bin:/bin
export PATH
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && /bin/pwd -P)
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/air-quality-make-authority-XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
unset GIT MAKEFILES MAKEFILE_LIST MAKEFLAGS MFLAGS MAKEOVERRIDES PYTHON ROOT SHELL

CONTROL_DIR="$TEMP_ROOT/control"
CHECKOUT="$TEMP_ROOT/air app's [gate] \"quoted\" \`touch AIR_ROOT_MARKER\`"
ATTACKER_ROOT="$TEMP_ROOT/attacker"
AUTHORITY_PATH="$TEMP_ROOT/no-tools"
LOG="$TEMP_ROOT/commands.log"
SHELL_LOG="$TEMP_ROOT/shell.log"
mkdir -p "$CONTROL_DIR" "$CHECKOUT/scripts" "$ATTACKER_ROOT" "$AUTHORITY_PATH"
CONTROL_DIR=$(CDPATH= cd -- "$CONTROL_DIR" && /bin/pwd -P)
CHECKOUT=$(CDPATH= cd -- "$CHECKOUT" && /bin/pwd -P)
MAKEFILE="$CHECKOUT/Makefile"
cp "$ROOT_DIR/Makefile" "$MAKEFILE"

FAKE_PYTHON="$TEMP_ROOT/trusted python's \"quoted\" \`touch AIR_PYTHON_MARKER\` \$literal"
cat >"$FAKE_PYTHON" <<'SCRIPT'
#!/bin/sh
printf 'python|%s|%s|%s\n' "$PWD" "$0" "$*" >> "$AIR_QUALITY_COMMAND_LOG"
SCRIPT
chmod +x "$FAKE_PYTHON"

FAKE_GIT="$TEMP_ROOT/trusted git's quoted"
cat >"$FAKE_GIT" <<'SCRIPT'
#!/bin/sh
printf 'git|%s|%s|%s\n' "$PWD" "$0" "$*" >> "$AIR_QUALITY_COMMAND_LOG"
printf '%s\n' air.py app.py geocode.py run_tests.py
SCRIPT
chmod +x "$FAKE_GIT"

for script in check-baseline.sh test-makefile-root.sh; do
  cat >"$CHECKOUT/scripts/$script" <<'SCRIPT'
#!/bin/sh
printf 'script|%s|%s|%s\n' "$PWD" "$0" "$*" >> "$AIR_QUALITY_COMMAND_LOG"
SCRIPT
  chmod +x "$CHECKOUT/scripts/$script"
done

FAKE_SHELL="$TEMP_ROOT/fake-shell"
cat >"$FAKE_SHELL" <<'SCRIPT'
#!/bin/sh
printf invoked >> "$AIR_QUALITY_SHELL_LOG"
exec /bin/sh "$@"
SCRIPT
chmod +x "$FAKE_SHELL"

run_case() {
  target=$1
  mode=$2
  output="$TEMP_ROOT/case.out"
  rm -f "$LOG" "$SHELL_LOG" "$output"
  : >"$ATTACKER_ROOT/keep"
  set +e
  case "$mode" in
    default)
      (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" "$target") >"$output" 2>&1
      ;;
    command-root)
      (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" ROOT="$ATTACKER_ROOT" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" "$target") >"$output" 2>&1
      ;;
    environment-root)
      (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" ROOT="$ATTACKER_ROOT" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" "$target") >"$output" 2>&1
      ;;
    command-shell)
      (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" AIR_QUALITY_SHELL_LOG="$SHELL_LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" SHELL="$FAKE_SHELL" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" "$target") >"$output" 2>&1
      ;;
    environment-shell)
      (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" SHELL="$FAKE_SHELL" AIR_QUALITY_COMMAND_LOG="$LOG" AIR_QUALITY_SHELL_LOG="$SHELL_LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" "$target") >"$output" 2>&1
      ;;
  esac
  status=$?
  set -e
  if [ "$status" -ne 0 ] || [ -e "$SHELL_LOG" ] || [ ! -e "$ATTACKER_ROOT/keep" ]; then
    printf 'authority case failed: target=%s mode=%s status=%s\n' "$target" "$mode" "$status" >&2
    cat "$output" >&2
    return 1
  fi
  grep -Fq "$CHECKOUT" "$LOG"
}

executed=0
for target in audit build check lint root-test test; do
  for mode in default command-root environment-root command-shell environment-shell; do
    run_case "$target" "$mode"
    executed=$((executed + 1))
  done
done
[ "$executed" -eq 30 ]

rm -f "$LOG"
(cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" check) >/dev/null 2>&1
grep -Fq "$FAKE_PYTHON" "$LOG"
grep -Fq "$FAKE_GIT" "$LOG"
grep -Fq 'pip_audit --index-url https://pypi.org/simple -r requirements.txt' "$LOG"
[ ! -e "$CONTROL_DIR/AIR_ROOT_MARKER" ]
[ ! -e "$CONTROL_DIR/AIR_PYTHON_MARKER" ]

controls=0
for variable in PYTHON GIT; do
  mark="$TEMP_ROOT/${variable}-command-syntax"
  bad="\$(shell /usr/bin/touch '$mark')"
  if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" /usr/bin/make --no-print-directory -f "$MAKEFILE" "$variable=$bad" lint) >"$TEMP_ROOT/syntax.out" 2>&1; then exit 1; fi
  [ ! -e "$mark" ]
  controls=$((controls + 1))

  mark="$TEMP_ROOT/${variable}-environment-syntax"
  bad="\$(shell /usr/bin/touch '$mark')"
  if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" env "$variable=$bad" /usr/bin/make --environment-overrides --no-print-directory -f "$MAKEFILE" lint) >"$TEMP_ROOT/syntax-environment.out" 2>&1; then exit 1; fi
  [ ! -e "$mark" ]
  controls=$((controls + 1))
done

ROOT_MARK="$TEMP_ROOT/root-command-syntax"
ROOT_BAD="\$(shell /usr/bin/touch '$ROOT_MARK')"
(cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" "ROOT=$ROOT_BAD" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" lint) >/dev/null 2>&1
[ ! -e "$ROOT_MARK" ]
controls=$((controls + 1))
ROOT_ENV_MARK="$TEMP_ROOT/root-environment-syntax"
ROOT_ENV_BAD="\$(shell /usr/bin/touch '$ROOT_ENV_MARK')"
(cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" ROOT="$ROOT_ENV_BAD" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --environment-overrides --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" lint) >/dev/null 2>&1
[ ! -e "$ROOT_ENV_MARK" ]
controls=$((controls + 1))
[ "$controls" -eq 6 ]

LIST_MARK="$TEMP_ROOT/list-command-syntax"
LIST_BAD="\$(shell /usr/bin/touch '$LIST_MARK')"
if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" /usr/bin/make --no-print-directory -f "$MAKEFILE" "MAKEFILE_LIST=$LIST_BAD" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" check) >"$TEMP_ROOT/list-command.out" 2>&1; then exit 1; fi
[ ! -e "$LIST_MARK" ]
grep -Fq 'MAKEFILE_LIST must not be overridden' "$TEMP_ROOT/list-command.out"
if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" MAKEFILE_LIST=/tmp/untrusted /usr/bin/make --environment-overrides --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" check) >"$TEMP_ROOT/list-environment.out" 2>&1; then exit 1; fi
grep -Fq 'MAKEFILE_LIST must not be overridden' "$TEMP_ROOT/list-environment.out"

PRE="$TEMP_ROOT/pre.mk"
PRE_MARKER="$TEMP_ROOT/pre-marker"
printf '$(shell /usr/bin/touch %s)\n' "$PRE_MARKER" >"$PRE"
if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" MAKEFILES="$PRE" /usr/bin/make --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" check) >"$TEMP_ROOT/pre.out" 2>&1; then exit 1; fi
grep -Fq 'MAKEFILES must be empty' "$TEMP_ROOT/pre.out"
[ -e "$PRE_MARKER" ]
rm -f "$PRE_MARKER"
if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" MAKEFILES="$PRE" /usr/bin/make --environment-overrides --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" check) >"$TEMP_ROOT/pre-environment.out" 2>&1; then exit 1; fi
grep -Fq 'MAKEFILES must be empty' "$TEMP_ROOT/pre-environment.out"
[ -e "$PRE_MARKER" ]

LATER="$TEMP_ROOT/later.mk"
for target in audit build check lint root-test test; do
  printf '%s:\n\t@/usr/bin/touch %s\n' "$target" "$TEMP_ROOT/later-$target" >"$LATER"
  if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER" "$target" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT") >"$TEMP_ROOT/later.out" 2>&1; then exit 1; fi
  [ ! -e "$TEMP_ROOT/later-$target" ]
done

TARGET_PYTHON="$TEMP_ROOT/target-python"
TARGET_GIT="$TEMP_ROOT/target-git"
cp "$FAKE_PYTHON" "$TARGET_PYTHON"
cp "$FAKE_GIT" "$TARGET_GIT"
LATER_VARS="$TEMP_ROOT/later-vars.mk"
cat >"$LATER_VARS" <<LATER_VARS
audit build check lint root-test test: MAKEFILE_LIST := $MAKEFILE
audit build check lint root-test test: ROOT := $ATTACKER_ROOT
audit build check lint root-test test: PYTHON := $TARGET_PYTHON
audit build check lint root-test test: GIT := $TARGET_GIT
LATER_VARS
rm -f "$LOG"
(cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER_VARS" check "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT") >"$TEMP_ROOT/later-vars.out" 2>&1
grep -Fq "$FAKE_PYTHON" "$LOG"
grep -Fq "$FAKE_GIT" "$LOG"
if grep -Fq "$TARGET_PYTHON" "$LOG" || grep -Fq "$TARGET_GIT" "$LOG"; then exit 1; fi

LATER_FAKE_SHELL="$TEMP_ROOT/later-fake-shell"
LATER_SHELL_LOG="$TEMP_ROOT/later-shell.log"
cat >"$LATER_FAKE_SHELL" <<'SCRIPT'
#!/bin/sh
printf invoked >> "$AIR_QUALITY_LATER_SHELL_LOG"
exec /bin/sh "$@"
SCRIPT
chmod +x "$LATER_FAKE_SHELL"
LATER_OVERRIDE="$TEMP_ROOT/later-override.mk"
cat >"$LATER_OVERRIDE" <<LATER_OVERRIDE_MAKE
audit build check lint root-test test: MAKEFILE_LIST := $MAKEFILE
audit build check lint root-test test: override SHELL := $LATER_FAKE_SHELL
audit build check lint root-test test: override .SHELLFLAGS := -c
LATER_OVERRIDE_MAKE
rm -f "$LATER_SHELL_LOG" "$LOG"
(cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" AIR_QUALITY_LATER_SHELL_LOG="$LATER_SHELL_LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER_OVERRIDE" check "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT") >"$TEMP_ROOT/later-override.out" 2>&1
[ -s "$LATER_SHELL_LOG" ]

LATER_APPEND="$TEMP_ROOT/later-append.mk"
LATER_APPEND_MARKER="$TEMP_ROOT/later-append-marker"
cat >"$LATER_APPEND" <<LATER_APPEND_MAKE
audit build check lint root-test test: MAKEFILE_LIST := $MAKEFILE
lint::
	@/usr/bin/touch '$LATER_APPEND_MARKER'
LATER_APPEND_MAKE
rm -f "$LATER_APPEND_MARKER" "$LOG"
(cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" AIR_QUALITY_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER_APPEND" lint "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT") >"$TEMP_ROOT/later-append.out" 2>&1
[ -e "$LATER_APPEND_MARKER" ]

PATH_PYTHON="$TEMP_ROOT/python"
PATH_PYTHON_LOG="$TEMP_ROOT/path-python.log"
cp "$FAKE_PYTHON" "$PATH_PYTHON"
rm -f "$PATH_PYTHON_LOG"
(cd "$CONTROL_DIR" && PATH="$TEMP_ROOT:/usr/bin:/bin" AIR_QUALITY_COMMAND_LOG="$PATH_PYTHON_LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" lint "GIT=$FAKE_GIT") >"$TEMP_ROOT/path-python.out" 2>&1
grep -Fq "$PATH_PYTHON" "$PATH_PYTHON_LOG"
grep -Fq -- '-I -B -m ruff format --check .' "$PATH_PYTHON_LOG"

PYTHONPATH_DIR="$TEMP_ROOT/pythonpath"
PYTHONPATH_MARKER="$TEMP_ROOT/pythonpath-marker"
mkdir -p "$PYTHONPATH_DIR"
cat >"$PYTHONPATH_DIR/sitecustomize.py" <<'PYTHON'
import os
from pathlib import Path

Path(os.environ["AIR_QUALITY_PYTHONPATH_MARKER"]).write_text("loaded", encoding="utf-8")
os._exit(0)
PYTHON
cat >"$CHECKOUT/run_tests.py" <<'PYTHON'
print("isolated Python executed the repository tests")
PYTHON
rm -f "$PYTHONPATH_MARKER"
(cd "$CONTROL_DIR" && PATH="/usr/bin:/bin" PYTHONPATH="$PYTHONPATH_DIR" AIR_QUALITY_PYTHONPATH_MARKER="$PYTHONPATH_MARKER" /usr/bin/make --no-print-directory -f "$MAKEFILE" test PYTHON=/usr/bin/python3 "GIT=$FAKE_GIT") >"$TEMP_ROOT/pythonpath.out" 2>&1
[ ! -e "$PYTHONPATH_MARKER" ]
grep -Fq 'isolated Python executed the repository tests' "$TEMP_ROOT/pythonpath.out"

PATH_GIT="$TEMP_ROOT/git"
PATH_GIT_LOG="$TEMP_ROOT/path-git.log"
cat >"$PATH_GIT" <<'SCRIPT'
#!/bin/sh
printf invoked >> "$AIR_QUALITY_PATH_GIT_LOG"
SCRIPT
chmod +x "$PATH_GIT"
rm -f "$PATH_GIT_LOG"
(cd "$CONTROL_DIR" && PATH="$TEMP_ROOT:/usr/bin:/bin" AIR_QUALITY_COMMAND_LOG="$LOG" AIR_QUALITY_PATH_GIT_LOG="$PATH_GIT_LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" lint "PYTHON=$FAKE_PYTHON") >"$TEMP_ROOT/path-git.out" 2>&1
[ ! -e "$PATH_GIT_LOG" ]

if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" /usr/bin/make --no-print-directory -f "$MAKEFILE" MAKEFLAGS=-n "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" check) >"$TEMP_ROOT/flags.out" 2>&1; then exit 1; fi
grep -Fq 'MAKEFLAGS must not be overridden' "$TEMP_ROOT/flags.out"
for flag in -n --just-print --dry-run --recon -t --touch -q --question -i --ignore-errors; do
  if (cd "$CONTROL_DIR" && PATH="$AUTHORITY_PATH" /usr/bin/make "$flag" --no-print-directory -f "$MAKEFILE" "PYTHON=$FAKE_PYTHON" "GIT=$FAKE_GIT" check) >"$TEMP_ROOT/flag.out" 2>&1; then exit 1; fi
  grep -Fq 'non-executing or error-ignoring MAKEFLAGS are not supported' "$TEMP_ROOT/flag.out"
done

printf '%s\n' 'Make authority tests passed: 30 target/authority cases, hostile literal Python and Git paths, 6 raw Make-syntax controls, 2 MAKEFILE_LIST rejections, 2 startup-boundary cases, 6 later recipe-replacement rejections, later root/Python/Git and non-override shell protection, target-specific override shell boundary control, caller-added double-colon recipe boundary control, startup/PATH-Python boundary controls, PYTHONPATH isolation, PATH-Git rejection, caller MAKEFLAGS rejection, and 10 mode rejections'
