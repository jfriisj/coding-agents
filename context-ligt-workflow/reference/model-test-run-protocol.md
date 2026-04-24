---
ID: model-test-run-protocol
Type: Reference
Status: Active
---

# Model Test Run Protocol

Use this protocol when you want to verify that agents/models behave as expected end-to-end.

## Goal

Detect behavior drift early and capture enough evidence to reproduce and fix issues quickly.

## 1) Preflight

- Confirm target agent file exists in `.github/agents/`.
- Confirm necessary tools and servers are reachable (e.g., native workspace tools, `github` MCP).
- Define explicit acceptance criteria for the run (what “pass” means).

## 2) Create Run Folder

Create a run folder in:

`agent-output/test-runs/YYYYMMDD-HHMM-[scenario-slug]/`

Inside it, prepare:

- `00-context.md`
- `01-expected-vs-actual.md`
- `02-reproduction-steps.md`
- `03-failure-report.md` (copy from `.github/reference/model-failure-report-template.md`)
- `04-agent-findings-log.md` (one-line summary per agent)
- `evidence/`

## 3) Execute Scenario

Run the scenario with one clear prompt sequence. Keep prompts deterministic.

Minimum checks:

1. Correct agent behavior (stays within role constraints).
2. Correct handoff format: `Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md`
3. Correct artifact updates in `agent-output/`.
4. Correct tool usage (uses standard workspace file tools; no forbidden script-based flow for core workflow operations).

## 4) If Anything Goes Wrong (Capture Immediately)

1. Fill `03-failure-report.md`.
2. Save raw evidence to `evidence/`:
   - `terminal.txt`
   - `problems.txt`
   - `prompt.txt`
   - `response.txt`
3. Record exact reproduction steps in `02-reproduction-steps.md`.
4. Add expected vs actual delta in `01-expected-vs-actual.md`.

## 5) Analysis & Fix Loop

- Link the run folder from the relevant workflow node (`WF-*.md`) using standard markdown links.
- Use the failure report’s “Fix Plan” section to patch the smallest root-cause area.
- Re-run the same scenario after patching.
- Mark the report `Status: Verified` only when acceptance criteria are met.

## 6) Output of a Successful Run

A run is complete when:

- Acceptance criteria are all checked.
- Any failures have a completed report + evidence bundle.
- Re-run passes and regression notes are documented.
