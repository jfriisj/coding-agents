---
name: code-review-standards
description: Code review severity definitions, finding formats, and document templates. Integrates strictly with Native Workflow Memory. Use this skill when defining review criteria, understanding severity levels, or creating the final code review artifact.
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

Create your review in `agent-output/code-review/NNN-review.md` matching the plan name. You MUST include the standard YAML frontmatter.

```markdown
---
ID: [NNN]
Type: CodeReview
Status: [Active / Closed]
Epic: "workflows/WF-E<epic-number>.md"
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

## 4. Document & Workflow Sync (The Handoff Protocol)

Before concluding your turn and handing off to the Implementer or QA, you MUST align the workflow using **standard workspace file tools**:

1. **The Artifact (`agent-output/`)**: 
   * Save the filled document template to `agent-output/code-review/` using `edit/createFile` or `edit/editFiles`.
   * If a review document reaches a terminal state (e.g., `Approved` or `Rejected`), use the close script via terminal: `sh .github/scripts/close_document.sh <path-to-your-file.md> "Approved"`.

2. **The Memory (Workflow Graph)**:
   * Use native file tools to create or update your `WF-<concrete-id>-<slug>.md` node.
   * Strictly follow the **10-Line Rule** (frontmatter `type: CodeReview`, `parent: "workflows/WF-...md"`, and a max 3-bullet summary).
   * Patch the calling agent's node to append a standard markdown link back to your new node.

**Final Chat Message**:
Always conclude your turn in the chat with:

> *"Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md"*
