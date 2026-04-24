#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$PWD}"

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Project root not found: $PROJECT_ROOT" >&2
  exit 1
fi

PYTEST_BIN="$PROJECT_ROOT/.venv/bin/pytest"

if [[ -f "$PROJECT_ROOT/pytest.ini" ]]; then
  if [[ ! -x "$PYTEST_BIN" ]]; then
    echo "Missing pytest executable: $PYTEST_BIN" >&2
    exit 1
  fi
  echo "🐍 Python coverage:"
  "$PYTEST_BIN"
  exit $?
fi

echo "No pytest.ini project found for coverage at: $PROJECT_ROOT" >&2
exit 1
