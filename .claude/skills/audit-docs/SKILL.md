---
description: Audit project documentation for accuracy against the actual codebase. Checks SKILL.md, ARCHITECTURE.md, and README.md for outdated references, missing items, redundancy, and inconsistencies. Use this skill when the user asks to "audit", "sanity check", "review docs", "check if docs are up to date", or "cleanup docs". Also use when the user says things like "is the skill file still accurate" or "anything outdated in the docs".
argument-hint: [which files to audit, or blank for all]
---

# Documentation Audit

Audit the project's key documentation files against the actual codebase to find outdated info, missing references, redundancy, and cross-file inconsistencies.

## Files to audit

1. `.claude/skills/flowbar-dev/SKILL.md` — development guide, coding rules, architecture, pitfalls
2. `ARCHITECTURE.md` — codemap, data flows, invariants
3. `README.md` — user-facing description, features, build instructions

If the user specifies particular files, audit only those. Otherwise audit all three.

## Audit process

### 1. Read all doc files first
Read all three files (or the ones requested) in parallel to understand what's documented.

### 2. Explore the codebase
Use an Explore agent to verify claims against reality. Check:

- **Referenced files/types/functions** — do they still exist? Are names correct?
- **Directory structure** — does the documented tree match the actual filesystem?
- **Enums and constants** — do documented values (AccentColor cases, ActivePanel cases, etc.) match the code?
- **Services and their responsibilities** — is the documented behavior accurate?
- **Build commands** — do schemes, targets, and flags match project.yml/xcodeproj?
- **Test structure** — do documented test files/directories exist?
- **UI element identifiers** — do accessibility IDs in docs match the views?

### 3. Cross-check between files
The three files describe the same project from different angles. Look for:

- **Contradictions** — e.g., ARCHITECTURE.md says X but SKILL.md says Y
- **Redundancy** — same info repeated across files that could drift out of sync
- **Coverage gaps** — something in one file that should be in another (e.g., a new service in ARCHITECTURE.md but missing from SKILL.md's architecture section)

### 4. Check for internal issues
Within each file:

- **Broken sentences or grammar** — incomplete thoughts, dangling clauses
- **Stale pitfalls** — warnings about things that no longer apply
- **Verbose sections** — anything that could be said in fewer words without losing meaning
- **Redundancy within the file** — same rule stated multiple ways

## Output format

Present findings grouped by file, with a clear verdict for each:

```
## SKILL.md
- [outdated] FlowbarSegmentedControl referenced on line 121 — doesn't exist in codebase
- [redundant] Accent color rule repeated in Views, Design Preferences, and Pitfall #11
- [stale] Pitfall #1 about xcodebuild -runFirstLaunch — rare edge case, adds noise

## ARCHITECTURE.md
- [missing] NewService not documented
- [outdated] Codemap shows old directory structure

## README.md
- (looks good, no issues found)

## Cross-file issues
- SKILL.md references ARCHITECTURE.md but the file was deleted
```

Categories: `[outdated]` `[missing]` `[redundant]` `[stale]` `[inconsistent]` `[broken]`

After presenting findings, ask the user which ones to fix, then apply the changes.

---

Now, help the user with: $ARGUMENTS
