# Required Files Catalog (New Project Bootstrap)

This catalog defines the minimum file set required for strict and organized operation of agents, skills, and governance checks.

## Goal

- Keep governance source-of-truth in `.github/`.
- Allow deterministic recovery when required files are missing.
- Make recovery agent-friendly via explicit file descriptions and scaffold instructions.

## Bootstrap Commands

- Check required files:
  - `sh .github/scripts/scaffold_required_files.sh`
- Scaffold missing files where templates exist:
  - `sh .github/scripts/scaffold_required_files.sh --create-missing`
- Validate governance contract:
  - `sh .github/scripts/check_strict_governance.sh`
- Validate workflow node contract (full scan):
  - `sh .github/scripts/check_workflow_contract.sh`
- Validate skill-gate coverage:
  - `sh .github/scripts/check_skill_gate_coverage.sh`
- Validate Native graph contract:
  - `sh .github/scripts/check_native_graph_contract.sh`

## Required File Groups

### 1) Governance Core

| Path | Why required |
|---|---|
| `.github/reference/strict-workflow-governance.md` | Contract for context, tools, skills, role gates |
| `.github/reference/required-files-catalog.md` | Recovery descriptions for missing required files |

Custom-agent operational rules are embedded directly in each `.github/agents/*.agent.md` file.

### 2) Agent & Skill Runtime

| Path | Why required |
|---|---|
| `.github/agents/01a-Roadmap.agent.md` … `.github/agents/05c-ProcessImprovement.agent.md` | Role definitions and responsibilities |
| `.github/skills/workflow-memory/SKILL.md` | WF node memory and existence gates |

### 3) CI Enforcement

| Path | Why required |
|---|---|
| `.github/workflows/markdown-lint.yml` | Markdown + governance checks in CI |
| `.github/scripts/check_strict_governance.sh` | Ensures required governance files and markers exist |
| `.github/scripts/check_workflow_contract.sh` | Ensures WF nodes meet frontmatter/section/link rules |
| `.github/scripts/check_skill_gate_coverage.sh` | Ensures phase/role skill-gate coverage across custom agents |
| `.github/scripts/check_native_graph_contract.sh` | Ensures agent-level Native graph parent-edge/handoff contract declarations |
| `.github/scripts/scaffold_required_files.sh` | Creates missing required files from scaffold templates |

Required automation scripts are centralized in `.github/scripts/` and are not required inside `.github/skills/*`.

### 4) Workspace Bootstrap (outside `.github`, scaffolded from `.github`)

| Path | Why required |
|---|---|
| `.vscode/mcp.json` | MCP namespace mapping expected by external tools (e.g., github) |
| `agent-output/.next-id` | Unified lifecycle ID counter |

## Recovery Rules

1. If a required file is missing, run scaffold with `--create-missing`.
2. If a file is scaffolded as a minimal stub, replace it with full canonical content before production use.
3. Always re-run both checks after recovery:
  - `sh .github/scripts/check_strict_governance.sh`
  - `sh .github/scripts/check_workflow_contract.sh`
  - `sh .github/scripts/check_skill_gate_coverage.sh`
  - `sh .github/scripts/check_native_graph_contract.sh`

## Notes for New Projects

- Copy the `.github/` folder first.
- Then run scaffold to create non-`.github` bootstrap files (`.vscode/mcp.json`, `agent-output/.next-id`).
- Initialize standard workspace tools and necessary external MCP services (e.g., github) before agent execution.
