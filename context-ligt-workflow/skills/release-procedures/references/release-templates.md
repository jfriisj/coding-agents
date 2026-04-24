# Release Document Templates

## Deployment Document Template

Use in `agent-output/deployment/[version].md`:

Status guidance for document header:
- `Active`: In progress
- `Committed`: Stage 1 completed (local commit only)
- `Released`: Stage 2 completed successfully
- `Abandoned`: Release flow intentionally stopped

````markdown
---
ID: [ID]
Origin: [Origin]
UUID: [UUID]
Status: Active
Type: Deployment
Version: [Version]
---

# Deployment [Version]

## Plan Reference

- Included plans: [Plan IDs]
- Primary release roadmap reference: `agent-output/roadmap/product-roadmap.md`

## Release Date

- Target: [YYYY-MM-DD]
- Execution timestamp: [YYYY-MM-DD HH:MM TZ]

## Release Summary

| Field | Value |
|---|---|
| Version | [Version] |
| Release Type | [Patch/Minor/Major] |
| Environment | [target environment] |
| Branch | [branch name] |
| Initiated By | [name/agent] |
| Approved By | [name] |

## Epic Readiness Matrix

| Epic | Linked Plans | UAT Rollup | Roadmap Waiver/Deferred | Blockers |
|---|---|---|---|---|
| [Epic X.Y title] | [Plan IDs] | [EPIC APPROVED / PARTIAL / NOT APPROVED] | [None / Waived / Deferred] | [None / detail] |

## Pre-Release Verification

### UAT/QA Approval

- [ ] QA status verified as `QA Complete` for all included plans
- [ ] UAT status verified as `APPROVED FOR RELEASE` for all included plans

### Version Consistency

- [ ] `package.json` version matches target release
- [ ] `CHANGELOG.md` latest release entry matches target version
- [ ] README/config/version references checked
- [ ] Git tag does not conflict with existing release tag

### Packaging Integrity

- [ ] Build completed successfully
- [ ] Artifact/package scripts verified
- [ ] Required assets included
- [ ] No debug-only artifacts in release package

### Gitignore Review

- [ ] `git status` reviewed for sensitive/unexpected files
- [ ] `.gitignore` changes approved if required

### Workspace Cleanliness

- [ ] No unintended uncommitted changes remain
- [ ] All release-included plan commits are present locally

## User Confirmation

| Field | Value |
|---|---|
| Summary Presented At | [timestamp] |
| Presented Summary | [short summary of included plans + release scope] |
| User Response | [Approved / Declined] |
| User Name | [name] |
| Response Timestamp | [timestamp] |
| Decline Reason (if any) | [reason] |

## Release Execution

### Git Tagging

- Command: `[git tag command]`
- Result: [success/fail + output]
- Tag pushed: [yes/no]

### Push

- Command: `[git push command]`
- Result: [success/fail + output]

### Package Publication

- Registry/Target: [npm/vsce/pypi/github/etc]
- Command: `[publish command]`
- Result: [success/fail + output]
- URL: [release/package URL]

### Publication Verification

- [ ] Released version visible in target registry/marketplace
- [ ] Install/consume check succeeded
- [ ] Release notes/changelog visible and correct
- [ ] No blocking publish errors/warnings

## Post-Release Status

| Field | Value |
|---|---|
| Final Status | [Deployment Complete / Deployment Failed / Aborted] |
| Completed At | [timestamp] |
| Known Issues | [none / list] |
| Rollback Plan | [link or summary] |

## Deployment History Entry

```json
{
  "version": "[Version]",
  "timestamp": "[ISO-8601]",
  "environment": "[target environment]",
  "status": "[released|failed|aborted]",
  "authorizer": "[name]",
  "includedPlans": ["[Plan ID]"],
  "tag": "[tag name]",
  "releaseUrl": "[url]"
}
```

## Next Actions

- [ ] Update included plan statuses to `Released`
- [ ] Hand off to Roadmap agent to update release tracker
- [ ] Hand off to Retrospective agent

## Changelog

| Date | Agent | Change | Notes |
|---|---|---|---|
| [YYYY-MM-DD] | 05a-DevOps | Deployment document created | Initialized from template |
````

---

## CHANGELOG Entry Template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Brief description of new feature (#issue)

### Changed
- Brief description of change (#issue)

### Fixed
- Brief description of bug fix (#issue)

### Security
- Brief description of security fix (#issue)
```

---

## Git Tag Message Template

```text
Release vX.Y.Z

Key changes:
- Feature: Brief description
- Fix: Brief description

Full changelog: [link to CHANGELOG]
```
