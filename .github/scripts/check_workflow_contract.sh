#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORKFLOW_DIR="$ROOT/workflows"
WORKFLOW_DIR_SET=0
CHANGED_ONLY=0
BASE_REF=""
MAX_SUMMARY_BULLETS=3
MAX_SUMMARY_LINES=10

usage() {
  cat <<'EOF'
Usage: sh .github/scripts/check_workflow_contract.sh [options]

Options:
  --workflow-dir PATH          Workflow notes directory (default: agent-output/workflows)
  --changed-only               Only validate changed workflow notes
  --base-ref REF               Optional git base ref for changed-only mode
  --max-summary-bullets N      Maximum summary bullet lines (default: 3)
  --max-summary-lines N        Maximum non-empty summary lines (default: 10)
EOF
}

resolve_base_ref() {
  candidate=$1
  if [ -n "$candidate" ]; then
    if git -C "$ROOT" rev-parse --verify "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
    if git -C "$ROOT" rev-parse --verify "origin/$candidate" >/dev/null 2>&1; then
      printf '%s\n' "origin/$candidate"
      return 0
    fi
  fi
  return 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workflow-dir)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      WORKFLOW_DIR=$2
      WORKFLOW_DIR_SET=1
      shift 2
      ;;
    --changed-only)
      CHANGED_ONLY=1
      shift
      ;;
    --base-ref)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      BASE_REF=$2
      shift 2
      ;;
    --max-summary-bullets)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      MAX_SUMMARY_BULLETS=$2
      shift 2
      ;;
    --max-summary-lines)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      MAX_SUMMARY_LINES=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[FAIL] Unknown argument: %s\n' "$1"
      usage
      exit 2
      ;;
  esac
done

if [ "${WORKFLOW_DIR#"$ROOT"}" = "$WORKFLOW_DIR" ]; then
  WORKFLOW_DIR=$(CDPATH= cd -- "$WORKFLOW_DIR" && pwd)
fi

if [ ! -d "$WORKFLOW_DIR" ] && [ "$WORKFLOW_DIR_SET" -eq 0 ] && [ -d "$ROOT/agent-output/workflows" ]; then
  WORKFLOW_DIR="$ROOT/agent-output/workflows"
fi

if [ ! -d "$WORKFLOW_DIR" ]; then
  printf '[FAIL] Workflow directory not found: %s\n' "$WORKFLOW_DIR"
  exit 1
fi

ids_tmp=$(mktemp)
files_tmp=$(mktemp)
violations_tmp=$(mktemp)
trap 'rm -f "$ids_tmp" "$files_tmp" "$violations_tmp"' EXIT

