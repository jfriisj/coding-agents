# Python Code Analysis & Linting

When reviewing Python code, use `execute/runInTerminal` to run these specific tools. Ensure you are running them from within the project's virtual environment if one exists (e.g., `uv run ruff check`).

## 1. Ruff (Linting & Complexity)
Ruff replaces Flake8, Black, and McCabe.

* **Check specific files:** `ruff check path/to/file.py`
* **Check complexity:** `ruff check --select C901 path/to/file.py` (Warns if complexity is > 10)
* **Format code (Auto-fix):** `ruff format path/to/file.py`

## 2. Vulture (Dead Code Detection)
Vulture finds unused classes, functions, and variables.

* **Scan a file/directory:** `vulture path/to/scan/`
* **Ignore test files:** If scanning a broad directory, ignore tests: `vulture path/to/scan/ --exclude '*test*'`