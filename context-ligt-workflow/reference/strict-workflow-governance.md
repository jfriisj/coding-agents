# Strict Workflow Governance Contract

This contract is mandatory for all custom agents (`01`-`13`) and all workflow phases.

## 1) Context Gate (Before Any Substantial Work)

Every agent must start with a deterministic context package:

1. **Source Artifact**: active document path in `agent-output/*`.
2. **WF Node**: concrete `workflows/WF-*.md` file that scopes the work. The WF node must represent one current epic or work item, not an entire release bundle.
3. **Placement Rule**: active workflow files should live under the matching epic subtree, with optional ID subfolders for scanability. Avoid placing active work directly at the `agent-output/workflows/` root when a matching epic folder exists.
3. **JIT Context Buffer (Consumers Only)**: execution of `sh .github/scripts/compile_context.sh` and reading of `.context-baseline.md` (and `.context-append.md` if it exists) before proceeding. The baseline must stay narrow and task-scoped.
4. **Target Outcome**: what decision/change must be true at handoff.
5. **Open Risks**: unresolved blockers that can affect correctness.

If WF node is missing, create a minimal compliant node before proceeding.

## 2) Tool Gate (No Silent Bypass)

1. Use standard workspace file tools first (e.g., `read/readFile`, `edit/editFiles`, `search`).
2. Confirm required write operations are available before execution.
3. **JIT Compilation Execution**: Downstream agents (Requirements, Critic, Designer, Implementer) MUST use `execute/runInTerminal` to compile context, followed explicitly by a read tool to consume it. They must not guess context.
4. If a required operation is unavailable, **halt and report blocker**, then apply approved fallback only.

### Script Ownership Rule

- Required repository governance automation MUST live in `.github/scripts/`.
- Skills (`.github/skills/*`) should remain instruction-first and tool-contract-first; skill-local scripts, if ever introduced, are optional helpers and MUST NOT be required for repository bootstrap or CI gates.

### Tool Scope by Role (Least-Privilege Guidance)

| Role | Primary tool families | Must avoid by default |
|---|---|---|
| Roadmap/Requirements/Planner/Critic | standard file tools, `search`, `execute/runInTerminal` (for JIT) | direct code edits, broad terminal workflows |
| Analyst/Architect/Security | standard file tools, `search`, `execute/runInTerminal` | implementation mutations unless explicitly requested |
| Designer | standard file tools, `search`, `execute/runInTerminal` | direct code edits, test execution |
| Implementer | code edit/read/search + `execute/*` | planner-owned artifact edits |
| TestRunner | `execute/runInTerminal`, `execute/awaitTerminal`, `execute/getTerminalOutput`, standard file tools | direct code edits, artifact edits |
| Code Reviewer/QA | read/search + role docs + terminal linters | production code implementation |
| UAT | read/search + role docs | production code implementation |
| DevOps | release/doc tooling | feature coding |
| Retrospective/PI | documentation tools | source-code feature changes |

## 3) Skill Gate (Required Activations by Phase)

- **Strategy/Requirements/Planning phases**: `workflow-memory`, `document-lifecycle`.
- **Analysis/Architecture/Security**: respective domain skill + `workflow-memory`.
- **Design/Implementation/Review/QA**: role skill(s) + `workflow-memory`.
- **Release/Retrospective/PI**: `release-procedures` or process skill + `document-lifecycle`.

If a required skill is not applicable, agent must state why.

### Skill Ownership by Stage

| Stage | Mandatory skills |
|---|---|
| Strategy/Requirements/Planning | `workflow-memory`, `document-lifecycle` |
| Analysis/Design/Security | domain skill + `workflow-memory` |
| Build/Verify | `testing-patterns` / `code-review-standards` / `engineering-standards` |
| Release/Closure | `release-procedures`, `document-lifecycle`, `workflow-memory` |
| Process hardening | `analysis-methodology`, `document-lifecycle` |

## 4) Role Responsibility Gates (Before Handoff)

### All Agents

- Handoff must include concrete path to `workflows/WF-*.md` and numeric card ID.
- No placeholders (`WF-[ID].md`, `CARD_ID_NUMERIC`, etc.) in runtime outputs.
- Do not modify artifacts owned by other gates unless explicitly allowed.
- **NEVER overwrite `.context-baseline.md`.** Append new context only to `.context-append.md`.

### Requirements/Planner/Critic

- Requirements: Must interview user, define explicit IN/OUT scope, write testable ACs, and forward JIT pointers.
- Planner: AC-list cardinality equals acceptance criteria count.
- Planner: MUST export exact JIT pointers to the workflow node; monolithic spec handoffs are forbidden.
- Critic: Must explicitly evaluate unresolved `OPEN QUESTION` items and verify JIT pointers exist.

