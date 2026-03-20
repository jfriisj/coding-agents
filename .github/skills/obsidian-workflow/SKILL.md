---
name: obsidian-workflow
description: Relational memory graph workflow using native Obsidian MCP tools with strict token-efficient WF node conventions. Use this for multi-agent workflows that require structured handoffs, relational context, and artifact linking without duplicating content from `agent-output/*` artifacts.
---

# Obsidian Workflow (Memory Graph)

Obsidian is the relational memory layer for this multi-agent workflow.
It does **not** replace `agent-output/*` artifacts and it does **not** own execution status.

## Triad of Truth
1. **Markdown (`agent-output/`)**: Canonical artifacts (full detail)
2. **Obsidian (`workflows/`)**: Relational context and handoff pointers
3. **Planka**: Live execution status and ownership

## WF Node Contract (10-Line Rule)

Use concise `WF-*` notes only. Do not duplicate full artifact content.

```markdown
---
type: [Epic | Plan | Analysis | Architecture | Security | Critique | Implementation | QA | UAT | Deployment | Retrospective | ProcessImprovement]
parent: "[[WF-...]]" # use "none" only for root epic nodes
Planka-Card: "CARD_ID_NUMERIC"
artifact_hash: "SHA256_EXTRACTED_FROM_SCRIPT"
---

## Summary
- [Max 3 bullets: key decision/constraint/outcome]

## Artifacts
- [[agent-output/path/to/artifact.md]]
```

## Deterministic WF-ID Contract (Mandatory)

WF IDs must be concrete and reproducible. Placeholder IDs are forbidden.

Use these conventions:
- **Epic root nodes**: `WF-E<epic-number>` (example: `WF-E1.2`)
- **Plan nodes**: `WF-P<plan-id>` (example: `WF-P001`)
- **Phase nodes**: `WF-<TYPE>-<plan-id>`
  - Examples: `WF-AN-001`, `WF-AR-001`, `WF-IMPL-001`, `WF-QA-001`, `WF-UAT-001`, `WF-DEP-001`

If an epic has no plan ID yet, reference the epic root (`WF-E...`) only.

### Placeholder Ban

Never emit placeholders such as:
- `[[WF-[ID]]]`
- `[[WF-Epic-ID]]`
- `[[WF-Plan-ID]]`
- `[[WF-Calling-ID]]`

All handoff messages and Planka comments must contain a concrete `[[WF-...]]` link.

## Allowed Operations (Native MCP Only)
- Use `read_note`, `write_note`, `patch_note`, and frontmatter update tools.
- Do not use terminal scripts for graph operations.
- Do not manually maintain index files.

## Retrieval Discipline
- Start from provided `[[WF-ID]]` handoff note.
- Follow only `parent:` if broader context is required.
- Read full artifacts only when summary bullets are insufficient.

## WF Existence Gate (Before Handoff/Planka Comment)

Before writing a handoff message or Planka comment that references `[[WF-...]]`:
1. Resolve a concrete WF ID via the deterministic contract.
2. Attempt targeted read on that exact note (`read_note`).
3. If missing, create a minimal compliant note (`write_note`) with required frontmatter.
4. Then emit handoff/comment using that concrete, existing `[[WF-...]]` link.

## Strict Governance Hooks (Mandatory)

1. Apply `.github/reference/strict-workflow-governance.md` on every workflow update.
2. Use alias nodes only for backward compatibility with legacy links.
3. Alias nodes MUST include `status: alias` and `canonical: "[[WF-...]]"` frontmatter.
4. If a referenced WF node cannot be created or verified, halt handoff and report blocker.

## Handoff Contract
Before concluding, output:

> "Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC)."

## Token Budget Guidance
- 0 broad vault searches
- Max 2 note reads
- Max 2 note writes/patches
- Keep notes link-first and minimal
