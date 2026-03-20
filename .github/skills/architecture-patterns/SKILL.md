---
name: architecture-patterns
description: Common software architecture patterns, ADR templates, diagram templates, and anti-pattern detection. Integrates strictly with Obsidian (Native MCP) for memory graphs and Planka (Native MCP) for design constraints tracking. Use this skill when reviewing system design, planning architecture, evaluating tradeoffs, or documenting architectural decisions.
---

# Architecture Patterns

Reference for architectural design and documentation. Use this skill when:
- Architect reviews system design
- Planner considers architectural constraints
- Analyst investigates integration approaches
- Critic evaluates architectural alignment

## The Triad of Truth (Architecture)

Every architectural decision must be reflected across three systems:
1. **Markdown (`agent-output/architecture/`)**: The detailed ADRs, master architecture doc, and findings.
2. **Obsidian Graph (`workflows/`)**: The lightweight `WF-` nodes linking architecture decisions to specific Epics and Plans (using the 10-Line Rule).
3. **Planka Board**: The "Architecture & Design" Task List on the relevant Epic card to enforce implementation constraints via Native MCP.

---

## Architecture Decision Records (ADR)

### ADR Format

Every significant architectural decision should be documented in `agent-output/architecture/`. All ADRs and Findings documents MUST include this standard YAML frontmatter for artifact indexing:

```markdown
---
ID: [NNN]
Type: Architecture
Status: [Proposed | Accepted | Deprecated]  # This is the decision status, not execution status
Epic: "[[WF-E<epic-number>]]"
Planka-Card: "CARD_ID_NUMERIC"
---
# ADR-[NNN]: [Decision Title]

## Context
[What is the situation? What forces are at play?]

## Decision
[What is the change being proposed or decided?]

## Consequences
### Positive
- [Benefit 1]

### Negative
- [Tradeoff 1]

### Neutral
- [Side effect]

## Alternatives Considered
1. [Alternative 1]: [Why rejected]

## Related
- ADR-XXX: [Related decision]

```

### When to Write ADRs

| Scenario | ADR Required? |
| --- | --- |
| New external dependency | Yes |
| New architectural pattern | Yes |
| Technology switch | Yes |
| Module boundary change | Yes |
| Performance tradeoff | Yes |
| Bug fix | No |
| Refactoring (same behavior) | Usually no |

---

## Common Patterns

### Layered Architecture

```text
┌─────────────────────────────────┐
│         Presentation            │  UI, API endpoints
├─────────────────────────────────┤
│          Application            │  Use cases, orchestration
├─────────────────────────────────┤
│           Domain                │  Business logic, entities
├─────────────────────────────────┤
│        Infrastructure           │  DB, external services
└─────────────────────────────────┘

```

**Rules:** Dependencies point downward only. Lower layers never import from higher. Domain has no external dependencies.

### Repository Pattern

**Purpose:** Abstract data access, enable testability without real databases.

### Service Layer

**Purpose:** Encapsulate business operations, transaction coordination, and cross-cutting concerns.

### Event-Driven Architecture

**Purpose:** Loose coupling, asynchronous processing, audit trails.

### Dependency Injection

**Purpose:** Invert control to easily swap implementations (e.g., MockDatabase for testing).

---

## Anti-Patterns to Detect

| Anti-Pattern | Detection | Fix |
| --- | --- | --- |
| **God Object** | Class with 20+ methods, 500+ lines | Extract classes |
| **Circular Dependencies** | A→B→C→A | Introduce interface |
| **Big Ball of Mud** | No clear structure | Define boundaries |
| **Spaghetti Code** | Tangled control flow | Refactor, add layers |
| **Anemic Domain** | Data classes + procedure classes | Move logic to domain |
| **Leaky Abstraction** | Implementation details exposed | Hide behind interface |

*(Note: The Architect may use safe terminal read commands like `grep`, `find`, or `madge` exclusively for codebase analysis to detect these patterns).*

---

## System Architecture Documentation

For `system-architecture.md` (Must also contain Dataview YAML header):

1. **Purpose**: What does this system do?
2. **High-Level Architecture**: Diagram, major components
3. **Components**: Each component's responsibility
4. **Data Flow**: How data moves through system
5. **Dependencies**: External services, libraries
6. **Quality Attributes**: Performance, security, scalability goals
7. **Decisions**: ADRs or decision log
8. **Known Issues**: Technical debt, problem areas

### Reconciliation Changelog Template

