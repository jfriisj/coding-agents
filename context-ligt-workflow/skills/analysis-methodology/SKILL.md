---
name: analysis-methodology
description: A structured approach to investigating unknowns, classifying findings by confidence level, and tracking remaining gaps. Integrates strictly with Native Workflow Memory. Use this skill when performing root cause analysis, investigating bugs/incidents, or evaluating system behavior.
---

# Analysis Methodology

A systematic approach to converting unknowns to knowns through structured investigation, with strict native workflow memory integration.

## Core Principle

**Objective**: Every analysis session should reduce uncertainty. If an unknown cannot be resolved, document *why* and *what is needed* to close it.

**The Hard Pivot (Incident/Bug Work)**: If a root cause cannot be proven with available evidence within a reasonable timebox, you must NOT force a narrative or guess. Instead, trigger a "Hard Pivot":
1. Stop digging.
2. Pivot to documenting system/architectural weaknesses.
3. Define the exact **Observability Gaps**: What minimal telemetry (correlation IDs, state markers) is needed to isolate the issue next time? Classify this telemetry as *normal* (always-on) vs *debug* (opt-in).

---

## Confidence Levels

Classify every finding by its evidence strength:

| Level | Label | Meaning | Example |
|---|---|---|---|
| 1 | **Proven** | Verified by code execution, POC, or reproducible test. | "Running `npm test -- --filter=X` confirms the error." |
| 2 | **Observed** | Seen in logs, monitoring, or direct inspection, but not isolated. | "The error appears in production logs at 3am." |
| 3 | **Inferred** | Derived from documentation, patterns, or logical deduction. | "The API docs suggest this should return 404." |

**Rule**: Findings at Level 3 (Inferred) should be flagged for upgrade to Level 1 (Proven) before being used for decisions.

---

## Gap Tracking Template

Use this structure in your artifact to surface remaining unknowns:

```markdown
## Remaining Gaps

| # | Unknown | Blocker | Required Action | Owner |
|---|---------|---------|-----------------|-------|
| 1 | Why does X fail under load? | Cannot reproduce locally. | Need staging access or load test harness. | [TBD] |
| 2 | Does API Y support pagination? | Docs unclear. | Run POC against sandbox. | Analyst |
```

---

## Investigation Techniques

Use these patterns to move unknowns to knowns:

### Log Tracing & Observability

* Add targeted logging to isolate behavior.
* Compare expected vs actual log sequences.
* *If logs are missing, trigger the Hard Pivot.*

### Component Isolation

* Reproduce behavior with minimal dependencies.
* Use mocks/stubs to eliminate variables.

### POC Execution

* Write minimal, runnable code to prove or disprove a behavior.
* POCs must be reproducible by others (check in or share).

### Upstream Tracing

* Follow data/control flow backward to find the root cause.
* Ask: "Where did this value *come from*?"

---

## Analysis Document Structure (`agent-output/analysis/`)

Recommended sections for your full markdown artifact:

1. **Frontmatter** — `ID`, `Origin`, and `Status` (e.g., `Status: Approved`).
2. **Changelog** — Date, handoff context, outcome summary.
3. **Value Statement & Objective** — Why this analysis matters.
4. **Context** — Background, scope, constraints.
5. **Methodology** — What techniques were used (e.g., POC, Log Tracing).
6. **Findings** — Factual results, classified by Confidence Level (1-3).
7. **Gap Tracking Table** — (see template above).
8. **Analysis Recommendations** — Next steps *to deepen inquiry* or implement.

---

## Document & Workflow Sync (The Handoff Protocol)

Before handing off to the Planner or Implementer, you must align the workflow using **standard workspace file tools**:

1. **The Artifact (`agent-output/`)**:
   * Ensure the markdown document is saved with your complete findings.
   * If your analysis task is fully complete, use the close script via terminal to update the status and move it to `closed/`:
     `sh .github/scripts/close_document.sh <path-to-your-file.md> "Resolved"` (or "Approved").

2. **The Memory (Workflow Graph)**:
   * Use native file tools (e.g., `edit/createFile`, `edit/editFiles`) to create or update your `WF-<concrete-id>.md` node in `agent-output/workflows/`.
   * Set frontmatter `type: Analysis` and `parent: "workflows/WF-...md"`.
   * Write a strict 3-bullet TL;DR summary in the note (The 10-Line Rule).
   * Link to your `agent-output/` artifact using standard markdown links.
   * If handing back to a Planner, you may append a standard markdown link to your node inside their node to establish the dependency.

**Final Chat Message**:
Always conclude your turn in the chat with:

> *"Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md"*
