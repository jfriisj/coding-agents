---
name: cross-repo-contract
description: Maintains cross-repository API contracts through local definitions and type validation. Integrates strictly with Obsidian/Planka via Native MCP to coordinate breaking changes. Use this skill when implementing API endpoints or clients, proposing contract changes, or validating contract adherence across repositories.
---

# Cross-Repository API Contract

## 1. The Triad of Truth (Contract Coordination)

Cross-repo contract changes are high-risk and require strict coordination across the Triad:
1. **Source Code (`api-contract/` or `.contracts/`)**: The actual TypeScript definitions and endpoint documentation.
2. **Obsidian Graph (`workflows/`)**: `WF-` nodes MUST explicitly mention contract changes in their 3-bullet summary to warn downstream agents (e.g., `* Breaking API change proposed in types.ts`).
3. **Planka Board**: Contract changes must be tracked as specific Tasks via Native MCP, and cross-repo dependencies must be flagged in the Epic card's comments.

---

## 2. Contract Discovery & Tooling

Before implementing any API endpoint or client, check for contract definitions in these locations using the **Native `filesystem` MCP tool** (`list_directory` / `read_multiple_files`):

1. **`api-contract/`** — This repo is the source of truth for the contract.
2. **`.contracts/`** — Synced copy from an external source repo (typically via CI).

If neither exists and you are implementing API endpoints, propose creating an `api-contract/` directory following the standard structure:


```text

api-contract/ (or .contracts/)
├── README.md       # Purpose, sync instructions, change process
├── version.ts      # Contract version and changelog
├── types.ts        # TypeScript interfaces for all request/response/error shapes
└── endpoints.md    # Human-readable endpoint documentation

```

---

## 3. Implementation Guidelines

### When Implementing API Endpoints (Backend)
1. Read `.contracts/types.ts` (or `api-contract/types.ts`) via `read_text_file` before writing handler code.
2. Import or reference the types directly — **do not redefine them**.
3. Validate that request and response shapes match the contract exactly.
4. If the contract is missing fields, document as an `OPEN QUESTION` in the plan and create a Task in Planka. **Do not add fields unilaterally**.

### When Implementing API Clients (Extension/Frontend)
1. Read `api-contract/types.ts` before writing client code.
2. Import types directly from the contract location.
3. Handle all error codes defined in the contract.
4. If the API behaves differently than the contract specifies, flag this as a bug in your analysis/review.

---

## 4. Proposing Contract Changes & The Handoff

When a Planner or Architect proposes a contract change, they MUST perform the following Triad alignment:

1. **Additive changes** (new optional fields, new endpoints): Safe to propose inline.
2. **Breaking changes** (removing fields, changing types): 
   - Document as an `OPEN QUESTION` with migration notes.
   - Use Planka's `create_task` to explicitly add a task like: *"Coordinate breaking contract change across repos"*.
   - Use Planka's `add_comment` to flag the breaking change for the human user.
3. **Always bump the version** in `version.ts` when modifying `types.ts`.
4. **Update Obsidian**: Use `obsidian/patch_note` to ensure the active `WF-<concrete-id>` node mentions the contract change in its `## Summary`.

---

## 5. Contract Sync & Type Validation

**For Consumer Repos:**
- If this repo consumes an external contract (indicated by `.contracts/`), the contract is synced automatically via GitHub Actions.
- Do not edit files in `.contracts/` directly — they will be overwritten.
- Do not attempt to run sync scripts via terminal. Rely on the CI workflow.

**Type Validation:**
- When a repo has `.contracts/` synced from an external source, you MUST include a test that imports `.contracts/types.ts` and validates handler I/O shapes.
- This catches contract drift before it causes runtime errors.
