---
name: engineering-standards
description: Core software engineering principles (SOLID, DRY, YAGNI, KISS) and refactoring catalog. Integrates strictly with Obsidian/Planka via Native MCP for tracking technical debt. Use this skill when reviewing code, planning architecture, evaluating technical debt, or executing refactoring.
---

# Engineering Standards & Refactoring

Foundational principles for high-quality software. Use this skill when reviewing code, planning architecture, evaluating technical debt, or executing refactoring.

## 1. The Triad of Truth (Technical Debt & Standards)

When these standards are applied or violated, findings must be anchored using **Native MCP Tools**:
1. **Markdown (`agent-output/`)**: Save full technical analyses, ADRs, or code-review findings.
2. **Obsidian Graph (`workflows/`)**: Major architectural refactoring decisions must be logged in a `WF-<concrete-id>` node following the strict **10-Line Rule**.
3. **Planka Board**: Use `create_task` to add specific refactoring/tech-debt items to the Epic card, or `add_comment` to flag code smells.

---

## 2. SOLID Principles

### Single Responsibility (SRP)
A class/module should have one reason to change.
* **Detection:** Class with 5+ public methods doing unrelated things. Method > 50 lines. "Manager" classes.
* **Refactoring:** Extract class for each responsibility.

### Open/Closed (OCP)
Open for extension, closed for modification.
* **Detection:** `switch/case` or `if/else` chains checking instance types.
* **Refactoring:** Strategy pattern, Polymorphism.

### Liskov Substitution (LSP)
Subtypes must be substitutable for their base types.
* **Detection:** Override that throws "not implemented". Type checks before calling inherited methods.
* **Refactoring:** Extract interface, use composition.

### Interface Segregation (ISP)
Clients shouldn't depend on methods they don't use.
* **Detection:** Interface with 10+ methods. Stubbed no-op methods.
* **Refactoring:** Split into role-specific interfaces.

### Dependency Inversion (DIP)
Depend on abstractions, not concretions.
* **Detection:** Direct instantiation of dependencies (`new ConcreteClass()`). Hard-coded DB/API connections.
* **Refactoring:** Constructor injection.

---

## 3. DRY, YAGNI, & KISS

**DRY (Don't Repeat Yourself)**
* **Detection:** Copy-pasted blocks (3+ times). Similar functions with minor variations.
* **Refactoring:** Extract shared function, parameterize variations. *(Exception: Test code clarity).*

**YAGNI (You Aren't Gonna Need It)**
* **Detection:** Unused parameters "for future use". Speculative generalization.
* **Action:** Build for current requirements. Delete dead code immediately.

**KISS (Keep It Simple, Stupid)**
* **Detection:** Cyclomatic complexity > 10. Nested callbacks > 4 deep. Framework overkill.
* **Refactoring:** Flatten control flow. Use early returns.

---

## 4. Code Smells Quick Reference

| Smell | Symptom | Fix |
|-------|---------|-----|
| **Long Method** | >50 lines, multiple concerns | Extract method |
| **Large Class** | >500 lines, many responsibilities | Extract class |
| **Feature Envy** | Method uses other class more than own | Move method |
| **Data Clumps** | Same fields appear together often | Extract object |
| **Primitive Obsession**| Strings/ints for domain concepts | Value objects |
| **Switch Statements** | Type-based switching | Polymorphism |

---

## 5. Refactoring Catalog (Implementation Guide)

When executing refactoring, follow these before/after patterns.

### Extract Method
**When:** A code block can be grouped with a descriptive name to improve readability or SRP.
```python
# Before
def process():
    if not x: raise Error
    if not y: raise Error
    result = complex_operation()

# After
def process():
    validate_input(x, y)
    result = complex_operation()

def validate_input(x, y):
    if not x: raise Error
    if not y: raise Error

```

### Extract Class

**When:** A class has multiple responsibilities (violating SRP).

```python
# Before
class Order:
    def calculate_total(self): ...
    def format_invoice(self): ...
    def send_email(self): ...

# After
class Order:
    def calculate_total(self): ...

class InvoiceFormatter:
    def format(self, order): ...

class OrderNotifier:
    def send_email(self, order): ...

```

### Replace Conditional with Polymorphism

**When:** A switch/case or if/else chain checks types to determine behavior (violating OCP).

```python
# Before
def calculate_pay(employee):
    if employee.type == "hourly":
        return hours * rate
    elif employee.type == "salary":
        return annual / 12

# After
class HourlyEmployee:
    def calculate_pay(self):
        return self.hours * self.rate

class SalariedEmployee:
    def calculate_pay(self):
        return self.annual / 12

```

### Introduce Parameter Object

**When:** The same group of parameters consistently appear together.

```python
# Before
def search(start_date, end_date, min_price, max_price): ...

# After
@dataclass
class SearchCriteria:
    start_date: date
    end_date: date
    min_price: float
    max_price: float

def search(criteria: SearchCriteria): ...

```

### Guard Clause

**When:** Deeply nested conditionals obscure the primary "happy path" (violating KISS).

```python
# Before
def process(x):
    if x:
        if x.valid:
            if x.ready:
                return do_work(x)
    return None

# After
def process(x):
    if not x: return None
    if not x.valid: return None
    if not x.ready: return None
    return do_work(x)

```
