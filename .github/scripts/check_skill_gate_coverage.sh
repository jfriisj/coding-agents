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

agent_has_skill() {
  rel_path=$1
  skill=$2
  reason=$3
  abs_path="$ROOT/$rel_path"

  if [ ! -f "$abs_path" ]; then
    fail "Missing agent file for skill check: $rel_path"
    return
  fi

  if grep -Fq "$skill" "$abs_path"; then
    ok "$rel_path includes '$skill' ($reason)"
  else
    fail "$rel_path missing '$skill' ($reason)"
  fi
}

agent_has_pattern() {
  rel_path=$1
  pattern=$2
  reason=$3
  abs_path="$ROOT/$rel_path"

  if [ ! -f "$abs_path" ]; then
    fail "Missing agent file for pattern check: $rel_path"
    return
  fi

  if grep -Eq "$pattern" "$abs_path"; then
    ok "$rel_path matches pattern ($reason)"
  else
    fail "$rel_path missing required pattern ($reason)"
  fi
}

stage_has_skill() {
  stage=$1
  skill=$2
  found=0
  shift 2

  for rel_path in "$@"; do
    abs_path="$ROOT/$rel_path"
    if [ -f "$abs_path" ] && grep -Fq "$skill" "$abs_path"; then
      found=1
      break
    fi
  done

  if [ "$found" -eq 1 ]; then
    ok "$stage stage includes '$skill' coverage"
  else
    fail "$stage stage missing '$skill' coverage"
  fi
}

while IFS= read -r agent_rel; do
  [ -n "$agent_rel" ] || continue
  agent_has_pattern "$agent_rel" "MANDATORY[^\n]*Load .*document-lifecycle.*skill" "mandatory document lifecycle declaration"
  agent_has_pattern "$agent_rel" "MANDATORY[^\n]*Load .*planka-workflow.*skill" "mandatory planka workflow declaration"
  agent_has_pattern "$agent_rel" "MANDATORY[^\n]*Load .*obsidian-workflow.*skill" "mandatory obsidian workflow declaration"
  agent_has_pattern "$agent_rel" "MANDATORY[^\n]*Use .*obsidian-workflow.*sole long-term memory mechanism" "mandatory obsidian memory authority declaration"
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

agent_has_skill \
  ".github/agents/03-analyst.agent.md" \
  "analysis-methodology" \
  "analysis stage domain skill"

agent_has_skill \
  ".github/agents/04-architect.agent.md" \
  "architecture-patterns" \
  "design stage domain skill"

agent_has_skill \
  ".github/agents/05-security.agent.md" \
  "security-patterns" \
  "security stage domain skill"

agent_has_skill \
  ".github/agents/11-devops.agent.md" \
  "release-procedures" \
  "release stage domain skill"

agent_has_skill \
  ".github/agents/12-retrospective.agent.md" \
  "analysis-methodology" \
  "retrospective process skill declaration"

agent_has_skill \
  ".github/agents/13-pi.agent.md" \
  "analysis-methodology" \
  "process-hardening methodology"

agent_has_skill \
  ".github/agents/07-implementer.agent.md" \
  "testing-patterns" \
  "implementer testing methodology"

agent_has_skill \
  ".github/agents/08-code-reviewer.agent.md" \
  "code-review-standards" \
  "reviewer quality framework"

agent_has_skill \
  ".github/agents/09-qa.agent.md" \
  "testing-patterns" \
  "qa testing methodology"

stage_has_skill \
  "Build/Verify" \
  "testing-patterns" \
  ".github/agents/07-implementer.agent.md" \
  ".github/agents/08-code-reviewer.agent.md" \
  ".github/agents/09-qa.agent.md"

stage_has_skill \
  "Build/Verify" \
  "code-review-standards" \
  ".github/agents/07-implementer.agent.md" \
  ".github/agents/08-code-reviewer.agent.md" \
  ".github/agents/09-qa.agent.md"

stage_has_skill \
  "Build/Verify" \
  "engineering-standards" \
  ".github/agents/07-implementer.agent.md" \
  ".github/agents/08-code-reviewer.agent.md" \
  ".github/agents/09-qa.agent.md"

stage_has_skill \
  "Release/Closure" \
  "release-procedures" \
  ".github/agents/10-uat.agent.md" \
  ".github/agents/11-devops.agent.md" \
  ".github/agents/12-retrospective.agent.md"

stage_has_skill \
  "Release/Closure" \
  "document-lifecycle" \
  ".github/agents/10-uat.agent.md" \
  ".github/agents/11-devops.agent.md" \
  ".github/agents/12-retrospective.agent.md"

stage_has_skill \
  "Release/Closure" \
  "obsidian-workflow" \
  ".github/agents/10-uat.agent.md" \
  ".github/agents/11-devops.agent.md" \
  ".github/agents/12-retrospective.agent.md"

stage_has_skill \
  "Process Hardening" \
  "analysis-methodology" \
  ".github/agents/13-pi.agent.md"

stage_has_skill \
  "Process Hardening" \
  "document-lifecycle" \
  ".github/agents/13-pi.agent.md"

stage_has_skill \
  "Process Hardening" \
  "planka-workflow" \
  ".github/agents/13-pi.agent.md"

if [ "$errors" -gt 0 ]; then
  printf '\nSkill-gate coverage check failed with %s error(s).\n' "$errors"
  exit 1
fi

printf '\nSkill-gate coverage check passed.\n'