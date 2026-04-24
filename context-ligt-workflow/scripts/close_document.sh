#!/usr/bin/env sh
# Usage: sh .github/scripts/close_document.sh <file_path> <status>
set -eu

FILE="$1"
STATUS="$2"

if [ -z "$FILE" ] || [ -z "$STATUS" ]; then
  echo "Error: Missing arguments."
  echo "Usage: sh .github/scripts/close_document.sh path/to/file.md \"Committed\""
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "Error: File '$FILE' does not exist."
  exit 1
fi

# Opbyg stier
DIR=$(dirname "$FILE")
BASENAME=$(basename "$FILE")

# Default closure behavior: sibling closed/ folder.
CLOSED_DIR="$DIR/closed"

# Workflow closure behavior: archive under agent-output/workflows/closed/<relative-active-subpath>/
# This preserves nested grouping such as epic-3.31/id-208/.
case "$FILE" in
  agent-output/workflows/closed/*)
    # Already in closed tree, keep default sibling behavior.
    ;;
  agent-output/workflows/*)
    case "$DIR" in
      agent-output/workflows)
        CLOSED_DIR="agent-output/workflows/closed"
        ;;
      agent-output/workflows/*)
        REL_DIR="${DIR#agent-output/workflows/}"
        CLOSED_DIR="agent-output/workflows/closed/$REL_DIR"
        ;;
    esac
    ;;
esac

# Sørg for at closed/ mappen eksisterer
mkdir -p "$CLOSED_DIR"

# Opdater Status i YAML frontmatter sikkert via awk
tmp=$(mktemp)
awk -v new_status="$STATUS" '
  /^Status:/ { print "Status: " new_status; next }
  { print }
' "$FILE" > "$tmp" && mv "$tmp" "$FILE"

# Flyt filen
TARGET="$CLOSED_DIR/$BASENAME"
mv "$FILE" "$TARGET"

echo "Success: Document closed and moved to $TARGET with Status: $STATUS"