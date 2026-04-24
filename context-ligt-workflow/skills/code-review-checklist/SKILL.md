---
name: code-review-checklist
description: Structured code review criteria for pre-implementation (Critic) and post-implementation (Security/Code Reviewer). Exclusively uses token-efficient tools (Analyzer, File tools, Search) to replace legacy bash scripts. Integrates strictly with Native Workflow Memory. Use this skill when performing code reviews, whether reviewing plans (Critic) or implemented code (Code Reviewer/Security). This skill defines the specific checks to perform, the severity levels, and the exact tools to use for each check, ensuring a consistent and efficient review process across all agents.
---

# Code Review Checklist

Systematic review criteria for evaluating code and plans. Use this skill when:
- Critic reviews plans before implementation
- Code Reviewer evaluates implemented features
- Security agent conducts code audits
- Architect reviews architectural compliance

## 1. Document & Workflow Sync (Review & Critique)

Every review verdict must be synchronized across two structural layers:
1. **Execution Artifact (`agent-output/`)**: The detailed critique or code-review document.
2. **Workflow Graph (`workflows/`)**: The lightweight `WF-*` node (10-Line Rule) linking your review to the Plan or Implementation using standard native markdown links.

---

## 2. Tooling Contract (Native Commands & Progressive Disclosure)

**CRITICAL RULE**: You MUST use standard terminal commands and native file tools for all code analysis. 

To determine the exact terminal commands needed for the language you are reviewing, use `read/readFile` to load the appropriate reference guide:

> **Read**: `.github/skills/code-review-checklist/references/python-linting.md` (For Python / Ruff / Vulture)
> **Read**: `.github/skills/code-review-checklist/references/typescript-linting.md` (For TS/JS / ESLint)

*(If a specific guide does not exist for the language, inspect the `package.json`, `Makefile`, or equivalent configuration file to determine the project's standard linting commands).*

### Fast Native Checks (Without Terminal)
For structural analysis without running heavy tools, use native `search` and file tools:
- **`search/listDirectory`**: Assess project structure and find excessively large directories without reading files.
- **Native `search` tool**: Use regex queries across the workspace to instantly detect anti-patterns (e.g., searching for `console.log` or deep nesting).

---

## 3. Post-Implementation Review Checks (Regex & MCP)

When reviewing code, run these specific checks using your tools.

### Check 1: Complexity & Code Smells
*Instead of bash scripts, use these heuristics:*
- **High Coupling**: Use `search` with regex `^import\s` or `^from .+ import\s` to find files with massive import blocks.
- **Deep Nesting**: Use `search` with regex `^(\s{16}|\t{4})` to find 4+ levels of indentation.
- **God Objects**: Check file sizes or visually inspect line counts when reading files. Threshold: > 500 lines.

### Check 2: Pre-Review Safety Checks
*Use the native `search` tool with these exact regex patterns (enable regex mode):*

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

## 4. Pre-Implementation Review (Critic)

When reviewing a Plan (Markdown), read the document using `read/readFile` and assess:

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

## 5. Severity Definitions & Finding Format

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

## 6. Document & Workflow Sync (The Handoff Protocol)

### For `02e-Critic` and `03c-CodeReviewer`

Before concluding your turn and handing off, you MUST align the workflow using **standard workspace file tools**:

1. **The Artifact (`agent-output/`)**: 
   * Write your full review to `agent-output/critiques/NNN-critique.md` (Critic) or `agent-output/code-review/NNN-review.md` (Code Reviewer) using `edit/createFile` or `edit/editFiles`.
   * If a review document reaches a terminal state (e.g., `Resolved`), use the close script via terminal: `sh .github/scripts/close_document.sh <path-to-your-file.md> "Resolved"`.

2. **The Memory (Workflow Graph)**:
   * Use native file tools to create or update your `WF-<concrete-id>-<slug>.md` node.
   * Follow the **10-Line Rule** (frontmatter `type`, `parent: "workflows/WF-...md"`, and max 3-bullet summary).
   * Patch the calling agent's node to append a standard markdown link back to your new node.

**Final Chat Message**:
Always conclude your turn in the chat with:

> *"Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md"*