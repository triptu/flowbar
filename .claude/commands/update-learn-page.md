Update the interactive learning guide at `Flowbar/docs/learn-swift.html` to reflect recent codebase changes. Don't include details about before state, write as if there was no change, just present the updated state of the code and concepts.

## What to do

1. **Read recent git history** — Run `git log --oneline -10` and `git diff HEAD~1 --stat` (or a specific commit range if provided as $ARGUMENTS) to identify what Swift source files changed and how.

2. **Read the changed Swift source files** — Get the current content of every `.swift` file that was modified.

3. **Read the learn-swift.html file** — It contains several data sections that must stay in sync with the actual code:

   - **`FILES` object** (~line 1742) — Embedded source code for each Swift file, shown in the interactive file explorer. These must match the actual source files exactly (with `\(` escaped as `\\(`).

   - **`ANNOTATIONS` object** (~line 2399) — Line-numbered annotations explaining Swift concepts. Line numbers must match the code in `FILES`. If code shifted, update the line numbers. If concepts changed (e.g., `@Published` → plain `var`), update titles and descriptions.

   - **`CONCEPTS` array** (~line 2657) — Swift concept reference cards with example code snippets. Update any examples that reference changed patterns.

   - **`NODE_TOOLTIPS` object** (~line 3150) — Architecture diagram hover descriptions. Update if a component's role or implementation changed.

   - **Architecture "Why it's built this way"** (~line 990) — Prose explaining design decisions. Update if the rationale changed.

   - **Syntax highlighter** (~line 2789) — Property wrapper regex, keyword list, and type list. Add any new keywords/types introduced.

4. **Make targeted edits** — Only change what's needed. Don't rewrite the whole file. Use the Edit tool for each change.

5. **Verify** — After editing, grep for any stale references that should have been updated (e.g., old class names, removed patterns still referenced in annotations).
