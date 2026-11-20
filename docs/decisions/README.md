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
- **Proposed** — under discussion. Listed with the ADRs in force until it is accepted or
  withdrawn.
- **Superseded** — replaced by a later ADR, which its Status line links. The old one stays.
- **Withdrawn** — a proposal dropped before it was accepted. It stays, and its Status line
  says why.

## Supersede or amend

An ADR is never edited to reflect a change of mind. A dated amendment section at the end,
or a later ADR's **Amends** line, may correct a detail or add one. Write a new ADR that
states the whole decision as it now stands, and supersedes the old one, when the change
would:

- replace one of the old ADR's numbered decisions; or
- be its third amendment.

Then a reader finds the decision in one file, not spread over several amendments.

## Index

Each row's status matches the ADR's Status line. `scripts/check` fails when they differ
(`adr index`).

### In force

| ADR | Title | Status |
|-----|-------|--------|
| [0001](./0001-harness-owned-and-project-owned-files.md) | Template files are either harness-owned or project-owned | Accepted |
| [0002](./0002-project-facts-in-named-claude-md-sections.md) | Skills read project facts only from named CLAUDE.md sections | Accepted |
| [0003](./0003-stop-points-enforced-by-ask-rules.md) | Stop points are enforced by permission ask rules | Accepted |
| [0004](./0004-project-session-start-hook-sets-hooks-path.md) | A project SessionStart hook points git at .githooks/ when nothing else is set | Accepted |
| [0005](./0005-parallel-sessions-in-worktrees.md) | Independent sessions of one effort may run in parallel worktrees | Accepted |
| [0006](./0006-commit-stop-by-project-hook.md) | A project hook asks before commits, in place of the `ask` rule | Proposed |
| [0007](./0007-autopilot-runs-sessions-in-subagents.md) | Autopilot runs an approved effort's sessions in subagents on one branch | Accepted |
| [0008](./0008-facts-hooks-read-in-project-conf.md) | Hooks and scripts read their project facts from `.claude/yotamake/project.conf` | Accepted |
| [0009](./0009-autopilot-is-the-default.md) | Autopilot is the default for a multi-session effort once S0 is approved | Accepted |
| [0010](./0010-commit-gate-by-step-table.md) | A plugin hook refuses `git commit` until the check and the review are done, by one step table | Accepted |
| [0011](./0011-session-sized-by-review-revert-and-decisions.md) | A session is sized by review, revert and decisions, with context as a backstop | Accepted |

### Superseded and withdrawn

| ADR | Title | Status |
|-----|-------|--------|
| — | _None yet._ | — |

## Template

File: `docs/decisions/NNNN-<kebab-slug>.md`, numbered one above the highest here. Add a row
under "In force" above. Start from the decision template of the `write-doc` skill
(`templates/decision.md` in the skill). It says how to supersede or amend an ADR later.
When an ADR is superseded or withdrawn, move its row to the second table with its new
status, e.g. `Superseded by [NNNN](./NNNN-<slug>.md)`.

Older ADRs may have one `**Supersedes / amends:**` line. It means the same as the template's
separate **Supersedes** and **Amends** lines.
