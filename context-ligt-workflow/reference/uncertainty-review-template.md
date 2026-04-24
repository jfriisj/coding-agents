---
ID: uncertainty-aware-issue-review
Type: Template
Status: Active
---

# Uncertainty-Aware Issue Review Template

Use this template when you cannot prove a single root cause due to missing telemetry, non-determinism, or too many interacting factors.

## 0) Context
**Workflow Node**: [Link to the active WF-*.md node]
**Issue/Scenario**: [Brief description of the problem]

## 1) What we can prove
**Verified facts**:
- [fact 1]
- [fact 2]

**Reproduction / evidence**:
- Steps attempted: [What was tried?]
- Environments: [Local, Docker, CI, etc.]
- Outputs/logs captured: [Links or brief snippets]

## 2) What we *suspect* (explicitly labeled)
**High-confidence inference** (supported by evidence, not fully proven):
- [inference]

**Hypotheses** (plausible, not proven):
- **Hypothesis 1:** [Description]
  - Confidence: High | Med | Low
  - Fastest disconfirming test: [How can we quickly prove this wrong?]
  - Missing telemetry that would make this provable: [What logs/metrics are we missing?]

## 3) System weaknesses that allow the behavior (improvement list)
List weaknesses in architecture, code structure, or process flow that make the system susceptible.

For each weakness, capture:
- **Weakness**: [Description]
- **Mechanism**: [Why it enables the observed behavior]
- **Impact**: [What is the consequence?]
- **Hardening Direction**: [Suggested direction, NOT an implementation plan]
- **Detection**: [How we would detect/confirm this weakness next time]

## 4) Observability gaps (telemetry needed)
Specify additional markers needed to isolate the issue next time.

For each telemetry item, capture:
- **Signal type**: log | metric | trace | event
- **Location**: [Component/module + key codepath]
- **Fields**: [Correlation IDs, redacted inputs/outputs, timings, retries, error class, state transitions]
- **Level**: **Normal** (always-on) vs **Debug** (opt-in)
- **Volume/sampling expectation**: [High/Low volume? Sampled?]
- **Privacy/PII notes**: [Any sensitive data concerns?]

*Normal vs Debug quick criteria:*
- **Normal**: always-on, low-volume, structured, actionable for triage/alerts, safe-by-default (no secrets/PII), stable fields.
- **Debug**: opt-in (flag/config), high-volume or high-cardinality, safe to disable, short windows; still respect privacy.

*Minimum viable incident telemetry set (recommended default):*
- Correlation IDs propagated across boundaries
- Key state transitions (start/success/fail)
- Dependency boundary signals (duration, retries/attempts, result)
- Error taxonomy (typed category/class) without leaking secrets

## 5) Fastest next steps to reduce uncertainty
Smallest set of investigations/experiments that most quickly collapse uncertainty.
- [Next step 1]
- [Next step 2]
