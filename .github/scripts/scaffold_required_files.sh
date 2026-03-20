#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
CREATE_MISSING=0
DRY_RUN=0
missing_count=0
unresolved_count=0

usage() {
  cat <<'EOF'
Usage: sh .github/scripts/scaffold_required_files.sh [--create-missing] [--dry-run]

Options:
  --create-missing   Create missing files when a scaffold template exists.
  --dry-run          Show what would be created without writing files.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --create-missing)
      CREATE_MISSING=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
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

strict_baseline_block() {
  cat <<'EOF'
## Strict Governance Baseline (Mandatory)

- Apply `.github/reference/strict-workflow-governance.md` before substantial work.
- Execute required gates for context, tools, skills, and role responsibilities.
- If a required tool operation is unavailable, halt and report blocker + approved fallback (no silent bypass).

## Workflow Memory Rules (Mandatory)

- Before deep artifact work, read the relevant `WF-*` node in `agent-output/workflows/` first.
- If a required `WF-*` node is missing or has `artifact_hash` mismatch, halt and request intervention.
- Keep `WF-*` note summaries concise (10-Line Rule) and maintain deterministic IDs via `agent-output/.next-id`.
- Update workflow status only with the correct `handoff_id`, and emit concrete `[[WF-...]]` + numeric Planka card IDs in handoffs.
EOF
}

write_agent_stub() {
  path=$1
  description=$2
  name=$(basename "$path" .agent.md)

  cat > "$path" <<EOF
---
description: $description
name: $name
target: vscode
argument-hint: TODO
tools: [read/readFile, search, todo]
model: GPT-5.3-Codex
handoffs: []
---

$(strict_baseline_block)

Purpose:
- TODO: restore full role responsibilities from canonical template.
EOF
}

write_skill_stub() {
  path=$1
  description=$2
  name=$(basename "$(dirname "$path")")

  cat > "$path" <<EOF
---
name: $name
description: $description
license: MIT
---

# $name

TODO: restore full skill content from canonical template.

## Strict Governance Hooks (Mandatory)

1. Apply `.github/reference/strict-workflow-governance.md` on every workflow update.
EOF
}

write_template() {
  template=$1
  rel_path=$2
  abs_path=$3
  description=$4

  case "$template" in
    mcp_json)
      cat > "$abs_path" <<'EOF'
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "${workspaceFolder}"
      ]
    },
    "analyzer": {
      "command": "uvx",
      "args": [
        "mcp-server-analyzer"
      ]
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "planka": {
      "url": "http://localhost:25478/mcp"
    },
    "obsidian": {
      "command": "npx",
      "args": [
        "@bitbonsai/mcpvault@latest",
        "${workspaceFolder}/agent-output"
      ]
    }
  }
}
EOF
      ;;
    next_id)
      printf '1\n' > "$abs_path"
      ;;
    strict_contract_stub)
      cat > "$abs_path" <<'EOF'
# Strict Workflow Governance Contract

This file is required for custom-agent operation.

If this was scaffolded, restore full contract content from the canonical repository copy.
EOF
      ;;
    markdown_lint)
      cat > "$abs_path" <<'EOF'
name: Markdown Lint

on:
  pull_request:
    paths:
      - "**/*.md"
  push:
    branches:
      - main
    paths:
      - "**/*.md"

