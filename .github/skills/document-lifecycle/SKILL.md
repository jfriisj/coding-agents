---
name: document-lifecycle
description: Unified document lifecycle management. Defines terminal statuses, unified numbering via .next-id, close procedures, and orphan detection. Uses native filesystem MCP tools. Use this skill when managing the state transitions of documents in `agent-output/`, ensuring consistent closure, and maintaining the integrity of the document lifecycle across all agents.
---

# Document Lifecycle Skill

Manages document state transitions, unified numbering, and automated closure across all `agent-output/` directories.

---

## 1. The Triad of Truth (Lifecycle & Closure)

When a document reaches a terminal state, the lifecycle event must be reflected across all three systems using **Native MCP Tools**:
1. **Markdown (`agent-output/`)**: The artifact is updated with a terminal status and moved to a `closed/` subfolder.
2. **Planka Board**: The associated Epic card is moved to the appropriate terminal list (e.g., `Delivered`, `Deferred`, `Closed`) via `move_card`.
3. **Obsidian Graph**: The `WF-` node's summary is patched to reflect the closure/release.

---

## 2. Terminal Statuses

These statuses trigger document closure (move to `closed/`):

| Status | Meaning | Handled By |
|--------|---------|-----------|
| `Committed` | Changes committed to git (awaiting release) | DevOps |
| `Released` | Successfully pushed/published to production | DevOps |
| `Abandoned` | Explicitly dropped, will not proceed | User/Planner |
| `Deferred` | Postponed indefinitely | User/Planner |
| `Superseded` | Replaced by a newer document | User/Planner |
| `Resolved` | All findings addressed (critiques only) | Critic |

---

## 3. Unified Numbering Protocol

Every work chain shares a single ID (e.g., analysis `080` → plan `080` → QA `080`).

### The `.next-id` File
Location: `agent-output/.next-id`

**Rules (No Terminal/Bash):**
- Only **originating agents** (Analyst, Planner when no analysis) read and increment.
- Downstream agents **inherit** the ID from their source document.
- Use `filesystem/read_text_file` to read the current ID.
- Use `filesystem/write_file` to save the incremented ID.

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

## 4. The Close Procedure (Strictly Native MCP)

When a document reaches a terminal status, you MUST follow this sequence using native tools (do NOT use `execute/runInTerminal`):

### Step 1: Update the Artifact

1. Use `read_text_file` (or `edit_file`) to update the `Status:` field in the YAML frontmatter to the terminal status (e.g., `Status: Committed`).
2. Add a changelog entry: `| YYYY-MM-DD | [Your Agent Name] | Document closed | Status: [status] |`

### Step 2: Move the File to `closed/`

1. Use `create_directory` to ensure the target folder exists: `agent-output/<domain>/closed/` (e.g., `agent-output/planning/closed/`).
2. Use `move_file` to relocate the artifact:
* `source`: `agent-output/planning/NNN-name.md`
* `destination`: `agent-output/planning/closed/NNN-name.md`



### Step 3: Update Planka (The Execution State)

If you are the DevOps agent executing a release, or a Planner deferring an Epic:

* Use `planka/move_card` to shift the Epic card from `In Progress` to `Delivered`, `Deferred`, or `Closed`.
* Use `planka/add_comment` to log the closure.

### Step 4: Cross-Reference Updates

When referencing a closed document from another document, use relative paths:

* From active doc to closed doc: `../closed/080-feature.md`
* From closed doc to closed doc: `./080-feature.md` (same folder)

---

## 5. Orphan Detection (Agent Self-Check)

**Every Session Start:**
Before starting work, each agent MUST check their domain for orphaned terminal documents:

1. Use `filesystem/list_directory` on your exclusive domain (e.g., `agent-output/qa/`).
2. Ignore the `closed/` folder.
3. Read the frontmatter of the active files. If any file has a terminal Status (`Committed`, `Released`, `Abandoned`, `Deferred`, `Superseded`, `Resolved`), it is an orphan.
4. Use `move_file` to relocate it to `closed/`.
5. Log in your chat response: *"Found orphaned document [name] with Status [status], moved to closed/."*
