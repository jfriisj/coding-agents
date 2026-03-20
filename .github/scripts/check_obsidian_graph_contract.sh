#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
errors=0

ok() {
  printf '[OK]   %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  errors=$((errors + 1))
}

check_contains() {
  rel_path=$1
  needle=$2
  reason=$3
  abs_path="$ROOT/$rel_path"

  if [ ! -f "$abs_path" ]; then
    fail "Missing agent file for Obsidian graph check: $rel_path"
    return
  fi

  if grep -Fq "$needle" "$abs_path"; then
    ok "$rel_path includes '$needle' ($reason)"
  else
    fail "$rel_path missing '$needle' ($reason)"
  fi
}

while IFS= read -r agent_rel; do
  [ -n "$agent_rel" ] || continue

  check_contains "$agent_rel" "Obsidian Workflow Sync (Graph-Relational Baseline)" "graph sync section"
  check_contains "$agent_rel" "Obsidian Graph Memory" "graph memory section"
  check_contains "$agent_rel" "WF-<concrete-id>-<slug>.md" "deterministic wf naming guidance"
  check_contains "$agent_rel" "Establish the Upward Edge" "parent-edge contract"
  check_contains "$agent_rel" "type:" "wf type frontmatter guidance"
  check_contains "$agent_rel" "parent:" "wf parent frontmatter guidance"
  check_contains "$agent_rel" "Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC)." "canonical handoff sentence"
  check_contains "$agent_rel" "sole long-term memory mechanism" "obsidian authority rule"
done <<'EOF'
.github/agents/01-roadmap.agent.md
.github/agents/02-planner.agent.md
.github/agents/03-analyst.agent.md
.github/agents/04-architect.agent.md
.github/agents/05-security.agent.md
.github/agents/06-critic.agent.md
.github/agents/07-implementer.agent.md
.github/agents/08-code-reviewer.agent.md
.github/agents/09-qa.agent.md
.github/agents/10-uat.agent.md
.github/agents/11-devops.agent.md
.github/agents/12-retrospective.agent.md
.github/agents/13-pi.agent.md
EOF

if [ "$errors" -gt 0 ]; then
  printf '\nObsidian graph contract check failed with %s error(s).\n' "$errors"
  exit 1
fi

printf '\nObsidian graph contract check passed.\n'