jobs:
  markdownlint:
    name: Lint Markdown files
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check strict workflow governance contract
        run: sh .github/scripts/check_strict_governance.sh

      - name: Check workflow note contract (full scan)
        run: sh .github/scripts/check_workflow_contract.sh

      - name: Check skill-gate coverage
        run: sh .github/scripts/check_skill_gate_coverage.sh

      - name: Check Obsidian graph contract
        run: sh .github/scripts/check_obsidian_graph_contract.sh

      - name: Run markdownlint-cli2
        uses: DavidAnson/markdownlint-cli2-action@v19
        with:
          globs: |
            **/*.md
          config: .markdownlint.json
EOF
      ;;
    skill_stub)
      write_skill_stub "$abs_path" "$description"
      ;;
    agent_stub)
      write_agent_stub "$abs_path" "$description"
      ;;
    none)
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

process_entry() {
  rel_path=$1
  description=$2
  template=$3

  abs_path="$ROOT/$rel_path"

  if [ -e "$abs_path" ]; then
    printf '[OK]   %s\n' "$rel_path"
    return 0
  fi

  missing_count=$((missing_count + 1))
  printf '[MISS] %s - %s\n' "$rel_path" "$description"

  if [ "$CREATE_MISSING" -eq 1 ] && [ "$template" != "none" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '       -> would create from scaffold template\n'
    else
      mkdir -p "$(dirname "$abs_path")"
      write_template "$template" "$rel_path" "$abs_path" "$description"
      printf '       -> created scaffold file\n'
    fi
  fi

  if [ "$CREATE_MISSING" -eq 0 ] || [ "$template" = "none" ]; then
    unresolved_count=$((unresolved_count + 1))
  fi
}

while IFS='|' read -r rel_path description template; do
  [ -n "$rel_path" ] || continue
  process_entry "$rel_path" "$description" "$template"
done <<'EOF'
.vscode/mcp.json|MCP server namespace configuration required by tools allowlists.|mcp_json
agent-output/.next-id|Unified document lifecycle counter.|next_id
.github/reference/strict-workflow-governance.md|Strict governance contract for context, tools, skills, and roles.|strict_contract_stub
.github/reference/required-files-catalog.md|Catalog of required files and recovery guidance for agents.|none
.github/workflows/markdown-lint.yml|Markdown + governance CI gate.|markdown_lint
.github/scripts/check_strict_governance.sh|Policy checker for strict governance file presence and markers.|none
.github/scripts/check_workflow_contract.sh|WF contract checker for workflow notes.|none
.github/scripts/check_skill_gate_coverage.sh|Skill-gate checker for phase/role skill coverage across agents.|none
.github/scripts/check_obsidian_graph_contract.sh|Obsidian graph checker for WF parent-edge and handoff contract across agents.|none
.github/scripts/scaffold_required_files.sh|Scaffold utility for missing required files.|none
.github/skills/obsidian-workflow/SKILL.md|WF memory contract and existence-gate behavior.|skill_stub
.github/skills/planka-workflow/SKILL.md|Planka lifecycle and handoff contract behavior.|skill_stub
.github/agents/01-roadmap.agent.md|Custom agent definition: Strategic vision holder maintaining outcome-focused product roadmap aligned with releases.|agent_stub
.github/agents/02-planner.agent.md|Custom agent definition: High-rigor planning assistant for upcoming feature changes.|agent_stub
.github/agents/03-analyst.agent.md|Custom agent definition: Research and analysis specialist for code-level investigation and determination.|agent_stub
.github/agents/04-architect.agent.md|Custom agent definition: Maintains architectural coherence across features and reviews technical debt accumulation.|agent_stub
.github/agents/05-security.agent.md|Custom agent definition: Comprehensive security audit specialist - architecture, code, dependencies, and compliance.|agent_stub
.github/agents/06-critic.agent.md|Custom agent definition: Constructive reviewer and program manager that stress-tests planning documents.|agent_stub
.github/agents/07-implementer.agent.md|Custom agent definition: Execution-focused coding agent that implements approved plans.|agent_stub
.github/agents/08-code-reviewer.agent.md|Custom agent definition: Reviews code quality, architecture alignment, and maintainability before QA testing.|agent_stub
.github/agents/09-qa.agent.md|Custom agent definition: Dedicated QA specialist verifying test coverage and execution before implementation approval.|agent_stub
.github/agents/10-uat.agent.md|Custom agent definition: Product Owner conducting UAT to verify implementation delivers stated business value.|agent_stub
.github/agents/11-devops.agent.md|Custom agent definition: DevOps specialist responsible for packaging, versioning, deployment readiness, and release execution.|agent_stub
.github/agents/12-retrospective.agent.md|Custom agent definition: Captures lessons learned, architectural decisions, and patterns after implementation completes.|agent_stub
.github/agents/13-pi.agent.md|Custom agent definition: Analyzes retrospectives and systematically improves agent workflows.|agent_stub
EOF

if [ "$unresolved_count" -gt 0 ]; then
  printf '\nMissing files remain. See descriptions above or run with --create-missing.\n'
  exit 1
fi

if [ "$missing_count" -gt 0 ] && [ "$CREATE_MISSING" -eq 1 ]; then
  printf '\nAll missing files were scaffolded.\n'
else
  printf '\nAll required files are present.\n'
fi
