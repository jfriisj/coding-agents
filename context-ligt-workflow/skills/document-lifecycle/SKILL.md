---
name: document-lifecycle
description: Unified document lifecycle management. Defines terminal statuses, unified numbering via .next-id, close procedures, and orphan detection. Uses standard workspace file tools. Use this skill when managing the state transitions of documents in `agent-output/`, ensuring consistent closure, and maintaining the integrity of the document lifecycle across all agents.
---

# Document Lifecycle Skill

Manages document state transitions, unified numbering, and automated closure across all `agent-output/` directories.

---

## 1. Document & Workflow Sync (Lifecycle & Closure)

When a document reaches a terminal state, the lifecycle event must be reflected across both structural layers using **Native File Tools**:
1. **Execution Artifact (`agent-output/`)**: The artifact is updated with a terminal status and moved to a `closed/` subfolder.
2. **Workflow Graph (`workflows/WF-*.md`)**: The workflow node's summary is appended to reflect the closure/release.

---

## 2. Terminal Statuses

These statuses trigger document closure (move to `closed/`):

| Status | Meaning | Handled By |
|--------|---------|-----------|
| `Committed` | Changes committed to git (awaiting release) | 05a-DevOps |
| `Released` | Successfully pushed/published to production | 05a-DevOps |
| `Abandoned` | Explicitly dropped, will not proceed | User / 02a-Planner |
| `Deferred` | Postponed indefinitely | User / 02a-Planner |
| `Superseded` | Replaced by a newer document | User / 02a-Planner |
| `Resolved` | All findings addressed (critiques only) | 02e-Critic |

---

## 3. Unified Numbering Protocol

Every work chain shares a single ID (e.g., analysis `080` → plan `080` → QA `080`).

### The `.next-id` File
Location: `agent-output/.next-id`

**Rules (No Terminal/Bash):**
- Only **originating agents** (`02b-Analyst` or `02a-Planner` when no analysis exists) read and increment.
- Downstream agents **inherit** the ID from their source document.
- Use native file tools (e.g., `read/readFile` or `filesystem/read_text_file`) to read the current ID.
- Use native file tools (e.g., `edit/editFiles` or `filesystem/write_file`) to save the incremented ID.

### Document Header Format
Every document in `agent-output/` MUST include this YAML frontmatter:

```yaml
---
ID: 080                    # Global sequence number
Origin: 080                # Chain origin (same as ID for originating docs)
UUID: a3f7c2b1             # 8-char random hex
Status: Active             # Current lifecycle state
---
```

---

## 4. The Close Procedure (Automated via Script)

When a document reaches a terminal status, you MUST use the provided automation script to safely update its frontmatter and relocate it.

1. Ensure you have added any final notes or changelog entries to the file using your standard edit tools.
2. Use `execute/runInTerminal` to execute the close script:
   `sh .github/scripts/close_document.sh <path-to-file.md> "<Terminal-Status>"`
   *(Example: `sh .github/scripts/close_document.sh agent-output/planning/080-auth.md "Committed"`)*
3. Verify the terminal outputs "Success".

---

## 5. Orphan Detection (Agent Self-Check)

**Every Session Start:**
Before starting work, each agent MUST check their domain for orphaned terminal documents:

1. Use directory listing tools (e.g., `search/listDirectory` or `filesystem/list_directory`) on your exclusive domain (e.g., `agent-output/qa/`).
2. Ignore the `closed/` folder.
3. Read the frontmatter of the active files. If any file has a terminal Status (`Committed`, `Released`, `Abandoned`, `Deferred`, `Superseded`, `Resolved`), it is an orphan.
4. Relocate it to `closed/`.
5. Log in your chat response: *"Found orphaned document [name] with Status [status], moved to closed/."*