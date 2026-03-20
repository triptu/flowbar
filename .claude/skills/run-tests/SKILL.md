---
name: run-tests
description: Run Flowbar tests. Use this skill whenever the user asks to run tests, check tests, verify tests pass, or test the app. Defaults to unit tests only. Supports "run all tests" (unit + UI), "run ui tests" (UI only), or "run unit tests" (unit only).
argument-hint: [all | ui | unit]
---

# Run Tests

Run Flowbar's test suites via the test script.

## Determine which tests to run

Based on what the user said, pick the right flag:

| User says | Flag |
|---|---|
| "run tests", "check tests", "test it" | `--unit` (default) |
| "run all tests", "also run ui tests", "run everything" | `--all` |
| "run ui tests", "only ui tests" | `--ui` |
| "run unit tests", "only unit tests" | `--unit` |

## Run

```bash
bash .claude/skills/run-tests/scripts/run-tests.sh <flag>
```

Examples:
```bash
# Unit tests only (default)
bash .claude/skills/run-tests/scripts/run-tests.sh

# All tests
bash .claude/skills/run-tests/scripts/run-tests.sh --all

# UI tests only
bash .claude/skills/run-tests/scripts/run-tests.sh --ui
```

## Notes

- Unit tests use Swift Testing (`FlowbarTests` target)
- UI tests use XCTest (`FlowbarUITests` target) and are slower (~3s per launch cycle)
- UI tests require screen access and will interact with the UI
