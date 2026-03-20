#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

REQUIRED_CONTRACT_REF=".github/reference/strict-workflow-governance.md"
REQUIRED_AGENT_HEADING="## Strict Governance Baseline (Mandatory)"
REQUIRED_AGENT_MEMORY_HEADING="## Workflow Memory Rules (Mandatory)"
REQUIRED_SKILL_HEADING="Strict Governance Hooks (Mandatory)"

errors=0

ok() {
  printf '[OK]   %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  errors=$((errors + 1))
}

check_file_exists() {
  rel_path=$1
  abs_path="$ROOT/$rel_path"
  if [ -e "$abs_path" ]; then
    ok "Required file exists: $rel_path"
  else
    fail "Missing required file: $rel_path (run: sh .github/scripts/scaffold_required_files.sh --create-missing)"
  fi
}

check_contains() {
  rel_path=$1
  needle=$2
  ok_msg=$3
  fail_msg=$4

  abs_path="$ROOT/$rel_path"
  if [ ! -e "$abs_path" ]; then
    return
  fi

  if grep -Fq "$needle" "$abs_path"; then
    ok "$ok_msg"
  else
    fail "$fail_msg"
  fi
}

while IFS= read -r rel_path; do
  [ -n "$rel_path" ] || continue
  check_file_exists "$rel_path"
done <<'EOF'
.github/reference/strict-workflow-governance.md
.github/reference/required-files-catalog.md
.github/skills/obsidian-workflow/SKILL.md
.github/skills/planka-workflow/SKILL.md
.github/workflows/markdown-lint.yml
.github/scripts/check_strict_governance.sh
.github/scripts/check_workflow_contract.sh
.github/scripts/check_skill_gate_coverage.sh
.github/scripts/check_obsidian_graph_contract.sh
.github/scripts/scaffold_required_files.sh
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

for skill_rel in \
  ".github/skills/obsidian-workflow/SKILL.md" \
  ".github/skills/planka-workflow/SKILL.md"
do
  check_contains \
    "$skill_rel" \
    "$REQUIRED_SKILL_HEADING" \
    "Strict hook present: $skill_rel" \
    "Missing strict hook heading in $skill_rel"
done

while IFS= read -r agent_rel; do
  [ -n "$agent_rel" ] || continue
  check_contains \
    "$agent_rel" \
    "$REQUIRED_AGENT_HEADING" \
    "Strict baseline present: $agent_rel" \
    "Missing strict baseline heading in $agent_rel"
  check_contains \
    "$agent_rel" \
    "$REQUIRED_AGENT_MEMORY_HEADING" \
    "Workflow memory rules present: $agent_rel" \
    "Missing workflow memory rules heading in $agent_rel"
  check_contains \
    "$agent_rel" \
    "$REQUIRED_CONTRACT_REF" \
    "Contract reference present: $agent_rel" \
    "Missing contract reference in $agent_rel"
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
  printf '\nStrict governance check failed with %s error(s).\n' "$errors"
  exit 1
fi

printf '\nStrict governance check passed.\n'
