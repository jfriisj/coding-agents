#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORKFLOW_DIR="$ROOT/agent-output/workflows"
WORKFLOW_DIR_SET=0
CHANGED_ONLY=0
BASE_REF=""
MAX_SUMMARY_BULLETS=3
MAX_SUMMARY_LINES=10
REQUIRED_FRONTMATTER_KEYS="type parent"
ENFORCE_REQUIRED_SECTIONS=1
ENFORCE_SUMMARY_LIMITS=1
ENFORCE_WF_REF_EXISTENCE=1

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

# (Behold al den oprindelige opsætning til argument parsing og git-diff tracking her... Jeg spoler frem til selve tjekket for at holde koden fokuseret på dine ændringer)

ids_tmp=$(mktemp)
files_tmp=$(mktemp)
violations_tmp=$(mktemp)
trap 'rm -f "$ids_tmp" "$files_tmp" "$violations_tmp"' EXIT

# Build ID catalog from all WF nodes (active + closed) so WF references to closed nodes resolve.
find "$WORKFLOW_DIR" -type f -name 'WF-*.md' | while IFS= read -r file; do
  [ -f "$file" ] || continue
  base=$(basename "$file" .md)
  printf '%s\n' "$base" >> "$ids_tmp"
done

# Fill files to validate (active WF nodes only; closed nodes are historical archive).
find "$WORKFLOW_DIR" -type f -name 'WF-*.md' ! -path '*/closed/*' | while IFS= read -r file; do
  [ -f "$file" ] || continue
  printf '%s\n' "$file" >> "$files_tmp"
done

sort -u "$files_tmp" -o "$files_tmp"

total_violations=0

while IFS= read -r file; do
  [ -n "$file" ] || continue
  : > "$violations_tmp"
  file_violations=0

  # Frontmatter Tjek (Samme som før)
  frontmatter_tmp=$(mktemp)
  if awk 'NR == 1 { if ($0 != "---") exit 1; valid=1; next } valid && $0 == "---" { exit 0 }' "$file" >/dev/null 2>&1; then
    awk 'NR == 1 { next } $0 == "---" { exit } { print }' "$file" > "$frontmatter_tmp"
    for key in $REQUIRED_FRONTMATTER_KEYS; do
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

  # Sektion Tjek
  if [ "$ENFORCE_REQUIRED_SECTIONS" -eq 1 ]; then
    for section in "## Summary" "## Artifacts"; do
      if ! grep -Fq "$section" "$file"; then
        printf '       - Missing required section: %s\n' "$section" >> "$violations_tmp"
        file_violations=$((file_violations + 1))
      fi
    done
  fi

  # Summary Line limits (Samme som før)

  # Placeholder Forbud (NYT: Opdateret til native markdown)
  if grep -Fq 'WF-[ID].md' "$file"; then
    printf '       - Found forbidden placeholder pattern: WF-[ID].md\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi

  if grep -Eq 'WF-(Epic-ID|Plan-ID|Calling-ID)\.md' "$file"; then
    printf '       - Found forbidden placeholder pattern: WF-(Epic-ID|Plan-ID|Calling-ID).md\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi

  # Obsidian [[ ]] Forbud (NYT TJEK)
  if grep -Eq '\[\[WF-[^]]+\]\]' "$file"; then
    printf '       - Found forbidden Obsidian link syntax: [[WF-...]]. Use standard markdown links.\n' >> "$violations_tmp"
    file_violations=$((file_violations + 1))
  fi

  # Reference Existence Tjek (NYT: Ekstraherer fra standard markdown stier i stedet for [[ ]])
  if [ "$ENFORCE_WF_REF_EXISTENCE" -eq 1 ]; then
    refs_tmp=$(mktemp)
    awk '
      {
        line = $0
        # Finder strenge der matcher WF-<noget>.md
        while (match(line, /WF-[A-Za-z0-9_-]+\.md/)) {
          ref = substr(line, RSTART, RLENGTH - 3) # fjerner .md for at matche ids_tmp
          print ref
          line = substr(line, RSTART + RLENGTH)
        }
      }
    ' "$file" | sort -u > "$refs_tmp"

    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      if ! grep -Fxq "$ref" "$ids_tmp"; then
        printf '       - WF reference points to missing note: %s.md\n' "$ref" >> "$violations_tmp"
        file_violations=$((file_violations + 1))
      fi
    done < "$refs_tmp"
    rm -f "$refs_tmp"
  fi

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