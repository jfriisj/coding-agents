---
name: mcp-server-filesystem
description: Reference guide for the Filesystem MCP Server tools, covering file reading, writing, searching, editing, and directory management. Use this skill when you need to perform any filesystem operations within the allowed directories, such as reading file contents, modifying files, searching for files, or managing directories. Always refer to this guide to understand the capabilities and constraints of the Filesystem MCP Server before executing any file operations.
---

# Filesystem MCP Server Reference

This document outlines the capabilities and intended usage of the tools provided by the Filesystem MCP Server.

**Access Control:** All operations are strictly restricted to permitted directories. The `list_allowed_directories` tool provides the current scope of accessible paths. Operations outside these bounds will result in access errors.

### 1. Exploring and Searching
The following tools are available for navigating and querying the filesystem:
* **Directory Inspection:** `list_directory` and `list_directory_with_sizes` return the immediate contents of a specific folder. For a recursive, structural overview, `directory_tree` is used.
* **File Discovery:** `search_files` locates files or directories using glob pattern matching. Performance and relevance are typically optimized by utilizing `excludePatterns` (such as `node_modules` or `.git`).
* **Metadata Retrieval:** `get_file_info` extracts file or directory properties, including size, entity type, and modification dates.

### 2. Reading Content
Data extraction is handled by specialized tools depending on the file type and size:
* **Standard Text:** `read_text_file` reads plain text or code. To conserve context window space on large files, the `head` or `tail` parameters can be applied to read only the beginning or end of a file.
* **Batch Reading:** `read_multiple_files` allows simultaneous reading of several files to gather broader context.
* **Media Assets:** `read_media_file` is utilized specifically for processing image or audio files.

### 3. Modifying and Creating Files (⚠️ Caution)
Modifications to the filesystem are handled through specific tools depending on the scope of the change:
* **Targeted Edits (Recommended):** `edit_file` is the standard tool for modifying existing code or text. It includes a `dryRun: true` parameter, which is designed to generate a Git-style diff. This allows changes to be previewed and verified before executing the final modification with `dryRun: false`.
* **Complete Overwrites:** `write_file` is intended only for the creation of completely new files or situations where the entire contents of an existing file must be intentionally overwritten.
* **Relocation:** `move_file` handles moving or renaming operations. This tool is designed to fail safely if the target destination already exists.

### 4. Managing Directories
* **Folder Creation:** `create_directory` initializes new folders. It automatically generates any missing parent directories in the path and succeeds silently if the requested directory already exists.