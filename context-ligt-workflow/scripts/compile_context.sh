#!/bin/sh
# compile_context.sh
# Usage: sh .github/scripts/compile_context.sh agent-output/workflows/WF-XXX.md

WF_NODE="$1"
CONTEXT_OUT="agent-output/.context-baseline.md"

if [ -z "$WF_NODE" ] || [ ! -f "$WF_NODE" ]; then
    echo "Error: Must provide a valid WF node file."
    exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$CONTEXT_OUT")"

# Start the XML context wrapper
echo "<jit_context>" > "$CONTEXT_OUT"
echo "  <metadata generated_at=\"$(date)\" source_node=\"$(basename "$WF_NODE")\" />" >> "$CONTEXT_OUT"

normalize_parent_ref() {
    value="$1"

    # Support legacy Obsidian-style links: [[WF-123|alias]]
    case "$value" in
        \[\[*\]\])
            value="${value#\[\[}"
            value="${value%\]\]}"
            ;;
    esac

    case "$value" in
        *\|*) value="${value%%|*}" ;;
    esac

    value="${value#./}"
    printf '%s\n' "$value"
}

find_workflow_by_basename() {
    base_name="$1"

    [ -n "$base_name" ] || return 1

    first_match=$(find agent-output/workflows -type f -name "$base_name" | head -n 1 || true)
    if [ -n "$first_match" ]; then
        printf '%s\n' "$first_match"
        return 0
    fi

    return 1
}

resolve_parent_node() {
    parent_ref=$(awk '
        BEGIN { in_frontmatter=0 }
        /^---$/ {
            in_frontmatter = !in_frontmatter
            next
        }
        in_frontmatter && /^parent:[[:space:]]*/ {
            # Matcher standard string quotes, fx parent: "workflows/WF-001.md"
            if (match($0, /"([^"]+)"/, capture)) {
                print capture[1]
            } else if (match($0, /parent:[[:space:]]*([^[:space:]]+)/, capture)) {
                print capture[1]
            }
            exit
        }
    ' "$1")

    parent_ref=$(normalize_parent_ref "$parent_ref")

    case "$parent_ref" in
        ""|none|"none") return 1 ;;
    esac

    case "$parent_ref" in
        workflows/*) parent_path="agent-output/${parent_ref}" ;;
        agent-output/*) parent_path="$parent_ref" ;;
        */*) parent_path="$parent_ref" ;;
        *.md) parent_path="agent-output/workflows/${parent_ref}" ;;
        *) parent_path="agent-output/workflows/${parent_ref}.md" ;;
    esac

    if [ ! -f "$parent_path" ]; then
        parent_base=$(basename "$parent_path")
        discovered_parent=$(find_workflow_by_basename "$parent_base" || true)

        if [ -n "$discovered_parent" ]; then
            parent_path="$discovered_parent"
        else
            return 1
        fi
    fi

    printf '%s\n' "$parent_path"
}

compile_from_node() {
    current_node="$1"

    # Matcher standard markdown links under overskriften: - [text](path)
    pointers=$(awk '/^### Required Context Pointers/{flag=1; next} /^#/{if(flag) flag=0} flag' "$current_node" | grep "^-[[:space:]]*\[" || true)

    if [ -z "$pointers" ]; then
        parent_node=$(resolve_parent_node "$current_node" || true)
        if [ -n "$parent_node" ] && [ "$parent_node" != "$current_node" ]; then
            compile_from_node "$parent_node"
            return $?
        fi

        echo "  <message>No specific context pointers were provided by the Planner or any parent WF node.</message>" >> "$CONTEXT_OUT"
        return 0
    fi

    echo "$pointers" | while read -r line; do
        [ -n "$line" ] || continue

        # Extract path from inside the parenthesis: - [text](path)
        LINK=$(echo "$line" | sed 's/.*(\(.*\)).*/\1/')

        case "$LINK" in
            *#*)
                FILE="${LINK%%#*}"
                TARGET="${LINK#*#}"
                TYPE="header"
                ;;
            *^*)
                FILE="${LINK%%^*}"
                TARGET="${LINK#*^}"
                TYPE="block"
                ;;
            *)
                continue
                ;;
        esac

        # Append .md if the file extension is missing
        case "$FILE" in
            *.md) ;;
            *) FILE="${FILE}.md" ;;
        esac

        # Open the resource tag
        printf "  <resource file=\"%s\" target=\"%s\">\n" "$FILE" "$TARGET" >> "$CONTEXT_OUT"

        if [ ! -f "$FILE" ]; then
            echo "    <error>File '$FILE' not found.</error>" >> "$CONTEXT_OUT"
            echo "  </resource>" >> "$CONTEXT_OUT"
            continue
        fi

        if [ "$TYPE" = "header" ]; then
            awk -v target="$TARGET" '
                BEGIN { capturing=0; level=0; IGNORECASE=1 }
                /^#+ / {
                    curr_level = length($1)
                    if (capturing) {
                        if (curr_level <= level) {
                            exit
                        }
                    } else {
                        header_text = substr($0, curr_level+2)
                        sub(/[ \t\r\n]+$/, "", header_text)
                        if (tolower(header_text) == tolower(target)) {
                            capturing = 1
                            level = curr_level
                        }
                    }
                }
                capturing { print }
            ' "$FILE" >> "$CONTEXT_OUT"
        else
            awk -v target="^$TARGET" '
                BEGIN { RS=""; ORS="\n\n" }
                $0 ~ "\\^" target "($|\n)" { print; exit }
            ' "$FILE" >> "$CONTEXT_OUT"
        fi

        printf "  </resource>\n" >> "$CONTEXT_OUT"
    done
}

compile_from_node "$WF_NODE"

# Close the XML context wrapper
echo "</jit_context>" >> "$CONTEXT_OUT"
echo "Successfully compiled JIT context baseline to $CONTEXT_OUT"