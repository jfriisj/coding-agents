---
name: code-review-standards
description: Code review severity definitions, finding formats, and document templates. Integrates strictly with Obsidian/Planka via Native MCP for handoffs. Use this skill when defining review criteria, understanding severity levels, or creating the final code review artifact.
---

# Code Review Standards

Systematic approach to documenting code reviews. Use this skill when defining review criteria, understanding severity levels, or creating the final code review artifact.

*(Note: For the actual items to check, load the `code-review-checklist` skill).*

---

## 1. Severity Levels & Rejection Criteria

| Severity | Definition | Action |
|----------|------------|--------|
| **CRITICAL** | Security vulnerability, data loss risk, architectural violation, missing TDD compliance | REJECT - must fix |
| **HIGH** | Anti-pattern, significant maintainability issue, missing tests | REJECT - must fix |
| **MEDIUM** | Code smell, minor design issue, unclear code | Fix recommended, may approve with comments |
| **LOW** | Style preference, minor optimization opportunity | Note for future, approve |
| **INFO** | Observation, suggestion for improvement | FYI only |

### When to Reject
- Any CRITICAL finding → REJECT
- Any HIGH finding → REJECT
- 3+ MEDIUM findings in same file → Consider REJECT

---

## 2. Finding Format

When documenting findings in your review, use this exact format:

```markdown
**[SEVERITY] [Category]**: [Brief title]
- **Location**: `path/to/file.py:L42-L55`
- **Issue**: [What's wrong and why it matters]
- **Recommendation**: [Specific fix suggestion]

```

---

## 3. Code Review Document Template

Create your review in `agent-output/code-review/NNN-review.md` matching the plan name. You MUST include the Dataview YAML frontmatter.

```markdown
---
ID: [NNN]
Type: CodeReview
Status: [Active / Closed]
Epic: "[[WF-E<epic-number>]]"
Planka-Card: "CARD_ID_NUMERIC"
---

# Code Review: [Plan Name]

**Plan Reference**: `agent-output/planning/[plan-name].md`
**Implementation Reference**: `agent-output/implementation/[plan-name]-implementation.md`
**Date**: [date]
**Reviewer**: Code Reviewer

## Changelog
| Date | Agent Handoff | Request | Summary |
|------|---------------|---------|---------|
| YYYY-MM-DD | [Who handed off] | [What was requested] | [Brief summary] |

## Architecture Alignment
**System Architecture Reference**: `agent-output/architecture/system-architecture.md`
**Alignment Status**: ALIGNED / MINOR_DEVIATIONS / MAJOR_DEVIATIONS

[Assessment of how implementation aligns with architectural decisions]

## TDD Compliance Check
**TDD Table Present in Implementation**: Yes / No
**All Rows Complete (Test-First)**: Yes / No
**Concerns**: [Any issues with TDD compliance]

## Findings

### Critical
[List of critical findings, or "None"]

### High
[List of high findings, or "None"]

### Medium/Low
[List of medium/low findings, or "None"]

## Verdict
**Status**: APPROVED / APPROVED_WITH_COMMENTS / REJECTED
**Rationale**: [Brief explanation]

## Required Actions
[If rejected: specific list of fixes required]

## Next Steps
[Handoff to Implementer for fixes / Handoff to QA for testing]

```

---

## 4. Agent Responsibilities & The Triad Handoff

Before concluding your turn and handing off to the Implementer or QA, you MUST align the Triad using **Native MCP Tools**:

1. **The Artifact (`agent-output/`)**: Save the filled document template to `agent-output/code-review/`.
2. **The Execution (Planka Board)**:
* Use `create_task_list` (if missing) for "Code Review".
* Use `create_task` for specific blocking findings that need fixing.
* Use `add_label_to_card` for the visual verdict (e.g., `Code Review Passed`, `Code Review Failed`).
* Use `add_comment` to state the final verdict, linking to your markdown artifact and Obsidian node.


3. **The Memory (Obsidian Graph)**:
* Use `obsidian/write_note` to create your `WF-<concrete-id>` node.
* Strictly follow the **10-Line Rule** (`type: CodeReview`, `parent: "[[WF-...]]"`, and a max 3-bullet summary).
* Patch the calling agent's node to link to yours.



**Final Chat Message**:
Always conclude your turn in the chat with:

> *"Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC)."*
