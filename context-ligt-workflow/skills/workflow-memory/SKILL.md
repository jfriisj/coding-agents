---
name: workflow-memory
description: Relational memory workflow using strictly native file paths (no Obsidian/MCP overhead). Enforces Just-In-Time (JIT) context protection (Baseline vs. Append) and strict document lifecycle cleanup to prevent markdown bloat.
---

Reference:
- [Workflow Context Model](references/workflow-context-model.md)

# Native Workflow Memory & JIT Context

This workflow replaces complex external memory servers with clean, deterministic, native markdown files. It separates strategic metadata (`WF-*` nodes) from heavy execution artifacts (`agent-output/*`).

## 1. The WF Node Contract (Standard Markdown)

Use concise `WF-*` files in the `workflows/` directory to track decisions and relations. **Always use standard markdown relative paths**.

Group related workflow nodes under the same epic subtree, and add a deeper ID-based grouping when an epic contains multiple chains. Active workflow notes should not be emitted directly at `agent-output/workflows/` when an epic subtree exists.

Canonical WF filename rules:
- Use role prefixes with hyphens, for example `WF-DES-208-...` and `WF-IMPL-216-...`.
- Do not create compacted forms such as `WF-DES208-...` or `WF-IMPL216-...`.
- Prefer `WF-IMPL-...` for implementation artifacts; `WF-IM-...` is legacy-only and should not be introduced for new work.
- Keep root-level workflow files only for explicit compatibility or historical exceptions.

```markdown
---
type: [Epic | Plan | Analysis | Architecture | Security | Critique | Implementation | QA | UAT | Deployment]
parent: "workflows/WF-001.md" # Provide relative path to parent. Use "none" for root.
---

## Summary
- [Max 3 bullets: key decision/constraint/outcome]

### Required Context Pointers (Planners/Architects Only)
- [Auth Rules](agent-output/architecture.md#Authentication)
- [Data Model](agent-output/spec.md^schema-rules)

## Artifacts
- [Implementation Doc](agent-output/implementation/002-feature.md)
```

## 2. JIT Context Protection (Baseline vs. Append)

To eliminate token burn and prevent agents from hallucinating or overwriting global specifications, context is strictly isolated.

### For Planners/Architects (Generators)
You must map out requirements using the `### Required Context Pointers` block in the `WF-*` node as shown above. Never pass full specification files.

### For Implementers/Reviewers/QA (Consumers)
1. **Compile**: You MUST run `sh .github/scripts/compile_context.sh agent-output/workflows/WF-XXX.md` via terminal.
2. **Read**: Explicitly read `agent-output/.context-baseline.md`. 
3. **CRITICAL OVERRIDE (READ-ONLY)**: You are strictly forbidden from modifying or writing to `.context-baseline.md`. This is the authoritative truth. If you edit this file, you violate the system prompt.
4. **Scope Rule**: The compiled baseline is a JIT slice for the current epic or work item only. If a release spans multiple epics, represent that as separate WF subtrees and keep each baseline narrow.
5. **The Append Log**: If you discover technical unknowns, missing rules, or establish new patterns during execution, you MUST use your native file-writing tools to create or update `agent-output/.context-append.md`. Subsequent agents will read both the baseline and the append log.

## 3. Document Lifecycle (Preventing ".md Hell")

Active workspaces must remain clean.
1. When a document's frontmatter `Status` is updated to a terminal state (`Committed`, `Released`, `Abandoned`, `Superseded`), the active work is done.
2. **Cleanup Obligation**: Before handoff, you MUST move the completed artifact to its respective `closed/` subdirectory (e.g., move `agent-output/planning/001-plan.md` to `agent-output/planning/closed/001-plan.md`) using native terminal commands (`mv`) or workspace edit tools. 
3. `WF-*` nodes remain in the `workflows/` directory permanently as the historical graph.
4. Keep release-level knowledge in the workflow graph, not in the baseline context file. Use the baseline only for the current epic/work item and the append file for reusable deltas.

## 4. Handoff Contract

Before concluding your task, output a clear handoff referencing the standard file path. Do not use placeholders.

> "Handoff Ready. Parent Node context for the next agent is: `agent-output/workflows/WF-XXX.md`"
