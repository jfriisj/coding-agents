---
name: planka-workflow
description: Agile Epic Management and synchronization contract for Planka MCP. Markdown remains the source of truth; Planka provides live agile execution visibility via Native MCP Tools exclusively. Python scripts are strictly forbidden.
---

# Planka Workflow (Agile Epic Management)

Unified Agile workflow tracking with Planka boards.

Use this skill when:
- Synchronizing Epics from the project roadmap to Planka.
- Breaking down Acceptance Criteria into actionable Tasks.
- Executing cross-functional work (Analysis, Architecture, Security, QA) on a shared Epic.
- Tracking execution time and status transitions.

---

## 1. The Triad of Truth Architecture

Our system strictly follows a three-pillar architecture for state, context, and execution:

1. **Markdown (`agent-output/`)**: "What" and "Why". The canonical source of truth.
2. **Obsidian Graph (`workflows/`)**: "How it connects". Our memory graph using `obsidian/*` tools (10-Line Rule).
3. **Planka Board**: "Who does what and status". The live operational Agile Kanban view using **Native Planka MCP Tools**.

**When conflicts occur:**
1. Trust the Markdown artifacts in `agent-output/` first.
2. Ensure the Obsidian `WF-<concrete-id>` node correctly points to the artifact.
3. Update Planka to match the Markdown/Obsidian state.
4. Add a comment on the Planka card detailing the reconciliation.

---

## 2. Board & Card Structure

**Project**: Use the project name derived from the first `#` heading in `agent-output/roadmap/product-roadmap.md`.
**Board**: `Epics`

**Status Lists (Lifecycle):**
1. `Planned`
2. `In Progress`
3. `Delivered`
4. `Deferred`
5. `Closed`

**The Epic Card:**
- **Title**: `Epic [X.Y]: [Title]`
- **Description**: Contains User Story, Business Value, Dependencies, Acceptance Criteria, and the `**Obsidian Root Node**: [[WF-E<epic-number>]]`.
- **Labels**: `Release vX.Y.Z`, `Priority P0|P1|P2|P3`, plus specific status labels (e.g., `QA Passed`).

---

## 3. Agent Workspaces (Task Lists)

Instead of moving cards between columns, the card stays in its Status List. Agents create and manage their own **Task Lists** inside the Epic card:

- `AC[n]: <Acceptance Criterion Summary>` (Planner; one list per acceptance criterion)
- `Analysis & Spikes` (Analyst)
- `Architecture & Design` (Architect)
- `Security & Compliance` (Security)
- `Implementation` (Implementer)
- `Code Review` (Code Reviewer)
- `QA & Testing` (QA)
- `UAT & Acceptance` (UAT)
- `Release & Deployment` (DevOps)
- `Retrospective & Learnings` (Retrospective/PI)

### Planner AC Task-List Contract (Mandatory)

1. Parse acceptance-criteria bullets from the Epic card description.
2. Build canonical planner list names in order: `AC1: ...`, `AC2: ...`, ... `ACN: ...`.
3. Reconcile existing planner lists before creating new ones:
  - Reuse existing matching `ACn:` lists when present.
  - If a legacy planner list maps to a criterion, rename it using `update_task_list`.
  - If a legacy planner list does not match canonical naming, move/recreate tasks into canonical `ACn:` lists and remove the legacy list (`delete_task_list`).
4. Ensure **exact cardinality**: number of planner `ACn:` lists MUST equal number of acceptance criteria.
5. Map every planning milestone task into one `ACn:` list.
6. **Forbidden planner list names**: `Detailed Planning`, `Planner Checklist`, `General`, `Misc`.
7. If no detailed plan artifact exists yet, create placeholder tasks marked `(pending Plan ID)` inside the appropriate `ACn:` list.

---

## 4. Operational Guidance (Strictly Native MCP)

**CRITICAL RULE**: Terminal CLI wrappers and Python scripts (like `sync_roadmap_epics.py` or `planka_ops.py`) are **strictly forbidden**. All agents MUST use Native MCP Tools.

### Native Tool Calling:
* **Discovery**: `list_projects`, `list_boards`, `get_board`, `get_card`
* **Card & List management**: `create_card`, `update_card`, `move_card`
* **Task management**: `create_task_list`, `update_task_list`, `delete_task_list`, `create_task`, `update_task`, `delete_task` (set `isCompleted: true` to drive progress bar)
* **Visual Status**: `create_label`, `add_label_to_card`
* **Audit trail & Triad Bridge**: `add_comment` (must include `[[WF-ID]]` and artifact link)
* **Time tracking**: `update_card` (modifying the stopwatch field)

---

## 5. Agent Workflow Playbook

When an agent works on an Epic, they **MUST** follow this execution order:

1. **Update Markdown**: Save work in `agent-output/`.
2. **Update Obsidian**: Create/update the `WF-<concrete-id>` node (10-Line Rule).
3. **Start Time**: Call `update_card` to start the stopwatch.
4. **Task Lists**:
  - Planner: enforce the AC Task-List Contract above, including legacy-list reconciliation and exact AC-list cardinality.
  - Non-planner agents: create/update only your own workspace list (e.g., `Architecture & Design`, `QA & Testing`).
  - Log actionable items via `create_task`; complete with `update_task`.
5. **Labels**: Apply visual status labels via `add_label_to_card`.
6. **Handoff & Artifacts**: Call `add_comment` to leave a verdict. Include:
  - markdown artifact path,
  - `[[WF-ID]]` node,
  - final handoff line: `Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC).`
7. **Stop Time**: Call `update_card` to stop the stopwatch.
8. **Compliance Self-Check (before conclude)**:
  - Planner has `AC1...ACN` lists matching acceptance criteria with exact count equality.
  - No duplicate AC indices exist (no duplicate `AC1`, `AC2`, etc.).
  - No planner tasks remain in legacy/non-AC planner lists.
  - No forbidden generic planner list names exist.
  - Handoff comment includes artifact + `[[WF-ID]]` + card ID.
  - No WF placeholders are present (`[[WF-[ID]]]`, `[[WF-Epic-ID]]`, etc.).
  - Referenced `[[WF-...]]` node exists (create minimal note first if missing).

---

## 6. Workflow Index

For cross-instance recovery, agents should maintain `agent-output/planka/workflow-index.md` as a JSON block mapping the Triad:

```json
{
  "workflows": {
    "WF-000-example": {
      "boardId": "<board-id>",
      "cardId": "<card-id>",
      "currentAgent": "01-Roadmap",
      "currentStatus": "Planned",
      "primaryArtifact": "agent-output/planning/NNN-plan.md",
      "obsidianNode": "[[WF-000-example]]"
    }
  }
}
```

## 7. Strict Governance Hooks (Mandatory)

1. Apply `.github/reference/strict-workflow-governance.md` in every Planka operation sequence.
2. Keep canonical lifecycle lanes present and ordered:
  - `Planned`, `In Progress`, `Delivered`, `Deferred`, `Closed`.
3. If `delete_list` is unavailable in runtime tools:
  - rename non-canonical active lanes to `LEGACY - ...`,
  - move them to far-right positions,
  - ensure they contain zero cards.
4. `Delivered` cards with open tasks require explicit deferment rationale comment.
5. Every epic card must have:
  - one `Release v*` label,
  - one `Priority P*` label,
  - description field containing `Obsidian Root Node: [[WF-E...]]`.
