#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$PWD}"

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Project root not found: $PROJECT_ROOT" >&2
  exit 1
fi

PYTEST_BIN="$PROJECT_ROOT/.venv/bin/pytest"
PYTHON_BIN="$PROJECT_ROOT/.venv/bin/python"

if [[ "${AUTO_INSTALL_TEST_DEPS:-false}" == "true" ]]; then
  if ! command -v uv >/dev/null 2>&1; then
    echo "AUTO_INSTALL_TEST_DEPS=true but 'uv' is unavailable" >&2
    exit 1
  fi
  if [[ -f "$PROJECT_ROOT/tests/requirements.txt" ]]; then
    uv pip install -r "$PROJECT_ROOT/tests/requirements.txt"
  fi
fi

if [[ -f "$PROJECT_ROOT/pytest.ini" ]]; then
  if [[ ! -x "$PYTEST_BIN" ]]; then
    echo "Missing pytest executable: $PYTEST_BIN" >&2
    exit 1
  fi
  "$PYTEST_BIN"
  exit $?
fi

if [[ "${RUN_TESTS_PYTHON_ONLY:-false}" == "true" ]]; then
  echo "RUN_TESTS_PYTHON_ONLY=true but no pytest.ini found" >&2
  exit 1
fi

if [[ -f "$PROJECT_ROOT/package.json" ]]; then
  if command -v npm >/dev/null 2>&1; then
    (cd "$PROJECT_ROOT" && npm test)
    exit $?
  fi
  echo "package.json found but npm is unavailable" >&2
  exit 1
fi

echo "No supported test project detected under: $PROJECT_ROOT" >&2
if [[ -x "$PYTHON_BIN" ]]; then
  "$PYTHON_BIN" -V >/dev/null 2>&1 || true
fi
exit 1
