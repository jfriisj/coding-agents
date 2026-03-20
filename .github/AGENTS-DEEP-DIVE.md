# VS Code Agents - Deep Dive Documentation

> This comprehensive guide covers advanced usage patterns, agent collaboration, Obsidian graph integration, Planka Agile tracking, and the design philosophy behind this multi-agent workflow.
>
> **New users**: Start with [USING-AGENTS.md](USING-AGENTS.md) for quick setup.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Agent Collaboration Patterns](#agent-collaboration-patterns)
3. [The Document-Driven Workflow](#the-document-driven-workflow)
4. [Obsidian Graph Integration](#obsidian-graph-integration)
5. [Planka Agile Integration](#planka-agile-integration)
6. [Agent Deep Dives](#agent-deep-dives)
7. [Customization Guide](#customization-guide)
8. [Troubleshooting & FAQ](#troubleshooting--faq)
9. [Agent Orchestration Playbook](#agent-orchestration-playbook)

---

## Design Philosophy

### Why Multiple Specialized Agents?

A single general-purpose AI tries to do everything—plan, code, test, review—often poorly. By splitting responsibilities:

1. **Each agent has clear constraints**: Planner can't write code, Implementer can't redesign.
2. **Quality gates are built in**: Critic reviews before implementation, Security audits before production.
3. **Handoffs create checkpoints**: Work is documented at each stage.
4. **Specialization improves quality**: A security-focused agent catches vulnerabilities a general agent misses.

### Native MCP First (Zero Terminal Overhead)

To ensure high reliability, extreme token efficiency, and no annoying manual terminal approvals, this system is strictly designed around **Native MCP Tools**:
* **`planka`**: Manages Agile execution (cards, tasks, status labels).
* **`obsidian`**: Manages the relational memory graph via lightweight `WF-` nodes.
* **`filesystem`**: Handles all file reading, writing, and directory creation (e.g., `read_text_file`, `move_file`).
* **`analyzer`**: Replaces fragile bash scripts for linting and code complexity checks (RUFF, VULTURE).

**Rule**: *Terminal commands and external Python/Bash scripts (like `sync_roadmap_epics.py` or `planka_ops.py`) are strictly forbidden for core workflow operations.*

### The Separation of Concerns

| Concern | Agent(s) | Key Constraint |
|---------|----------|----------------|
| **Vision** | 01-Roadmap | Outcomes, not implementation |
| **Planning** | 02-Planner | WHAT/WHY, never HOW (no code) |
| **Research** | 03-Analyst | Analysis only, no fixes |
| **Design** | 04-Architect | Patterns, not implementation details |
| **Quality** | 06-Critic | Reviews, doesn't modify artifacts |
| **Security** | 05-Security | Findings, doesn't implement remediations |
| **Implementation** | 07-Implementer | Follows plans, doesn't redesign |
| **Code Quality** | 08-Code Reviewer | Quality gate before QA, can reject |
| **Testing** | 09-QA | Test strategy, not business value |
| **Value** | 10-UAT | Business value, not technical quality |
| **Release** | 11-DevOps | Requires explicit user approval |

### Document-First Development

Every agent produces **Markdown documents** in `agent-output/`:

```text
agent-output/
├── planning/           # Plans with WHAT/WHY
├── analysis/           # Research findings
├── architecture/       # ADRs and design decisions
├── critiques/          # Plan reviews
├── security/           # Security assessments
├── code-review/        # Post-implementation reviews
├── qa/                 # Test strategies
├── uat/                # Value validation
├── retrospectives/     # Lessons learned
└── releases/           # Release documentation

```

**Why documents?**

* **Auditability**: See what was decided and why
* **Handoff context**: Next agent reads the artifacts
* **Memory anchors**: Obsidian stores graph relations to these documents
* **Version control**: Track evolution of decisions

---

## Agent Collaboration Patterns

### Pattern 1: The Planning Pipeline

```text
┌──────────┐    ┌─────────┐    ┌───────────┐    ┌──────────┐
│ Roadmap  │───▶│ Planner │───▶│ Analyst/  │───▶│  Critic  │
│ (vision) │    │ (plan)  │    │ Architect │    │ (review) │
└──────────┘    └─────────┘    │ /Security │    └──────────┘
                               └───────────┘           │
                                                       ▼
                                               ┌──────────────┐
                                               │ Implementer  │
                                               │ (approved)   │
                                               └──────────────┘

```

**When to use**: Starting a new feature from scratch.

**Example flow**:

1. Select **Roadmap** → Define epic: "User authentication system"
2. Select **Planner** → Create plan from epic → `agent-output/planning/001-auth-plan.md`
3. Select **Analyst** → Research OAuth providers → `agent-output/analysis/001-auth-analysis.md`
4. Select **Architect** → Review design fit → updates plan or creates ADR
5. Select **Security** → Threat model → `agent-output/security/001-auth-security.md`
6. Select **Critic** → Final review → `agent-output/critiques/001-auth-plan-critique.md`
7. Select **Implementer** → Code when approved

### Pattern 2: The Implementation Loop

```text
┌─────────────┐    ┌─────────────┐    ┌──────┐    ┌──────┐    ┌────────┐
│ Implementer │───▶│ Code        │───▶│  QA  │───▶│ UAT  │───▶│ DevOps │
│   (code)    │    │ Reviewer    │    │(test)│    │(value)│    │(release)│
└─────────────┘    └─────────────┘    └──────┘    └──────┘    └────────┘
       ▲               │               │           │
       └───────────────┴───────────────┴───────────┘
              (fix issues)

```

**When to use**: Plan is approved, coding phase.

**Example flow**:

1. Select **Implementer** → Implement plan → code changes + tests
2. Select **Code Reviewer** → Verify code quality → `agent-output/code-review/001-auth-code-review.md`
3. If quality issues: back to Implementer
4. Select **QA** → Verify coverage → `agent-output/qa/001-auth-qa.md`
5. If gaps: back to Implementer
6. Select **UAT** → Validate value → `agent-output/uat/001-auth-uat.md`
7. If gaps: back to Implementer
8. Select **DevOps** → Release → requires user approval

### Pattern 3: The Investigation Branch

```text
┌─────────────┐    ┌─────────┐    ┌─────────────┐
│ Any Agent   │───▶│ Analyst │───▶│ Back to     │
│ hits unknown│    │(research)    │ calling agent
└─────────────┘    └─────────┘    └─────────────┘

```

**When to use**: Hit technical uncertainty during any phase.

**Example flow**:

1. With **Planner** selected, planning auth but unsure about JWT vs session tokens
2. Select **Analyst** → investigates → `agent-output/analysis/002-jwt-vs-sessions.md`
3. Findings go back to Planner to inform the plan

**Incident/bug variant (when evidence is incomplete)**:

* If logs/telemetry are insufficient to prove a single root cause, Analyst switches to an uncertainty-aware format. The Analyst MUST trigger a "Hard Pivot": Stop digging, pivot to system weaknesses, and define required telemetry (normal vs debug). This procedure is strictly governed by the embedded `analysis-methodology` skill.

### Pattern 4: The Security Gate

```text
┌─────────────┐    ┌──────────┐    ┌─────────────┐
│ Any Phase   │───▶│ Security │───▶│ Continue or │
│ (sensitive) │    │ (audit)  │    │ Block       │
└─────────────┘    └──────────┘    └─────────────┘

```

**When to use**: Feature touches auth, sensitive data, external interfaces.

**Security can be invoked**:

* During planning (threat model)
* During implementation (code audit)
* Before production (final gate)

### Pattern 5: The Retrospective Cycle

```text
┌──────────┐    ┌───────────────┐    ┌────────────────────┐
│ Delivery │───▶│ Retrospective │───▶│ Process Improvement│
│ complete │    │ (lessons)     │    │ (evolve agents)    │
└──────────┘    └───────────────┘    └────────────────────┘

```

**When to use**: After feature delivery, to improve the workflow.

**Example flow**:

1. Feature shipped
2. Select **Retrospective** → captures what went well/poorly
3. Select **Process Improvement** → updates agent instructions if patterns emerge

---


## The Document-Driven Workflow

### Document Naming Convention

```text
NNN-feature-name-type.md

```

* **NNN**: Sequential number (001, 002, ...)
* **feature-name**: Descriptive name (auth-system, api-refactor)
* **type**: Document type (plan, analysis, critique, security, etc.)

**Examples**:

* `001-user-auth-plan.md`
* `001-user-auth-analysis.md`
* `001-user-auth-plan-critique.md`
* `001-user-auth-code-audit.md`

### Document Structure Standards

Every document should have:

1. **Changelog** (at top): Track revisions
2. **Value Statement** (plans): "As a [user] I want [X] so that [Y]"
3. **Clear Sections**: Standardized headings
4. **Status/Verdict**: Current state (APPROVED, BLOCKED, etc.)
5. **References**: Links to related documents

### Document Status Tracking

All agents track and update document status fields in the YAML frontmatter. This provides at-a-glance visibility into document state:

| Status | Meaning |
| --- | --- |
| `Draft` | Initial creation, not yet reviewed |
| `In Progress` | Actively being worked on |
| `Pending Review` | Ready for next agent's review |
| `Approved` | Passed review gate |
| `Blocked` | Cannot proceed until issues resolved |
| `Committed` | Changes committed to git (awaiting release) |
| `Released` | Successfully pushed/published to production |

Agents update status when:

* **Implementer**: Marks plan "In Progress" when starting implementation
* **Critic/QA/UAT**: Updates to "Approved" or "Blocked" after review
* **DevOps**: Updates to "Committed" or "Released" during deployment phases

### Document Lifecycle and Closure

Completed documents move to `closed/` subfolders to keep active work visible. **Agents MUST use the native `filesystem` MCP tools (`move_file`, `create_directory`) for this. Terminal commands like `mkdir` and `mv` are strictly forbidden.**

```text
agent-output/
├── planning/
│   ├── 085-active-feature.md      ← currently active
│   └── closed/
│       ├── 080-completed.md       ← archived after commit
│       └── 081-completed.md
├── qa/
│   └── closed/
└── ...

```

**Key concepts:**

| Concept | Description |
| --- | --- |
| **Unified numbering** | All documents in a work chain share the same ID (analysis 080 → plan 080 → qa 080) |
| **`.next-id` file** | Global counter at `agent-output/.next-id`, read and incremented via `filesystem` tools by originating agents |
| **Terminal statuses** | `Committed`, `Released`, `Abandoned`, `Deferred`, `Superseded` trigger closure |
| **Closure trigger** | Handled natively by agents when terminal statuses are reached |
| **Orphan detection** | Agents self-check on start using `filesystem/list_directory` |

See `document-lifecycle` skill for full details.

### Open Question Gate

Plans may contain `OPEN QUESTION` items that require resolution before implementation.

**Question lifecycle:**

1. Planner marks unresolved questions as `OPEN QUESTION: [description]`
2. When resolved, Planner updates to `OPEN QUESTION [RESOLVED]: [description]` or `[CLOSED]`
3. Before handoff, Planner warns user if unresolved questions remain

**Implementer behavior:**

* Scans plans for unresolved `OPEN QUESTION` items
* If any exist, **halts and strongly recommends resolution** before proceeding
* Requires explicit user acknowledgment to proceed despite warning
* Documents user's decision in implementation doc

> [!CAUTION]
> Proceeding with unresolved open questions risks building on flawed assumptions. Always resolve or explicitly acknowledge before implementation.

### Handoff Protocol (The Triad Bridge)

When handing off between agents, we rely on a strict final chat message that bridges the Obsidian Memory Graph and the Planka Execution Board.

Every agent MUST end their turn with this exact format:

```markdown
Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC).

```

---

### Model Test Runs and Failure Forensics

Use a repeatable run protocol whenever you want to validate end-to-end model/agent behavior and preserve failures for fast debugging.

- Run protocol: [.github/reference/model-test-run-protocol.md](.github/reference/model-test-run-protocol.md)
- Failure template: [.github/reference/model-failure-report-template.md](.github/reference/model-failure-report-template.md)
- Artifact location: `agent-output/test-runs/`

Minimum expectation:

1. Define acceptance criteria before execution.
2. Capture expected vs actual behavior.
3. Save prompts/responses/terminal evidence on failure.
4. Re-run after fixes and mark verified.

---


## Obsidian Graph Integration

### Replacing the External Memory Server

Instead of relying on an external, opaque Memory MCP server that dumps massive JSON blobs into the context window, this workflow uses **Obsidian** as its native long-term memory graph.

**Why Obsidian is superior for Agent Memory**:

* **Token Efficiency**: Agents load tiny "summary nodes" instead of full document histories.
* **Relational Graph**: YAML frontmatter defines exact relationships (Epic -> Plan -> Implementation).
* **Auditability**: You can visually open your Obsidian vault and see exactly how decisions map to one another.
* **Tools**: Relies purely on the native `obsidian` toolset.

### The "Summary Node" Pattern (The 10-Line Rule)

To prevent context window bloat, agents do not dump massive contents into Obsidian. They create lightweight `WF-<concrete-id>` (Workflow) nodes. These nodes act as **pointers and semantic edges**.

**The 10-Line Rule for `WF-` Notes**:

1. **Frontmatter**: Graph relations (Type, Parent links, and Planka Card ID). *Note: Status and Owner are tracked in Planka, not Obsidian.*
2. **TL;DR**: Maximum 3 bullet points summarizing the core decision, constraint, or verdict.
3. **Artifact Link**: A direct wikilink to the full markdown file in `agent-output/`.

*Example of a Workflow Node (`workflows/WF-002-Auth-Plan.md`):*

```markdown
---
type: Plan
parent: "[[WF-001-Auth-Epic]]"
Planka-Card: "CARD_ID_NUMERIC"
---
### Summary
* Decided to use JWT tokens over session cookies.
* Defined 4 implementation milestones.
* See artifact for exact file paths.

**Artifact**: [[agent-output/planning/002-auth-plan.md]]

```

**Validation Constraint**: Agents MUST use native `obsidian` tools (like `write_note`, `read_note`, `patch_note`) for all vault operations. Terminal validation scripts (like `verify-obsidian-graph.mjs`) are strictly forbidden to save token overhead.

### Retrieval and Storage Patterns

**Retrieval (Lazy Loading)**:
When an agent starts a task or receives a handoff, it should NOT search the entire vault. It should:

1. Read the provided `[[WF-...]]` note using `read_note`.
2. Understand the context from the bullet points and frontmatter.
3. Follow the `parent:` link if broader strategic context is needed.
4. Only read the full `agent-output/` artifact if deep implementation details are strictly necessary.

**Storage**:
Agents update the graph when:

* Completing a task or phase.
* Making a significant decision.
* Handing off to another agent.

They use `patch_note` to update the summary bullet, or link to a new downstream node.

### Memory Enables Agent Collaboration

Without the Obsidian graph, each agent session starts fresh. With it:

1. **Analyst** creates an analysis node (`WF-003`) linked to the plan.
2. **Planner** reads `WF-003` to instantly understand the POC results.
3. **Security** links their audit node to the plan, blocking it if necessary.
4. **Implementer** retrieves constraints from the Planner's node before coding.

Memory is the connective tissue that makes multi-agent workflows coherent.

---

## Planka Agile Integration

While Obsidian acts as the relational memory graph and `agent-output/` serves as the authoritative source of truth for documents, **Planka** is the execution engine. It provides the Agile Kanban view for tracking task progression, labels, and day-to-day execution status.

### The Triad of Truth

1. **Markdown (`agent-output/`)**: *What* we are building and *Why* (Full details).
2. **Obsidian Graph (`workflows/`)**: *How* decisions relate to each other (Memory).
3. **Planka Board**: *Who* is doing what, and *Where* it is in the pipeline. Execution is driven by **Native MCP Tools** exclusively.

### Agent Roles in Planka

Agents use the `planka-workflow` skill to keep the board synchronized using **100% Native MCP Tools** (Python/CLI scripts are strictly forbidden):

* **01-Roadmap**: The owner of the Planka board. Uses native tools (`list_projects`, `get_board`, `create_card`, `update_card`) to iteratively reconcile `product-roadmap.md` with Planka, ensuring every Epic has a corresponding card, correct release/priority labels, and lifecycle columns (`Planned`, `In Progress`, `Delivered`).
* **02-Planner**: Reads the Epic card and uses native MCP tools (`create_task_list`, `create_task`) to translate plan milestones into actionable Tasks on the card. Appends handoff comments linking back to Obsidian.
* **03-Analyst**: Creates an "Analysis & Spikes" Task List via MCP tools and leaves a comment with findings when research is done.
* **04-Architect**: Creates an "Architecture & Design" Task List via MCP tools for design constraints and leaves an Approved/Rejected verdict comment.
* **05-Security**: Tracks required controls and vulnerabilities via MCP tasks.
* **06-Critic & 08-Code Reviewer**: Manages visual labels (e.g., `Plan Approved`, `Code Review Passed`) via `add_label_to_card` and appends their review link.
* **07-Implementer**: Marks tasks as completed (`update_task`) and uses the stopwatch (`update_card`) for time tracking.

**Handoff Synergy (The Triad Bridge)**:
When an agent finishes its work, its final chat message MUST point the next agent to the correct `[[WF-ID]]` node and Planka `CARD_ID_NUMERIC`.

---

## Agent Deep Dives

### Roadmap Agent

**Purpose**: Own product vision and ensure features align with business objectives.

**Key Responsibilities**:

* Define and maintain product roadmap
* Translate business needs into epics
* Validate that plans deliver stated value
* Guard the "Master Product Objective"
* Synchronize the master roadmap with the Planka board using native MCP tools (ensuring all Epics have cards and correct statuses).

**When NOT to use**:

* Implementation details
* Technical decisions
* Code review

---

### Planner Agent

**Purpose**: Transform epics into implementation-ready plans.

**Key Responsibilities**:

* Create structured plans with WHAT and WHY
* Define milestones and deliverables
* Identify unknowns requiring investigation
* Coordinate with Analyst, Architect, Security
* Map plan steps to Planka tasks using native MCP tools

**Critical Constraint**: **Never writes code or implementation details**.

Plans answer:

* WHAT are we building?
* WHY are we building it (value statement)?
* WHAT are the acceptance criteria?
* WHAT dependencies exist?

Plans do NOT contain:

* HOW to implement (code snippets, algorithms)
* Test case implementations
* Technical architecture (that's Architect's job)

---

### Analyst Agent

**Purpose**: Deep technical investigation when unknowns arise.

**Key Responsibilities**:

* Research APIs, libraries, patterns
* Conduct experiments and benchmarks
* Analyze root causes
* Document findings with evidence

**Uncertainty-aware investigation (incident/bug work)**:

* If a root cause cannot be proven with available evidence, Analyst must NOT force a narrative.
* Analyst uses an objective hard pivot trigger (timebox/evidence gate) to stop digging and pivot to system weaknesses + required telemetry.
* Telemetry is classified as **normal** vs **debug** (always-on actionable signals vs opt-in verbose signals).

**Key Constraint**: **Investigates but doesn't fix**. Produces analysis docs, not code changes.

---

### Architect Agent

**Purpose**: Maintain system design coherence.

**Key Responsibilities**:

* Create and maintain Architecture Decision Records (ADRs)
* Define patterns and boundaries
* Review plans for architectural fit
* Guide cross-cutting concerns

**Observability is architecture (incident/bug work)**:

* When RCA is uncertain, Architect treats insufficient telemetry as an architectural risk.
* Architect requires explicit normal-vs-debug guidance and recommends a minimum viable incident telemetry baseline.

**Key Constraint**: **Defines WHERE things live, not exact implementation**.

---

### Critic Agent

**Purpose**: Quality gate for plans before implementation.

**Key Responsibilities**:

* Review plans for clarity, completeness, scope
* Check architectural alignment
* Track critique resolution
* Manage visual labels (Approved/Rejected) on Planka cards via native MCP tools

**Key Constraint**: **Reviews but doesn't modify**. Creates critique docs, doesn't edit plans.

**Verdicts**:

* Issues → Recommend revision
* Clean → Approve for implementation

---

### Security Agent

**Purpose**: Comprehensive security assessment and guidance.

**Five-Phase Framework**:

1. **Architectural Security**: Trust boundaries, STRIDE threat modeling, attack surface
2. **Code Security**: OWASP Top 10, language-specific vulnerabilities
3. **Dependency Security**: CVE scanning, supply chain risks
4. **Infrastructure Security**: Headers, TLS, container security
5. **Compliance**: OWASP ASVS, NIST, industry standards

**Key Constraint**: **Identifies and documents, doesn't fix**. Provides remediation guidance.

---

### Implementer Agent

**Purpose**: Write code that implements approved plans.

**Key Responsibilities**:

* Implement plan requirements
* Write and run tests
* Create implementation documentation
* Request clarification when plan is ambiguous
* Update task progress natively in Planka

**Key Constraint**: **Follows the plan**. Doesn't redesign or expand scope.

---

### Code Reviewer Agent

**Purpose**: Quality gate between implementation and QA.

**Key Responsibilities**:

* Review code for architecture alignment (uses Architect's docs as source of truth)
* Check SOLID, DRY, YAGNI, KISS principles
* Verify TDD compliance
* Assess documentation and comments (explaining "why" not "what")

**Key Constraint**: **Reviews but doesn't fix**. Can reject on code quality alone.

**Authority**: CAN REJECT implementation before QA invests testing time.

---

### QA Agent

**Purpose**: Ensure technical quality through testing.

**Key Responsibilities**:

* Design test strategy
* Verify test coverage
* Execute tests
* Identify gaps

**Diagnosability as a QA concern (incident/bug work)**:

* If a root cause cannot be proven, QA expects changes to improve diagnosability (telemetry markers, correlation IDs, structured context).

**Key Constraint**: **Technical quality, not business value** (that's UAT).

---

### UAT Agent

**Purpose**: Validate that implementation delivers business value.

**Key Responsibilities**:

* Read plan's value statement
* Review Implementation, Code Review, and QA docs (document-based, not code inspection)
* Verify implementation satisfies value statement
* Assess from user perspective
* Make release recommendation

**Key Constraint**: **Value, not technical quality** (that's QA). Quick sanity check when docs are present.

---

### DevOps Agent

**Purpose**: Manage releases safely.

**Key Responsibilities**:

* Verify packaging and versioning
* Execute release process
* Move Planka card to `Delivered` via native MCP tools
* Require explicit user approval

**Critical Constraint**: **Must ask user before releasing**. Never auto-releases.

---

### Retrospective & Process Improvement Agents

**Purpose**: Capture lessons after delivery and evolve the workflow.

**Critical Constraint**: **Requires user approval** before modifying `.agent.md` files.

---

## Skills System

Agents leverage **Skills**—modular, reusable instruction sets that load on-demand via progressive disclosure. This keeps agent files lean while providing deep expertise when needed.

### Skill Design: Lean Core + Optional References

To maintain token-efficiency, each skill keeps its core operational instructions in `SKILL.md`.

Optional `references/` files are allowed for shared templates or extended examples when they improve reuse across agents.

### Available Skills

| Skill | Purpose | Key Content |
| --- | --- | --- |
| `obsidian-workflow` | Graph Storage Contract | 10-Line Rule, native `obsidian` usage |
| `planka-workflow` | Agile tracking | Task lists, Native `planka` tool usage, Triad Bridge |
| `analysis-methodology` | Investigation techniques | Hard pivot triggers, confidence levels, gap tracking |
| `architecture-patterns` | Design rules | ADR templates, embedded Mermaid diagram templates |
| `code-review-checklist` | Technical checks | Native `search` regex and MCP `analyzer` triggers |
| `code-review-standards` | Review formatting | Severity definitions, markdown templates for Critic/Reviewer |
| `cross-repo-contract` | Multi-repo safety | API sync rules via `filesystem` MCP tools |
| `document-lifecycle` | File management | Numbering, closure procedures via `filesystem` MCP |
| `engineering-standards` | Software quality | SOLID, DRY, YAGNI, embedded Refactoring Catalog |
| `release-procedures` | Deployment rules | Two-stage workflow, semver validation |
| `security-patterns` | Vulnerability checks | OWASP Top 10, language-specific vulnerabilities |
| `testing-patterns` | Testing rules | TDD workflows, test pyramid, anti-patterns |

### Skill Placement

Skills are placed in different directories depending on your VS Code version:

| Version | Location | Notes |
| --- | --- | --- |
| **VS Code Stable (1.107.1)** | `.claude/skills/` | Legacy location, still supported |
| **VS Code Insiders** | `.github/skills/` | New recommended location |

> [!NOTE]
> These locations are changing with upcoming VS Code releases. The `.github/skills/` location is becoming the standard. Check the [VS Code Agent Skills documentation](https://code.visualstudio.com/docs/copilot/customization/agent-skills) for the latest guidance.

### Creating Skills

Each skill is a simple directory with a single `SKILL.md` file:

```text
.github/skills/
└── my-skill/
    └── SKILL.md           # Required: self-contained skill definition

```

*(Note: Native MCP workflows remain mandatory for execution. Optional `references/` files are documentation assets only.)*

**SKILL.md format:**

```yaml
---
name: my-skill
description: Brief description of when to use this skill
license: MIT
metadata:
  author: yourname
  version: "1.0"
---

# Skill Title

Detailed instructions, tables, code examples...

```

---

## Customization Guide

### Adding New Agents

1. Create `your-agent.agent.md` in `.github/agents/`
2. Follow the frontmatter format:

```yaml
---
description: One-line description
name: YourAgent
tools: ['filesystem/read_text_file', 'planka/create_task', 'search']
model: Claude 3.5 Sonnet (or preferred)
handoffs:
  - label: Handoff Name
    agent: TargetAgent
    prompt: Suggested prompt
    send: false
---

```

3. Define Purpose, Responsibilities, Constraints
4. Include the Obsidian Contract and Planka Contract sections
5. Copy to `.github/agents/` in your workspace

### Modifying Existing Agents

**Safe to modify**:

* `description`: Update for clarity
* `model`: Change to preferred model
* `handoffs`: Add/remove handoff targets
* Response style preferences

**Modify with caution**:

* `tools`: Removing tools limits capability
* Constraints: Removing constraints changes behavior significantly

**Generally don't modify**:

* Core separation of concerns (e.g., making Planner write code)
* Native MCP tool constraints (e.g., allowing terminal scripts)

### Creating Workspace-Specific Variants

You can have project-specific agent variants:

1. Copy an existing agent in `.github/agents/` and adapt it for your project
2. Modify for project needs
3. Project-specific agents override global agents with same name

---


## Troubleshooting & FAQ

### Agent Issues

**Q: Agent not appearing in Copilot**

* Check file location: `.github/agents/` for workspace, [VS Code profile folder](https://code.visualstudio.com/docs/configure/profiles) for user-level
* Verify file extension is `.agent.md`
* Reload VS Code

**Q: Agent ignores constraints**

* Re-invoke with explicit constraint reminder
* Check if constraint is clear in the `.agent.md` file
* Models sometimes drift; be explicit

**Q: Agent tries to do another agent's job**

* Use explicit handoff: "Hand off to [Agent] for [task]"
* Reference the agent's constraints

### Native MCP & Tooling Issues

**Q: Obsidian graph is not updating or retrieves irrelevant data**

* Verify the `obsidian` server is running and accessible in your VS Code MCP tool settings.
* Stop searching the full vault. Ensure the agent uses `read_note` on the specific `WF-<concrete-id>` handoff node.

**Q: Planka cards aren't updating or syncing natively**

* Ensure the `planka` server is running (e.g., via Docker on port 25478).
* Verify agents have permission to call tools like `add_comment`, `create_task_list`, or `create_card`.
* **CRITICAL**: Remind the agent strictly to use native Planka MCP tools and NOT to attempt running old python scripts like `sync_roadmap_epics.py` or `planka_ops.py`.

**Q: Bash scripts failing / Permission Denied**

* If an agent tries to run `verify-obsidian-graph.mjs`, `check-complexity.sh`, or `run-linters.sh`, stop it. Remind the agent that **all terminal scripts are strictly deprecated** and it must use `filesystem`, `search`, or `analyzer` MCP tools instead.

### Workflow Issues

**Q: Plans have too much implementation detail**

* Remind Planner of constraint: "WHAT and WHY, not HOW"
* Check if Planner `.agent.md` has this constraint

**Q: Security review is superficial**

* Use the enhanced Security agent (v2)
* Request specific phases: "Conduct Phase 2 (Code Security Review)"
* Provide specific files/endpoints to review

**Q: Too many handoffs, losing context**

* Ensure the Obsidian summary nodes (`WF-<concrete-id>`) are used correctly to maintain context.
* Reference artifact paths explicitly.

### General FAQ

**Q: Do I need all 13 agents?**
No. Start with Planner + Implementer. Add others as needed.

**Q: Can I use this without Obsidian?**
Yes, but agents won't remember context across handoffs effectively. Each conversation will require you to manually reference the artifact files.

**Q: Why separate QA and UAT?**

* QA = Technical quality (tests pass, coverage adequate)
* UAT = Business value (feature solves the stated problem)

**Q: Why can't Planner write code?**
Keeping planning separate from implementation:

* Forces clear requirements before coding
* Prevents premature implementation decisions
* Makes plans reviewable by non-coders

**Q: How do I handle urgent fixes that don't need full planning?**
For hotfixes:

1. Go directly to Implementer with clear scope
2. Have Security review if security-relevant
3. QA for test verification
4. Skip full planning pipeline

---



---

## Agent Orchestration Playbook

> This section documents when and how to use local, background, and subagent execution patterns for custom agents in VS Code 1.107+.

### Execution Modes Overview

| Mode | When to Use | Key Characteristics |
| --- | --- | --- |
| **Local Interactive** | Planning, strategy, review, handoffs | User in the loop, real-time collaboration |
| **Background Agent** | Long-running implementation, parallel tasks | Git worktree isolation, hands-off execution |
| **Subagent** | Focused subtask delegation | Context-isolated, returns findings to caller |

### Phase 1: Local Interactive (Strategy & Planning)

**Agents**: Roadmap, Architect, Planner, Analyst, Critic, Security (threat modeling)

**Pattern**: User selects agent from dropdown in VS Code chat. Conversation is interactive with frequent checkpoints.

```text
User selects Roadmap agent → "Define epic for X"
     selects Planner agent → "Create plan for epic"
     selects Architect agent → "Review architectural fit"
     selects Critic agent → "Review plan 002"

```

> [!NOTE]
> Custom agents are selected from the agents dropdown—not invoked with `@` syntax. The `@` symbol is strictly for built-in participants like `@workspace`.

**When to use**:

* Defining strategic direction (Roadmap)
* Creating or revising plans (Planner)
* Architectural decisions requiring judgment (Architect)
* Pre-implementation reviews (Critic, Security)
* Research with unclear scope (Analyst)

### Phase 2: Background Implementation (Execution)

**Agents**: Implementer, QA, Security (code audit)

**Pattern**: After plan approval, run execution-focused agents as background agents in Git worktrees for isolated, parallel, or long-running work.

```text
Planner (plan approved) ──▶ Background: Implementer in worktree
                            Background: QA test strategy
                            Background: Security code audit

```

**When to use**:

* Multi-file implementation (Implementer)
* Comprehensive test execution (QA)
* Full 5-phase security audits (Security)
* Any task expected to take >15 minutes

**Benefits**:

* Git worktree isolation prevents interference with main workspace
* Can run multiple background agents in parallel (e.g., QA + Security)
* Results can be reviewed and selectively merged

### Phase 3: Review & Merge (Validation)

**Agents**: Code Reviewer, QA, UAT, DevOps

**Pattern**: Return to local interactive mode to review background agent results, validate value delivery, and prepare release.

```text
Background results ──▶ Local: Code Reviewer analyze complexity
                       Local: QA verify tests
                       Local: UAT validate value
                       Local: DevOps release (user approval required)

```

**When to use**:

* Reviewing background implementation results (Code Reviewer)
* Verifying test coverage (QA)
* Final value validation (UAT)
* Release execution (DevOps always local, always requires explicit user approval)

### Subagent Usage Patterns

**Definition**: A subagent is invoked by another agent (the "caller") to perform a focused, context-isolated task. The subagent returns findings to the caller rather than taking independent action.

**Subagent-Eligible Agents** (may be auto-invoked):

| Agent | Subagent Use Case |
| --- | --- |
| Analyst | Clarify technical questions mid-implementation |
| Security | Targeted security review of specific code |
| QA | Test implications for a specific change |

**Explicit-Only Agents** (should NOT be auto-invoked):

| Agent | Reason |
| --- | --- |
| Roadmap | Strategic decisions require user involvement |
| Architect | System-level decisions need explicit review |
| Process Improvement | Cross-cutting process changes need approval |
| DevOps | Release actions require explicit user confirmation |

**Subagent Invocation Example**:

```text
Implementer working on feature
├── Hits technical unknown
├── Invokes Analyst as subagent: "How does API X handle pagination?"
├── Analyst returns findings
└── Implementer continues with answer

```

### Security and Tool Approval Guidance

With the transition to **Native MCP First**, the need for terminal commands is drastically reduced. Follow these approval rules:

**Always Manual Approval** (never auto-approve):

* `execute/runInTerminal` with destructive commands (`rm`, `git push --force`, `npm publish`)
* `execute/runTask` for deploy/publish tasks
* Any command modifying infrastructure or external services
* Package install commands in production contexts

**Session Auto-Approval Eligible** (highly recommended for workflow speed):

* `filesystem/*` (Reading, writing, and moving files/directories securely)
* `analyzer/*` (Ruff and Vulture static code analysis)
* `planka/*` (Task creation, card updates, leaving comments)
* `obsidian/*` (Reading notes, patching workflow nodes)
* Native VS Code `search` tool

### Orchestration Quick Reference

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    AGENT ORCHESTRATION FLOW                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  PHASE 1: LOCAL INTERACTIVE (Strategy)                              │
│  ┌─────────┐   ┌─────────┐   ┌──────────┐   ┌────────┐             │
│  │ Roadmap │──▶│ Planner │──▶│ Architect│──▶│ Critic │             │
│  └─────────┘   └─────────┘   └──────────┘   └────────┘             │
│       │             │              │             │                   │
│       └─────────────┴──────────────┴─────────────┘                   │
│                    [Analyst/Security as needed]                      │
│                                                                     │
│  PHASE 2: BACKGROUND (Execution) ─── Git Worktree Isolation         │
│  ┌─────────────┐   ┌────────────┐   ┌──────────────┐               │
│  │ Implementer │   │     QA     │   │   Security   │               │
│  │ (parallel)  │   │ (parallel) │   │  (parallel)  │               │
│  └─────────────┘   └────────────┘   └──────────────┘               │
│                                                                     │
│  PHASE 3: LOCAL INTERACTIVE (Validation)                            │
│  ┌──────────┐   ┌──────┐   ┌──────┐   ┌────────┐                   │
│  │ Code Rev │──▶│  QA  │──▶│ UAT  │──▶│ DevOps │                   │
│  │ (verify) │   │(test)│   │(val.)│   │(relea.)│                   │
│  └──────────┘   └──────┘   └──────┘   └────────┘                   │
│                                           ▲                         │
│                                           │                         │
│                                [USER APPROVAL REQUIRED]             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

```

---


## License

MIT License - see [LICENSE](https://www.google.com/search?q=LICENSE)
