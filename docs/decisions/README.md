# Architecture Decision Records (ADRs)

This directory records the **architecturally significant decisions** behind the project: the
choices that are load-bearing, costly to reverse, and that constrain how the rest of the
system is built. Each ADR captures one decision, the alternatives considered, and the
trade-offs accepted, so future contributors can see which invariants are deliberate.

**The bar.** Write an ADR when reversing the choice later would mean touching many files,
migrating data, or breaking callers. A local implementation choice belongs in a record, not
here. Ask the user before writing one.

## Status legend

- **Accepted** — in force; the system is built this way today.
- **Superseded** — replaced by a later ADR. The old one stays.
- **Proposed** — under discussion.

An ADR is never edited to reflect a change of mind. It is superseded by a new one, or given a
dated amendment section at the end.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](./0001-harness-owned-and-project-owned-files.md) | Template files are either harness-owned or project-owned | Accepted |
| [0002](./0002-project-facts-in-named-claude-md-sections.md) | Skills read project facts only from named CLAUDE.md sections | Accepted |
| [0003](./0003-stop-points-enforced-by-ask-rules.md) | Stop points are enforced by permission ask rules | Accepted |
| [0004](./0004-project-session-start-hook-sets-hooks-path.md) | A project SessionStart hook points git at .githooks/ when nothing else is set | Accepted |
| [0005](./0005-parallel-sessions-in-worktrees.md) | Independent sessions of one effort may run in parallel worktrees | Accepted |
| [0006](./0006-commit-stop-by-project-hook.md) | A project hook asks before commits, in place of the `ask` rule | Proposed |
| [0007](./0007-autopilot-runs-sessions-in-subagents.md) | Autopilot runs an approved effort's sessions in subagents on one branch | Accepted |

## Template

File: `docs/decisions/NNNN-<kebab-slug>.md`, numbered one above the highest here. Add a row
to the index above.

```markdown
---
kind: decision
date: YYYY-MM-DD
status: current
---

# ADR-NNNN: <Decision as a short statement>

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Work record:** <link, if any>
- **Supersedes / amends:** <links, if any>

## Context

<What forced a choice. The constraints. Say so if the rationale is inferred from the code.>

## Decision

In the context of <use case or component>, facing <concern>, we decided for <option> (and
against <alternatives>) to achieve <quality>, accepting that <downside>.

## Consequences

<What becomes easier, what becomes harder, what is now forbidden.>

## References

<Files, records, issues.>
```

Use `status: superseded` in the front-matter when a later ADR replaces this one.
