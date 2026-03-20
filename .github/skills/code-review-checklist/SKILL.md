---
name: code-review-checklist
description: Structured code review criteria for pre-implementation (Critic) and post-implementation (Security/Code Reviewer). Exclusively uses token-efficient MCP tools (Analyzer, Filesystem, Search) to replace legacy bash scripts. Integrates strictly with Obsidian/Planka. Use this skill when performing code reviews, whether reviewing plans (Critic) or implemented code (Code Reviewer/Security). This skill defines the specific checks to perform, the severity levels, and the exact tools to use for each check, ensuring a consistent and efficient review process across all agents.
---

# Code Review Checklist

Systematic review criteria for evaluating code and plans. Use this skill when:
- Critic reviews plans before implementation
- Code Reviewer evaluates implemented features
- Security agent conducts code audits
- Architect reviews architectural compliance

## The Triad of Truth (Review & Critique)

Every review verdict must be synchronized across three systems:
1. **Markdown (`agent-output/`)**: The detailed critique or code-review document.
2. **Obsidian Graph (`workflows/`)**: The lightweight `WF-` node (10-Line Rule) linking your review to the Plan or Implementation.
3. **Planka Board**: The specific Task List updated via Native MCP, including visual approval/rejection labels.

---

## Tooling Contract (MCP First, Zero Terminal)

**CRITICAL RULE**: Do NOT use `execute/runInTerminal` to run bash scripts (like `check-complexity.sh` or `run-linters.sh`). Terminal commands require manual user approval and waste tokens. 

Instead, you MUST use these structured MCP and native tools to gather your review evidence:

### 1. Python Code (Use `analyzer` MCP)
- **`analyze-code`**: Run this for a combined RUFF (linting/complexity) and VULTURE (dead code) assessment.
- **`ruff-check`**: Use to find style violations, missing docs, and complexity issues.
- **`vulture-scan`**: Use to detect unused imports, variables, and functions.

### 2. TS/JS/Go/General Code (Use Native `search` & `filesystem`)
- **`directory_tree`** (from `filesystem`): Use to quickly assess project structure and find excessively large directories without reading files.
- **`read_multiple_files`** (from `filesystem`): Use to read specific files identified during search.
- **Native `search` tool**: Use regex queries across the workspace to instantly detect anti-patterns and vulnerabilities.

---

## Post-Implementation Review Checks (Regex & MCP)

When reviewing code, run these specific checks using your tools.

### Check 1: Complexity & Code Smells
*Instead of `check-complexity.sh`, use these heuristics:*
- **High Coupling**: Use `search` with regex `^import\s` or `^from .+ import\s` to find files with massive import blocks.
- **Deep Nesting**: Use `search` with regex `^(\s{16}|\t{4})` to find 4+ levels of indentation.
- **God Objects**: Use `get_file_info` (from `filesystem`) to check file sizes, or visually inspect line counts when reading files. Threshold: > 500 lines.

### Check 2: Pre-Review Safety Checks
*Instead of `pre-review-check.sh`, use the native `search` tool with these exact regex patterns (enable regex mode):*

| Anti-Pattern | Search Regex | Severity |
|---|---|---|
| **Debug Leftovers** | `console\.log\|console\.debug\|debugger\|print\(\|pdb\.set_trace` | MEDIUM |
| **TODO/FIXME** | `(TODO\|FIXME\|XXX\|HACK):` | LOW (Flag for tracking) |
| **Swallowed Errors** | `catch\s*\([^)]*\)\s*\{\s*\}` | HIGH |
| **Hardcoded URLs** | `https?://[a-zA-Z0-9]+(localhost\|127\.0\.0\.1\|staging\|dev\.)` | HIGH |
| **Type Evasion (TS)** | `: any\b\|as any\b\|<any>` | MEDIUM |

### Check 3: Security & Architecture (Manual/Search)

| Category | Check | Severity |
|----------|-------|----------|
| **Input & Auth** | Server-side validation? Auth checks on protected routes? | CRITICAL |
| **Secrets** | No hardcoded credentials? (Check for `password`, `secret`, `key=`) | CRITICAL |
| **Injection** | Parameterized queries used? Output encoded? | CRITICAL |
| **Boundaries** | Module boundaries and dependency direction respected? | HIGH |
| **Performance** | Batch fetches used instead of N+1 query loops? | HIGH |

---

## Pre-Implementation Review (Critic)

When reviewing a Plan (Markdown), read the document using `read_text_file` and assess:

### Value Statement Assessment (MUST START HERE)

| Check | Question | Finding Severity |
|-------|----------|------------------|
| Presence | Does plan have clear value statement in user story format? | CRITICAL if missing |
| Clarity | Is "So that" outcome measurable or verifiable? | HIGH if vague |
| Alignment | Does value support Master Product Objective? | CRITICAL if drift |
| Directness | Is value delivered directly, not deferred? | HIGH if deferred |

### Plan Completeness & Constraints

| Check | Question | Finding Severity |
|-------|----------|------------------|
| Scope | Are boundaries clearly defined? | MEDIUM |
| Dependencies | Are dependencies identified and sequenced? | MEDIUM |
| No Code | Does plan avoid prescriptive code? Focus on WHAT/WHY? | LOW |
| Architecture | Does plan respect architectural constraints? | HIGH |
| Open Questions | Are all `OPEN QUESTION` items resolved? | CRITICAL if unresolved |

---

## Severity Definitions & Finding Format

| Severity | Response |
|----------|----------|
| **CRITICAL** | Block until fixed (Auth bypass, SQLi, missing value statement) |
| **HIGH** | Fix before merge (Missing validation, N+1 queries, swallowed errors) |
| **MEDIUM** | Fix in current cycle (Deep nesting, `any` types) |
| **LOW** | Track for later (Style issues, TODOs) |

**Finding Format:**
```markdown
### [ID]: [Brief Title]
- **Severity**: CRITICAL / HIGH / MEDIUM / LOW
- **Status**: OPEN / ADDRESSED / RESOLVED / DEFERRED
- **Location**: [file:line or plan section]
- **Description**: [What is the issue?]
- **Impact**: [Why does this matter?]
- **Recommendation**: [How to fix?]

```

---

## Agent Responsibilities & The Triad Handoff

### For 06-Critic and 08-Code Reviewer

Before concluding your turn and handing off, you MUST align the Triad using **Native MCP Tools**:

1. **The Artifact (`agent-output/`)**: Write your full review to `agent-output/critiques/NNN-critique.md` (Critic) or `agent-output/code-review/NNN-review.md` (Code Reviewer) using `write_file`.
2. **The Execution (Planka Board)**:
* Use `create_task_list` for your domain ("Plan Review & Critique" or "Code Review").
* Use `create_task` for specific blocking findings that need fixing.
* Use `add_label_to_card` for the visual verdict (e.g., `Plan Approved`, `Revision Required`, `Code Review Passed`).
* Use `add_comment` to state the final verdict, linking to your markdown artifact and Obsidian node.


3. **The Memory (Obsidian Graph)**:
* Use `obsidian/write_note` to create your `WF-<concrete-id>` node.
* Follow the **10-Line Rule** (`type`, `parent: "[[WF-...]]"`, and max 3-bullet summary).
* Patch the calling agent's node to link to yours.



**Final Chat Message**:
Always conclude your turn in the chat with:

> *"Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC)."*

