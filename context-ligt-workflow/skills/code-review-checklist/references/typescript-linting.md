# TypeScript / Node.js Code Analysis & Linting

When reviewing TypeScript or JavaScript code, use `execute/runInTerminal` to run the project's configured tools.

## 1. ESLint (Linting & Complexity)
* **Run standard checks:** `npm run lint` or `npx eslint path/to/file.ts`
* **Auto-fix issues:** `npx eslint --fix path/to/file.ts`

## 2. TypeScript Compiler (Type Checking)
Ensure the code actually compiles without errors before approving.
* **Run type check:** `npx tsc --noEmit`

## 3. Prettier (Formatting)
* **Check formatting:** `npx prettier --check path/to/file.ts`
* **Fix formatting:** `npx prettier --write path/to/file.ts`