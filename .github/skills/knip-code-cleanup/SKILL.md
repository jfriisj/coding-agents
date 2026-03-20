---
name: knip-code-cleanup
description: Reference guide for utilizing Knip to identify and manage unused files, dependencies, and exports in JavaScript/TypeScript projects. Use this skill when performing code cleanups, especially for addressing technical debt related to orphaned code and dependencies. Always refer to this guide to understand the standard workflows, configuration best practices, and execution modes for safe and effective code cleanup with Knip.
---

# Knip Code Cleanup Reference

This document outlines the capabilities, standard workflows, and best practices for using Knip to maintain JavaScript and TypeScript codebases.

**Scope and Limitations:** Knip is designed strictly for project-wide analysis to find unused files, dependencies, and exports. It does not handle unused imports or variables *inside* individual files (which is typically managed by linters like ESLint or Biome).

### 1. Setup and Discovery
Standard initialization involves verifying the tool's presence and understanding the project context:
* **Installation Check:** The `npx knip --version` command verifies the current installation. If absent, Knip is typically installed as a development dependency.
* **Environment Analysis:** Frameworks and existing configurations are identified by examining `package.json` (for tools and `"knip"` keys) or dedicated config files like `knip.json` or `knip.jsonc`.

### 2. The Configuration-First Loop
To avoid false positives, the standard Knip workflow dictates a configuration-first approach before any code is modified or deleted:
* **Configuration Hints:** Running `npx knip` generates configuration hints at the top of the output. These hints guide necessary adjustments in `knip.json` (e.g., enabling framework plugins, adding entry patterns, or configuring monorepo workspaces).
* **Iteration:** The analysis is iteratively re-run until all configuration hints are resolved, ensuring a stable baseline for code cleanup.

### 3. Targeted Cleanup Priorities
Once the configuration is stable, issues are typically addressed in a specific priority order to reduce noise efficiently:
1. **Unused Files:** Addressed first to clear out the most significant orphaned elements.
2. **Unused Dependencies:** Removed from `package.json`.
3. **Unused devDependencies:** Removed from `package.json`.
4. **Unused Exports:** Removed entirely or explicitly marked as internal API.
5. **Unused Types:** Removed, or if used locally, handled via the `ignoreExportsUsedInFile: { interface: true, type: true }` configuration.

### 4. Auto-Fixing Capabilities
Knip provides several automated execution modes for safe or aggressive cleanups:
* **Safe Fix:** `npx knip --fix` automates the removal of unused exports and dependencies.
* **Aggressive Fix:** `npx knip --fix --allow-remove-files` includes the automated deletion of unused files.
* **Production Focus:** `npx knip --production` scopes the analysis strictly to production code, deliberately ignoring tests and configuration files.

### 5. Best Practices and Guardrails
* **Pattern Exclusions:** Generic `ignore` patterns are strongly discouraged as they mask underlying issues. Valid entry points are instead added to the `entry` configuration, and Node.js built-ins (like `buffer`) are handled via `ignoreDependencies`.
* **Redundant Configurations:** Ignoring `.git`, `node_modules`, or `dist` is unnecessary, as Knip natively respects `.gitignore` rules.
* **Safety Checks:** Manual verification is standard practice before deleting potential entry points, public API exports (e.g., `index.ts`, `lib/`), or dynamically imported files to prevent accidental removal of critical code.