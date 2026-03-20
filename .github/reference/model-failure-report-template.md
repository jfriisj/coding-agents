# Model Failure Report Template

```yaml
Run-ID: [YYYYMMDD-HHMM-scenario]
Date: [YYYY-MM-DD]
Agent: [01-Roadmap / 02-Planner / ...]
Model: [e.g., GPT-5.3-Codex]
Scenario: [short name]
Severity: [BLOCKER/HIGH/MEDIUM/LOW]
Status: [Open/In Analysis/Fixed/Verified]
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
- File/context state: [active file, selected text, branch]

## 5) Evidence Links

- Run folder: `agent-output/test-runs/[Run-ID]/`
- Terminal output: `agent-output/test-runs/[Run-ID]/evidence/terminal.txt`
- Problems output: `agent-output/test-runs/[Run-ID]/evidence/problems.txt`
- Relevant artifacts: [paths]

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

- Final result:
- Follow-up actions:
