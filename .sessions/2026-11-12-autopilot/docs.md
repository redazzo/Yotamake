# Docs ledger

Every change a durable doc must reflect, logged by the session that made it. Close-out
works through this file; nothing here may be left `open` when the folder is deleted.

Status values: `done` (the doc was changed in that session), `open` (still to do; say who
does it), `none` (checked; no doc needs it, and why).

## Changes

| Session | What changed | Doc that owns it | Status |
|---|---|---|---|
| S0 | A conversation may drive session subagents, under autopilot only | `docs/decisions/0007-autopilot-runs-sessions-in-subagents.md` (Proposed) | done |
| S0 | ADR index row for ADR-0007 | `docs/decisions/README.md` | done |

## Renames and removals

Old names that docs may still use. Close-out greps `docs/` and CLAUDE.md for each one.

| Session | Old name | New name, or "removed" |
|---|---|---|

## For close-out

- **Record:** S0 planned autopilot: one approval of the plan, sessions in subagents on one
  mother branch, one report and one merge question at the end.
- **Backlog:** "Spawn worktree sessions from the main conversation" — update it to point at
  ADR-0007 (S4).
- **ADR candidates:** ADR-0007 (S0, D1–D3).
