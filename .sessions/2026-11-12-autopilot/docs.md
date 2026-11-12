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
| S1 | ADR-0007 Accepted; test results in its "Tested" section; the main conversation runs each session's review (D4) | `docs/decisions/0007-autopilot-runs-sessions-in-subagents.md` | done |
| S1 | ADR-0007 status in the index | `docs/decisions/README.md` | done |
| S1 | ADR-0005 amended for autopilot | `docs/decisions/0005-parallel-sessions-in-worktrees.md` | done |
| S1 | The review runs in the main conversation under autopilot (D4); a session brief must not rely on the subagent starting agents | `plugin/skills/multi-session/SKILL.md`, "Autopilot" | open (S2) |

## Renames and removals

Old names that docs may still use. Close-out greps `docs/` and CLAUDE.md for each one.

| Session | Old name | New name, or "removed" |
|---|---|---|

## For close-out

- **Record:** S0 planned autopilot: one approval of the plan, sessions in subagents on one
  mother branch, one report and one merge question at the end.
- **Backlog:** "Spawn worktree sessions from the main conversation" — update it to point at
  ADR-0007 (S4).
- **ADR candidates:** ADR-0007 (S0, D1–D3), Accepted in S1.
- **Backlog:** test whether a subagent's edit marks the parent session for the `Stop` gate
  (F8), in a session where the plugin's hooks run (S1 could not).