### Designer/Implementer/TestRunner/Code Reviewer/QA

- Designer: Technical spec mapped to `app/core/adapters` parity with Mermaid diagrams complete.
- Implementer: JIT Context executed and read FIRST. TDD evidence and implementation artifact complete.
- TestRunner: Execute heavy test suites, capture deterministic terminal evidence, and isolate stack traces.
- Code Reviewer: code-quality verdict documented using static-analysis tools before QA starts.
- QA: test evidence documented; no release handoff if quality gate fails.

### UAT/DevOps

- UAT must issue both plan-level and epic-level decisions.
- DevOps must enforce release gate from epic decisions and user approval.

### Roadmap/Retrospective/PI

- Roadmap maintains release/epic traceability, lifecycle alignment, and seeds global JIT constraints.
- Retrospective captures process failures and controls.
- PI turns recurring failures into instruction updates.

### Full Role Matrix (Custom Agents)

| Agent | Non-negotiable responsibility |
|---|---|
| 01a-Roadmap | Own epic/release truth and seed global JIT context pointers |
| 01b-Requirements | Translate epic into explicit scope/ACs, interview user, and forward JIT pointers |
| 02a-Planner | Enforce AC list and export exact JIT Context Pointers (no monolithic specs) |
| 02b-Analyst | Convert unknowns to evidence or explicit uncertainty with validation path |
| 02c-Architect | Enforce system coherence, diagnosability invariants, and JIT pointer export |
| 02d-Security | Apply mode-scoped security gate with reproducible findings |
| 02e-Critic | Block weak plans, missing JIT pointers, and unresolved open-question risk |
| 02f-Designer| Translate plan into LLD, Mermaid diagrams, and app/core/adapter parity maps |
| 03a-Implementer | Execute/Read JIT context first, then deliver TDD-backed implementation |
| 03b-TestRunner | Execute heavy integration/E2E pipelines and gather deterministic terminal evidence logs |
| 03c-CodeReviewer | Enforce maintainability/architecture quality gate before QA |
| 04a-QA | Validate test sufficiency and execution evidence |
| 04b-UAT | Validate business-value delivery and epic decision |
| 05a-DevOps | Enforce release gate + user approval before push/release |
| 05b-Retrospective | Capture systemic process lessons and control gaps |
| 05c-ProcessImprovement | Convert retrospective signals into instruction updates |

## 5) Workflow Graph Strictness Controls

1. WF IDs must be deterministic and concrete.
2. WF references in comments/handoffs must resolve to existing files.
3. WF nodes stay concise (10-Line Rule) and link-first using standard markdown syntax `[text](path)`.
4. Global spec constraints MUST be passed via `### Required Context Pointers` inside the WF node.
5. Release-sized knowledge must be decomposed into multiple epic/work-item WF subtrees; do not encode one full release as a single context baseline.
6. Canonical naming must use role-hyphen-ID form for new files, for example `WF-DES-208-...` and `WF-IMPL-216-...`. Do not introduce compacted legacy forms such as `WF-DES208-...` or mixed `WF-IM`/`WF-IMPL` variants for new artifacts.

### Automated Enforcement

- Run `sh .github/scripts/check_strict_governance.sh` to verify required governance files.
- Run `sh .github/scripts/check_workflow_contract.sh` to enforce WF-contract compliance.

## 6) Memory & File Boundary Constraints (Anti-Pattern Override)

**CRITICAL OVERRIDE**: You are operating in a secured, Sandboxed environment. 
- **NO GLOBAL MEMORY**: You MUST NOT attempt to read from IDE-specific global memory directories (e.g., `/memories/repo/*`, `~/.cursor/`, etc.). These paths are blocked and will result in `Access denied`.
- **THE WORKFLOW GRAPH IS THE ONLY MEMORY**: All historical context, repo facts, and architectural rules are stored in the `agent-output/workflows/` directory and related artifacts. 
- If you need to find historical facts, rules, or previous decisions, you MUST use native file search tools (like `grep` or editor search) or traverse the `parent:` links in the `WF-*` nodes.

## 7) Definition of Done for Handoff

A handoff is valid only when:

- Context gate passed (including JIT compilation script execution and reading of `.context-baseline.md` for consumers).
- Tool gate passed (or blocker + approved fallback documented).
- Skill gate passed.
- Role gate passed.
- Document lifecycle rules applied (completed artifacts moved to `closed/`).
- Final line present:

`Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md`