for file in "$WORKFLOW_DIR"/*.md; do
  [ -f "$file" ] || continue
  base=$(basename "$file" .md)
  printf '%s\n' "$base" >> "$ids_tmp"
done

if [ "$CHANGED_ONLY" -eq 1 ]; then
  resolved_base=""
  if [ -n "$BASE_REF" ]; then
    resolved_base=$(resolve_base_ref "$BASE_REF" || true)
  fi

  if [ -z "$resolved_base" ] && [ -n "${GITHUB_BASE_REF:-}" ]; then
    resolved_base=$(resolve_base_ref "$GITHUB_BASE_REF" || true)
  fi

  if [ -z "$resolved_base" ] && [ -n "${BASE_REF:-}" ]; then
    resolved_base=$(resolve_base_ref "$BASE_REF" || true)
  fi

  if [ -z "$resolved_base" ] && git -C "$ROOT" rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    resolved_base="HEAD~1"
  fi

  if [ -z "$resolved_base" ]; then
    printf '[OK]   No changed workflow notes detected. Skipping WF contract check.\n'
    exit 0
  fi

  if [ "$resolved_base" = "HEAD~1" ]; then
    diff_range="HEAD~1...HEAD"
  else
    diff_range="$resolved_base...HEAD"
  fi

  git -C "$ROOT" diff --name-only --diff-filter=ACMR "$diff_range" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    abs="$ROOT/$rel"
    [ -f "$abs" ] || continue
    [ "$(dirname "$abs")" = "$WORKFLOW_DIR" ] || continue
    case "$abs" in
      *.md) printf '%s\n' "$abs" >> "$files_tmp" ;;
    esac
  done

  if [ ! -s "$files_tmp" ]; then
    printf '[OK]   No changed workflow notes detected. Skipping WF contract check.\n'
    exit 0
  fi
else
  for file in "$WORKFLOW_DIR"/*.md; do
    [ -f "$file" ] || continue
    printf '%s\n' "$file" >> "$files_tmp"
  done
fi

sort -u "$files_tmp" -o "$files_tmp"

total_violations=0

while IFS= read -r file; do
  [ -n "$file" ] || continue
  : > "$violations_tmp"
  file_violations=0

  frontmatter_tmp=$(mktemp)
  if awk '
    NR == 1 {
      if ($0 != "---") {
        valid = 0
        exit
      }
      valid = 1
      next
    }
    valid && $0 == "---" {
      found = 1
      exit
    }
    END {
      if (valid && found) {
        exit 0
      }
      exit 1
    }
  ' "$file" >/dev/null 2>&1; then
    awk 'NR == 1 { next } $0 == "---" { exit } { print }' "$file" > "$frontmatter_tmp"
    for key in type parent Planka-Card artifact_hash; do
      if ! grep -Eq "^[[:space:]]*${key}:" "$frontmatter_tmp"; then
        printf '       - Missing frontmatter key: %s\n' "$key" >> "$violations_tmp"
        file_violations=$((file_violations + 1))
      fi
    done
  else
    printf '       - Missing YAML frontmatter block\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi
  rm -f "$frontmatter_tmp"

  for section in "## Summary" "## Artifacts"; do
    if ! grep -Fq "$section" "$file"; then
      printf '       - Missing required section: %s\n' "$section" >> "$violations_tmp"
      file_violations=$((file_violations + 1))
    fi
  done

  summary_counts=$(awk '
    BEGIN { in_summary = 0; summary_found = 0; bullets = 0; lines = 0 }
    /^##[[:space:]]+Summary[[:space:]]*$/ { in_summary = 1; summary_found = 1; next }
    in_summary && /^##[[:space:]]+/ { in_summary = 0 }
    in_summary {
      if ($0 ~ /[^[:space:]]/) lines++
      if ($0 ~ /^[[:space:]]*-[[:space:]]+/) bullets++
    }
    END {
      if (summary_found) {
        printf "%d:%d", bullets, lines
      } else {
        printf "NA"
      }
    }
  ' "$file")

  if [ "$summary_counts" != "NA" ]; then
    summary_bullets=${summary_counts%%:*}
    summary_lines=${summary_counts##*:}

    if [ "$summary_bullets" -gt "$MAX_SUMMARY_BULLETS" ]; then
      printf '       - Summary has %s bullets (max %s)\n' "$summary_bullets" "$MAX_SUMMARY_BULLETS" >> "$violations_tmp"
      file_violations=$((file_violations + 1))
    fi

    if [ "$summary_lines" -gt "$MAX_SUMMARY_LINES" ]; then
      printf '       - Summary has %s non-empty lines (max %s)\n' "$summary_lines" "$MAX_SUMMARY_LINES" >> "$violations_tmp"
      file_violations=$((file_violations + 1))
    fi
  fi

  if grep -Fq '[[WF-[ID]]]' "$file"; then
    printf '       - Found forbidden placeholder pattern: \[\[WF-\[ID\]\]\]\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi

  if grep -Eq '\[\[WF-(Epic-ID|Plan-ID|Calling-ID)\]\]' "$file"; then
    printf '       - Found forbidden placeholder pattern: \[\[WF-(Epic-ID|Plan-ID|Calling-ID)\]\]\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi

  if grep -Fq 'CARD_ID_NUMERIC' "$file"; then
    printf '       - Found forbidden placeholder pattern: CARD_ID_NUMERIC\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi

  if grep -Fq '<numeric-card-id>' "$file"; then
    printf '       - Found forbidden placeholder pattern: <numeric-card-id>\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi

  refs_tmp=$(mktemp)
  awk '
    {
      line = $0
      while (match(line, /\[\[WF-[^]|#\]]+/)) {
        ref = substr(line, RSTART + 2, RLENGTH - 2)
        sub(/\.md$/, "", ref)
        print ref
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$file" | sort -u > "$refs_tmp"

  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    if ! grep -Fxq "$ref" "$ids_tmp"; then
      printf '       - WF reference points to missing note: [[%s]]\n' "$ref" >> "$violations_tmp"
      file_violations=$((file_violations + 1))
    fi
  done < "$refs_tmp"
  rm -f "$refs_tmp"

  rel_file=${file#"$ROOT/"}
  if [ "$file_violations" -gt 0 ]; then
    printf '[FAIL] %s\n' "$rel_file"
    cat "$violations_tmp"
    total_violations=$((total_violations + file_violations))
  else
    printf '[OK]   %s\n' "$rel_file"
  fi
done < "$files_tmp"

if [ "$total_violations" -gt 0 ]; then
  printf '\nWF contract check failed with %s violation(s).\n' "$total_violations"
  exit 1
fi

printf '\nWF contract check passed.\n'
