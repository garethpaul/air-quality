#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
: "${REPOSITORY_PYTHON:?REPOSITORY_PYTHON must name the reviewed interpreter}"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/air-quality-python-selection.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

cat >"$TMP_DIR/python" <<'EOF'
#!/usr/bin/env sh
echo "baseline used PATH-selected python" >&2
exit 91
EOF
chmod 700 "$TMP_DIR/python"

PATH="$TMP_DIR:/usr/bin:/bin" PYTHON="$REPOSITORY_PYTHON" \
  /bin/sh "$ROOT_DIR/scripts/check-baseline.sh" >/dev/null

printf '%s\n' "baseline Python selection contract passed"
