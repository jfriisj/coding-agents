---
name: bdd-gherkin-lifecycle
description: Mandatory protocols for authoring, implementing, and validating Behavior-Driven Development (BDD) Gherkin scenarios. Integrates with Native Workflow Memory. Trigger when writing Acceptance Criteria, designing test strategies, or conducting UAT.
---

# BDD & Gherkin Lifecycle Protocols

Behavior-Driven Development (BDD) is the primary bridge between business requirements and verifiable code. This skill defines how Gherkin scenarios are authored, implemented, and validated across the agentic pipeline.

## 1. Authoring (For `01b-Requirements` / Product Owners)
When translating Epic requirements into Acceptance Criteria (AC), you MUST use strict Gherkin syntax.

* **Rule 1: One Scenario per AC.** Every Acceptance Criterion must have exactly one corresponding Gherkin Scenario.
* **Rule 2: Declarative, not Imperative.** Describe the *business behavior*, not the UI clicks.
  * *Bad:* `When the user clicks the blue submit button...`
  * *Good:* `When the user submits a valid translation request...`
* **Rule 3: Strict Syntax.** Use `Given`, `When`, `Then`, `And`, `But`.

**Format Template:**
```gherkin
**AC1: [Name of Acceptance Criterion]**
Scenario: [Clear description of the scenario]
  Given [Initial state or context]
  And [Additional context]
  When [Action taken by user or system trigger]
  Then [Observable business outcome]
  And [Additional observable outcome]
```

## 2. Implementation & Test Strategy (For `04a-QA` & `03a-Implementer`)
When the QA agent designs a test strategy, or the Implementer writes the tests, they MUST map the business Gherkin directly into the code.

If using a native framework (like standard `pytest` or `Jest`) instead of a dedicated BDD runner:
* You MUST copy the exact Gherkin text into the test function docstring or as inline comments.
* The test function name MUST reference the AC number.

**Python Example:**
```python
def test_ac1_orchestrator_routes_to_translation(kafka_harness):
    """
    Scenario: Orchestrator successfully routes ASR output to Translation
      Given the pipeline is active
      When the ASR service publishes a TextRecognizedEvent
      Then the Orchestrator MUST emit a routing command for Translation
    """
    # Given the pipeline is active
    harness.setup_pipeline()
    
    # When the ASR service publishes a TextRecognizedEvent
    harness.publish_asr_event(text="Hello world")
    
    # Then the Orchestrator MUST emit a routing command for Translation
    event = harness.await_orchestrator_command()
    assert event.target_service == "translation"
```

## 3. Validation & Reporting (For `04a-QA`, `03b-TestRunner`, & `04b-UAT`)
To allow the UAT agent to cleanly approve the release, the QA agent (or TestRunner) MUST output a strict **BDD Traceability Matrix** in the `agent-output/qa/` report.

**The matrix MUST use this format:**
| AC / Scenario | Test Implementation | Status |
|---------------|---------------------|--------|
| AC1: Orchestrator routes to Translation | `test_ac1_orchestrator_routes_to_translation` | ✅ PASS |
| AC2: Gateway rejects invalid payloads | `test_ac2_gateway_rejection` | ❌ FAIL |

**UAT Validation Rule:** The `04b-UAT` agent will read the original Requirements document, extract the Gherkin scenarios, and compare them against the QA Traceability Matrix. If all scenarios map 1:1 and show `✅ PASS`, UAT approves the epic. If any are missing or failed, UAT rejects it.

---

## 4. Document & Workflow Sync (The Handoff Protocol)

When participating in the BDD lifecycle, you must align the workflow using **standard workspace file tools**:

1. **The Artifact (`agent-output/`)**: 
   * Ensure your Gherkin ACs, test matrices, or UAT verdicts are saved using `edit/editFiles` or `edit/createFile`. 
   * If your document reaches a terminal state (e.g., UAT Approved), use the close script via terminal: `sh .github/scripts/close_document.sh <path-to-your-file.md> "Approved"`.

2. **The Memory (Workflow Graph)**: 
   * Use native file tools to create or update your `WF-<concrete-id>-<slug>.md` node. 
   * Strictly follow the 10-Line Rule (frontmatter `type`, `parent`, max 3-bullet summary, and standard Markdown Artifact links).

**Final Chat Message**:
Always conclude your turn with:
> *"Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md"*
