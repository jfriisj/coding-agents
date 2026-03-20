---
name: security-patterns
description: Comprehensive security methodology, OWASP Top 10, and templates. Uses Progressive Disclosure to lazy-load language-specific vulnerabilities via Native MCP. Use this skill for security audits, code reviews, and threat modeling.
---

# Security Patterns & Methodology

Systematic approach to identifying and remediating security vulnerabilities. Use this skill when conducting security audits, reviewing code, or creating Threat Models.

## 1. The Triad of Truth (Security)

Every security audit or threat model must be synchronized across three systems:
1. **Markdown (`agent-output/security/`)**: The detailed assessment using the template below.
2. **Obsidian Graph (`workflows/`)**: The `WF-` node linking your security verdict to the Plan or Implementation.
3. **Planka Board**: The "Security & Audit" Task List, visual labels (e.g., `Security Blocked`), and your verdict comment.

---

## 2. Tooling Contract (MCP First, Zero Terminal)

**CRITICAL RULE**: Do NOT use terminal bash scripts. You MUST use structured MCP tools:

### Secrets Scanning (Native Search)
Use the native `search` tool (with regex enabled) to scan the workspace for hardcoded secrets:
* **AWS Keys**: `AKIA[0-9A-Z]{16}`
* **Passwords**: `(?i)password\s*[=:]\s*["'][^"']{8,}["']`
* **Private Keys**: `-----BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY-----`
* **GitHub Tokens**: `gh[pousr]_[A-Za-z0-9_]{36,}`
* **JWT Tokens**: `eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*`

### Dependency Checks
Use `filesystem/read_text_file` to read `package.json`, `requirements.txt`, or `go.mod` to identify outdated dependencies.

---

## 3. Language-Specific Deep Dives (Progressive Disclosure)

To save context tokens, this skill uses lazy loading for deep language specifics. Once you identify the primary language of the repository, you MUST use `filesystem/read_text_file` to load the corresponding reference:

* **If TypeScript/JavaScript**: Read `.github/skills/security-patterns/references/javascript-vulnerabilities.md`
* **If Python**: Read `.github/skills/security-patterns/references/python-vulnerabilities.md`
* **If Go**: Read `.github/skills/security-patterns/references/go-vulnerabilities.md`
* **If Java/Kotlin**: Read `.github/skills/security-patterns/references/java-vulnerabilities.md`

---

## 4. Security Review Methodology (STRIDE)

| Threat | Questions to Ask | Controls |
|--------|------------------|----------|
| **S**poofing | Can an attacker impersonate users/systems? | Auth, MFA, certificates |
| **T**ampering | Can data be modified in transit/rest? | Integrity checks, MACs |
| **R**epudiation | Can actions be denied? | Tamper-proof audit logs |
| **I**nfo Disclosure | Where could sensitive data leak? | Encryption, access control |
| **D**enial of Service | What resources can be exhausted? | Rate limits, redundancy |
| **E**levation | Can users gain unauthorized access? | RBAC, input validation |

### Severity Classification (CVSS-Aligned)
| Severity | CVSS Score | Definition |
|----------|------------|------------|
| **CRITICAL** | 9.0 - 10.0 | Active exploitation possible, data breach imminent. **REJECT** |
| **HIGH** | 7.0 - 8.9 | Significant vulnerability, exploitation likely. **REJECT** |
| **MEDIUM** | 4.0 - 6.9 | Moderate risk, requires specific conditions. |
| **LOW** | 0.1 - 3.9 | Minor issue, minimal impact. |

---

## 5. OWASP Top 10 (2021) Quick Detection

### A01: Broken Access Control
**Detection patterns:**
- Missing authorization checks on endpoints
- Direct object references without ownership validation
- Path traversal: `../` in file paths
- CORS with `Access-Control-Allow-Origin: *`
- JWT without signature verification

**Remediation:**
- Implement RBAC/ABAC at controller/service layer
- Validate ownership on every resource access
- Use allowlists for file paths
- Configure CORS with specific origins

### A02: Cryptographic Failures
**Detection patterns:**
- MD5/SHA1 for passwords
- Hardcoded encryption keys
- HTTP for sensitive data
- Weak random: `Math.random()`, `rand()`
- Missing encryption at rest

**Remediation:**
- Use bcrypt/argon2 for passwords (cost ≥12)
- External key management (KMS, Vault)
- TLS 1.2+ everywhere
- Cryptographic RNG only

