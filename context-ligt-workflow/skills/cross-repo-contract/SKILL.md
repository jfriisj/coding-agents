---
name: cross-repo-contract
description: Maintains cross-repository API contracts through local definitions and type validation. Integrates strictly with Native Workflow Memory to coordinate breaking changes. Use this skill when implementing API endpoints or clients, proposing contract changes, or validating contract adherence across repositories.
---

# Cross-Repository API Contract

## 1. Document & Workflow Sync (Contract Coordination)

Cross-repo contract changes are high-risk and require strict coordination across two structural layers:
1. **Source Code (`api-contract/` or `.contracts/`)**: The actual TypeScript definitions and endpoint documentation.
2. **Workflow Graph (`workflows/`)**: `WF-*` nodes MUST explicitly mention contract changes in their 3-bullet summary to warn downstream agents (e.g., `* Breaking API change proposed in types.ts`).

---

## 2. Contract Discovery & Tooling

Before implementing any API endpoint or client, check for contract definitions in these locations using **native file tools** (e.g., `search/listDirectory` or `read/readFile`):

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
1. Read `.contracts/types.ts` (or `api-contract/types.ts`) via `read/readFile` before writing handler code.
2. Import or reference the types directly — **do not redefine them**.
3. Validate that request and response shapes match the contract exactly.

### When Implementing API Clients (Extension/Frontend)
1. Read `api-contract/types.ts` before writing client code.
2. Import types directly from the contract location.
3. Handle all error codes defined in the contract.
4. If the API behaves differently than the contract specifies, flag this as a bug in your analysis/review.

---

## 4. Proposing Contract Changes

When a Planner or Architect proposes a contract change, they MUST align the workflow:

1. **Additive changes** (new optional fields, new endpoints): Safe to propose inline.
2. **Breaking changes** (removing fields, changing types): 
   - Document as an `OPEN QUESTION` with migration notes.
3. **Always bump the version** in `version.ts` when modifying `types.ts`.
4. **Update Workflow Memory**: Use native file tools to ensure the active `WF-<concrete-id>-<slug>.md` node mentions the contract change in its `## Summary`.

---

## 5. Contract Sync & Type Validation

**For Consumer Repos:**
- If this repo consumes an external contract (indicated by `.contracts/`), the contract is synced automatically via GitHub Actions.
- Do not edit files in `.contracts/` directly — they will be overwritten.
- Do not attempt to run sync scripts via terminal. Rely on the CI workflow.

**Type Validation:**
- When a repo has `.contracts/` synced from an external source, you MUST include a test that imports `.contracts/types.ts` and validates handler I/O shapes.
- This catches contract drift before it causes runtime errors.

---

## 6. Document & Workflow Sync (The Handoff Protocol)

Before concluding your turn when modifying or reviewing contracts, you MUST align the workflow using **standard workspace file tools**:

1. **The Artifact (`api-contract/` or `.contracts/`)**: 
   * Save any contract changes or documentation updates using `edit/createFile` or `edit/editFiles`.
   * If applicable, ensure the `version.ts` file is updated.

2. **The Memory (Workflow Graph)**:
   * Use native file tools to create or update your `WF-<concrete-id>-<slug>.md` node.
   * Strictly follow the **10-Line Rule** (frontmatter `type`, `parent`, and max 3-bullet summary explicitly mentioning the contract change).
   * Patch the calling agent's node to append a standard markdown link back to your new node.

**Final Chat Message**:
Always conclude your turn in the chat with:

> *"Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md"*