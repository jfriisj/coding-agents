#!/usr/bin/env sh
set -eu

# Backward-compatible CI entrypoint: workflow contract validation now owns
# the Obsidian-link prohibition and related WF graph checks.
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
exec sh "$ROOT/.github/scripts/check_workflow_contract.sh" "$@"