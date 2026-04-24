# Workflow Context Model

This repository uses the workflow graph as the durable memory layer and the compiled context files as a task-scoped JIT cache.

## Active Workflow Structure

- Group related workflow notes under `agent-output/workflows/epic-*/`.
- Group same-chain notes one level deeper by ID when it makes the graph easier to scan.
- Keep closed lifecycle artifacts in `closed/` folders.
- Keep each `WF-*` node concrete and linked to its immediate parent.

## Context Files

### `agent-output/.context-baseline.md`

- Generated from the current WF node plus its parent chain.
- Contains only the context required for the current epic or work item.
- Must not be edited manually.

### `agent-output/.context-append.md`

- Stores reusable findings that were discovered while working the current task.
- Use it for compact, durable insights that should help the next agent.
- Keep it narrow and additive.

### `agent-output/.context.md`

- Treat this as a legacy or historical snapshot unless a workflow explicitly references it.
- Do not expand it into a release-sized knowledge dump.

## Scope Rule

The compiled context should cover one current epic/work item at a time, not an entire release.

- If a release spans multiple epics, model that as multiple WF subtrees.
- Let the parent WF node carry just enough release linkage to find the relevant epic subtree.
- Keep the baseline focused so agents do not spend context on unrelated release material.

## Agent Applicability

All custom agents use the same model:

- read the relevant WF node
- compile the JIT baseline for the current epic/work item
- consume the append log if it exists
- add only new, reusable knowledge back into append
- avoid turning one context file into a release-wide knowledge store