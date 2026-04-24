# Model Failure Report Template

```yaml
---
ID: [YYYYMMDD-HHMM-scenario]
Type: ModelFailureReport
Date: [YYYY-MM-DD]
Agent: [01a-Roadmap / 02a-Planner / ...]
Model: [e.g., GPT-5.4 mini (copilot)]
Scenario: [short name]
Severity: [BLOCKER/HIGH/MEDIUM/LOW]
Status: [Open/In Analysis/Fixed/Verified]
WorkflowNode: "agent-output/workflows/WF-...md"
---
```

## 1) Expected Behavior

- [What should have happened]

## 2) Actual Behavior

- [What happened instead]

## 3) Reproduction Steps

1. [Exact step]
2. [Exact step]
3. [Exact step]

## 4) Prompt & Context

- Prompt used: [paste exact prompt]
- Active Workflow Node: [Link to the WF- node being processed]
- File/context state: [active file, selected text, branch]

## 5) Evidence Links

- Run folder: `agent-output/test-runs/[Run-ID]/`
- Terminal output: `agent-output/test-runs/[Run-ID]/evidence/terminal.txt`
- Problems output: `agent-output/test-runs/[Run-ID]/evidence/problems.txt`
- Relevant artifacts: [paths to relevant agent-output docs]

## 6) Root Cause Hypotheses (if RCA incomplete)

- **Verified**: [facts]
- **Hypothesis**: [what you suspect]
- **Missing telemetry/evidence**: [what is needed]

## 7) Fix Plan

- [Target file/agent/skill]
- [Minimal patch strategy]
- [Validation steps]

## 8) Verification

- [ ] Reproduced before fix
- [ ] Patch applied
- [ ] Re-run scenario passes
- [ ] No regressions detected

## 9) Closure Note

- Final result: [What was the outcome?]
- Follow-up actions: [e.g., Update to 05c-ProcessImprovement needed?]