When reconciling architecture docs after implementations, use this format:

| Date | Change | Rationale | Source |
| --- | --- | --- | --- |
| YYYY-MM-DD | Added caching layer | Reconciled from Plan-015 | Plan-015 |

### Design Debt Registry Template

Track architectural improvements in the **Problem Areas** section:

| ID | Area | Current State | Optimal State | Priority | Discovered |
| --- | --- | --- | --- | --- | --- |
| DD-001 | Memory | Direct calls scattered | Unified facade | Medium | 2024-12-15 |

---

## Diagram Templates (Mermaid)

Always use Mermaid for version-controlled diagrams. Here are baseline templates to ensure correct syntax and structure.

**Component Diagram:**

```mermaid
graph TB
    subgraph "System Name"
        subgraph "Layer 1"
            A[Component A]
            B[Component B]
        end
        
        subgraph "Layer 2"
            C[Component C]
            D[Component D]
        end
    end
    
    External[External Service]
    
    A --> C
    B --> C
    B --> D
    C --> External

```

**Sequence Diagram:**

```mermaid
sequenceDiagram
    participant U as User
    participant A as API
    participant S as Service
    participant D as Database
    
    U->>A: Request
    A->>S: Process
    S->>D: Query
    D-->>S: Result
    S-->>A: Response
    A-->>U: Response

```

**Data Flow Diagram:**

```mermaid
flowchart LR
    subgraph Input
        I1[User Input]
        I2[API Request]
    end
    
    subgraph Processing
        P1[Validation]
        P2[Business Logic]
        P3[Transformation]
    end
    
    subgraph Output
        O1[Database]
        O2[Response]
        O3[Queue]
    end
    
    I1 --> P1
    I2 --> P1
    P1 --> P2
    P2 --> P3
    P3 --> O1
    P3 --> O2
    P3 --> O3

```

**Entity Relationship (Simple):**

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER_ITEM }|--|| PRODUCT : references
    
    USER {
        int id PK
        string email
        string name
    }
    
    ORDER {
        int id PK
        int user_id FK
        date created_at
    }

```

**State Diagram:**

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Pending: submit
    Pending --> Approved: approve
    Pending --> Rejected: reject
    Approved --> [*]
    Rejected --> Draft: revise

```

**C4 Context (Simplified):**

```mermaid
graph TB
    subgraph "Users"
        User[User]
        Admin[Admin]
    end
    
    subgraph "System"
        App[Application]
    end
    
    subgraph "External"
        Email[Email Service]
        Payment[Payment Gateway]
    end
    
    User --> App
    Admin --> App
    App --> Email
    App --> Payment

```

**Deployment Diagram:**

```mermaid
graph TB
    subgraph "Production"
        subgraph "Load Balancer"
            LB[nginx]
        end
        
        subgraph "App Servers"
            A1[App 1]
            A2[App 2]
        end
        
        subgraph "Data"
            DB[(PostgreSQL)]
            Cache[(Redis)]
        end
    end
    
    LB --> A1
    LB --> A2
    A1 --> DB
    A2 --> DB
    A1 --> Cache
    A2 --> Cache

```

---

## Agent Responsibilities & The Triad Handoff

### 04-Architect (Execution & Handoff)

Before handing off, the Architect MUST align the triad using **Native MCP Tools**:

1. **The Artifact (`agent-output/`)**: Document ADRs and update `system-architecture.md`.
2. **The Execution (Planka Board)**:

* Use native tools (`create_task_list`, `create_task`) to ensure an "Architecture & Design" Task List exists on the Epic card.
* Add Tasks for specific constraints the Implementer must follow.
* Use `add_comment` to leave the final verdict (`APPROVED`, `APPROVED_WITH_CHANGES`, `REJECTED`) and link to the findings document and Obsidian node.

3. **The Memory (Obsidian Graph)**:

* Use native tools (`write_note`, `patch_note`) to create/update `workflows/WF-<concrete-id>-<slug>.md`.
* Strictly follow the **10-Line Rule** (`type`, `parent`, `Planka-Card`, max 3-bullet summary, and Artifact link).
* Patch the calling agent's node to link back to your new Architect node.

**Final Chat Message**:
Always conclude your turn in the chat with:

> *"Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC)."*

### Other Agents

* **Analyst**: Consult Architect for systemic pattern questions.
* **Planner**: Read active `WF-Architecture` notes before planning.
* **Critic**: Verify architectural alignment against `system-architecture.md`.
