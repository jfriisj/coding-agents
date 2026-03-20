# Strict Workflow Governance Contract

This contract is mandatory for all custom agents (`01`-`13`) and all workflow phases.

## 1) Context Gate (Before Any Substantial Work)

Every agent must start with a deterministic context package:

1. **Source Artifact**: active document path in `agent-output/*`.
2. **WF Node**: concrete `[[WF-...]]` that scopes the work.
3. **Planka Card**: numeric card ID.
4. **Target Outcome**: what decision/change must be true at handoff.
5. **Open Risks**: unresolved blockers that can affect correctness.

If WF node is missing, create a minimal compliant node before proceeding.

## 2) Tool Gate (No Silent Bypass)

1. Use native MCP namespaces first: `planka/*`, `obsidian/*`, `filesystem/*`, `analyzer/*`.
2. Confirm required write operations are available before execution.
3. If a required operation is unavailable, **halt and report blocker**, then apply approved fallback only.

### Approved Fallbacks

- If Planka `delete_list` is unavailable:
  - Keep canonical lifecycle lanes active.
  - Rename non-canonical active lanes to `LEGACY - ...`.
  - Move legacy lanes to far-right positions.
  - Ensure legacy lanes contain zero cards.

### Script Ownership Rule

- Required repository governance automation MUST live in `.github/scripts/`.
- Skills (`.github/skills/*`) should remain instruction-first and tool-contract-first; skill-local scripts, if ever introduced, are optional helpers and MUST NOT be required for repository bootstrap or CI gates.

### Tool Scope by Role (Least-Privilege Guidance)

| Role | Primary tool families | Must avoid by default |
|---|---|---|
| Roadmap/Planner/Critic | `filesystem/*`, `obsidian/*`, `planka/*` | direct code edits, broad terminal workflows |
| Analyst/Architect/Security | `filesystem/*`, `obsidian/*`, `planka/*` | implementation mutations unless explicitly requested |
| Implementer | code edit/read/search + optional lightweight `analyzer/*` preflight on touched Python files + targeted `planka/*`/`obsidian/*` | planner-owned artifact edits |
| Code Reviewer/QA | read/search + role docs + `analyzer/*` + `planka/*`/`obsidian/*` | production code implementation |
| UAT | read/search + role docs + `planka/*`/`obsidian/*` | production code implementation |
| DevOps | release/doc tooling + `planka/*`/`obsidian/*` | feature coding |
| Retrospective/PI | documentation + `planka/*`/`obsidian/*` | source-code feature changes |

## 3) Skill Gate (Required Activations by Phase)

- **Roadmap/Planning phases**: `planka-workflow`, `obsidian-workflow`, `document-lifecycle`.
- **Analysis/Architecture/Security**: respective domain skill + `obsidian-workflow`.
- **Implementation/Review/QA/UAT**: role skill(s) + `planka-workflow` + `obsidian-workflow`.
- **Release/Retrospective/PI**: `release-procedures` or process skill + `document-lifecycle`.

If a required skill is not applicable, agent must state why.

### Skill Ownership by Stage

| Stage | Mandatory skills |
|---|---|
| Strategy/Planning | `planka-workflow`, `obsidian-workflow`, `document-lifecycle` |
| Analysis/Design/Security | domain skill + `obsidian-workflow` |
| Build/Verify | `testing-patterns` / `code-review-standards` / `engineering-standards` + `planka-workflow` |
| Release/Closure | `release-procedures`, `document-lifecycle`, `obsidian-workflow` |
| Process hardening | `analysis-methodology`, `document-lifecycle`, `planka-workflow` |

## 4) Role Responsibility Gates (Before Handoff)

### All Agents

- Handoff must include concrete `[[WF-...]]` and numeric card ID.
- No placeholders (`[[WF-[ID]]]`, `CARD_ID_NUMERIC`, etc.) in runtime outputs.
- Do not modify artifacts owned by other gates unless explicitly allowed.

### Planner/Critic

- Planner AC-list cardinality equals acceptance criteria count.
- Critic must explicitly evaluate unresolved `OPEN QUESTION` items.

### Implementer/Code Reviewer/QA

- Implementer: TDD evidence and implementation artifact complete.
- Code Reviewer: code-quality verdict documented before QA starts.
- QA: test evidence documented; no release handoff if quality gate fails.

### UAT/DevOps

- UAT must issue both plan-level and epic-level decisions.
- DevOps must enforce release gate from epic decisions and user approval.

### Roadmap/Retrospective/PI

- Roadmap maintains release/epic traceability and lifecycle alignment.
- Retrospective captures process failures and controls.
- PI turns recurring failures into instruction updates.

### Full Role Matrix (Custom Agents)

| Agent | Non-negotiable responsibility |
|---|---|
| 01-Roadmap | Own epic/release truth and card-root-node traceability |
| 02-Planner | Enforce AC list cardinality and executable milestone clarity |
| 03-Analyst | Convert unknowns to evidence or explicit uncertainty with validation path |
| 04-Architect | Enforce system coherence and diagnosability invariants |
| 05-Security | Apply mode-scoped security gate with reproducible findings |
| 06-Critic | Block weak plans and unresolved open-question risk |
| 07-Implementer | Deliver TDD-backed implementation aligned to approved plan |
| 08-Code Reviewer | Enforce maintainability/architecture quality gate before QA |
| 09-QA | Validate test sufficiency and execution evidence |
| 10-UAT | Validate business-value delivery and epic decision |
| 11-DevOps | Enforce release gate + user approval before push/release |
| 12-Retrospective | Capture systemic process lessons and control gaps |
| 13-Process Improvement | Convert retrospective signals into instruction updates |

## 5) Planka Strictness Controls

1. Canonical lifecycle lanes must exist and be ordered:
   - `Planned`, `In Progress`, `Delivered`, `Deferred`, `Closed`.
2. Epic cards must include:
   - one release label (`Release v*`),
   - one priority label (`Priority P*`),
   - `Obsidian Root Node` in description.
3. `Delivered` with open tasks requires explicit deferment rationale comment.

## 6) Obsidian Strictness Controls

1. WF IDs must be deterministic and concrete.
2. WF references in comments/handoffs must resolve to existing notes.
3. WF nodes stay concise (10-Line Rule) and link-first.
4. Use alias notes only for backward compatibility with legacy references.

### Automated Enforcement

- Run `sh .github/scripts/check_strict_governance.sh` to verify required governance files and markers.
- Run `sh .github/scripts/check_workflow_contract.sh` to enforce WF-contract compliance across all workflow notes.
- Run `sh .github/scripts/check_skill_gate_coverage.sh` to verify phase/role skill-gate coverage across custom agents.
- Run `sh .github/scripts/check_obsidian_graph_contract.sh` to verify agent-level Obsidian graph parent-edge and handoff contract declarations.
- Run `sh .github/scripts/scaffold_required_files.sh --create-missing` to scaffold missing required files from documented templates.

## 7) Definition of Done for Handoff

A handoff is valid only when:

- Context gate passed.
- Tool gate passed (or blocker + approved fallback documented).
- Skill gate passed.
- Role gate passed.
- Evidence artifacts updated.
- Final line present:

`Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC).`