### A03: Injection
**Detection patterns:**
- String concatenation in SQL/NoSQL queries
- Template literals in HTML without escaping
- `eval()`, `exec()`, `Function()` with user input
- Shell commands with string interpolation
- LDAP/XPath queries with user input

**Remediation:**
- Parameterized queries always
- Context-aware output encoding
- Never eval untrusted input
- Use ORM/query builders

### A04: Insecure Design
**Detection patterns:**
- Business logic without rate limiting
- Missing account lockout
- No CAPTCHA on authentication
- Unbounded resource allocation
- Missing threat model documentation

**Remediation:**
- Rate limit all sensitive operations
- Implement progressive delays
- Bound all allocations
- Document trust boundaries

### A05: Security Misconfiguration
**Detection patterns:**
- Default credentials in config
- Verbose error messages to users
- Debug mode in production
- Unnecessary services enabled
- Missing security headers

**Remediation:**
- Automated hardening scripts
- Generic error messages externally
- Disable debug in production
- Minimize attack surface

### A06: Vulnerable Components
**Detection patterns:**
- Dependencies with known CVEs
- Outdated framework versions
- Abandoned packages (no updates >2 years)
- Single-maintainer critical deps

**Remediation:**
- Automated dependency scanning
- Regular update schedule
- Evaluate package health before adoption
- Pin specific versions with lockfiles

### A07: Authentication Failures
**Detection patterns:**
- Weak password requirements
- Missing brute force protection
- Session tokens in URL
- No session timeout
- Plain passwords in logs

**Remediation:**
- Strong password policy
- Account lockout/delays
- Secure cookie flags
- Session timeout <30 min idle
- Never log credentials

### A08: Data Integrity Failures
**Detection patterns:**
- Deserialization of untrusted data
- Missing integrity checks on downloads
- Unsigned software updates
- CI/CD without verification

**Remediation:**
- Avoid native deserialization
- Verify checksums/signatures
- Sign all releases
- Secure CI/CD pipeline

### A09: Logging Failures
**Detection patterns:**
- No logging on auth events
- Sensitive data in logs
- Logs without timestamps
- No centralized logging
- Missing alerting

**Remediation:**
- Log all security events
- Sanitize log data
- Structured logging with timestamps
- Centralize with retention policy

### A10: SSRF
**Detection patterns:**
- User-controlled URLs in server requests
- Internal service access without validation
- Cloud metadata endpoint accessible
- URL parsing inconsistencies

**Remediation:**
- Allowlist URLs/domains
- Block internal IP ranges
- Disable cloud metadata endpoint
- Use URL parser consistently

---

## 6. Security Document Template

Save your assessment to `agent-output/security/NNN-[topic]-security-audit.md`:

```markdown
---
ID: [NNN]
Type: SecurityAudit
Status: [Active / Closed]
Epic: "[[WF-E<epic-number>]]"
Planka-Card: "CARD_ID_NUMERIC"
---

# Security Assessment: [Feature/Component Name]

## Executive Summary
**Overall Risk Rating**: CRITICAL | HIGH | MEDIUM | LOW
**Verdict**: APPROVED | APPROVED_WITH_CONTROLS | REJECTED

## Threat Model (STRIDE)
[Brief analysis results]

## Findings

### [SEVERITY] ID: [Category] - [Title]
- **Location**: `file.ts:123`
- **Issue**: [What's wrong]
- **Risk**: [Impact if exploited]
- **Fix**: [How to remediate]
- **CVSS**: [Score]

## Compliance & Controls
[Required controls that must be implemented for approval]

```

---

## 7. Agent Responsibilities & The Triad Handoff

Before concluding your turn, you MUST align the Triad using **Native MCP Tools**:

1. **The Artifact (`agent-output/`)**: Save the filled document template using `filesystem/write_file`.
2. **The Execution (Planka Board)**:
* Use `create_task` for specific security controls or blocking findings.
* Use `add_label_to_card` for the visual verdict.
* Use `add_comment` to state the final verdict.


3. **The Memory (Obsidian Graph)**:
* Use `obsidian/write_note` to create your `WF-<concrete-id>` node.
* Strictly follow the **10-Line Rule** (`type: Security`, `parent: "[[WF-...]]"`, and max 3-bullet summary).
* Patch the calling agent's node to link to yours.



**Final Chat Message**:
Always conclude your turn with:

> *"Handoff Ready. Parent Node context for the next agent is [[WF-...]] (Planka Card: CARD_ID_NUMERIC)."*
