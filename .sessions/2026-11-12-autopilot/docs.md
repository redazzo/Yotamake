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
| S1 | The review runs in the main conversation under autopilot (D4); a session brief must not rely on the subagent starting agents | `plugin/skills/multi-session/SKILL.md`, "Autopilot" | done (S2) |
| S2 | Autopilot: turning it on, mother branch (D6), per-session loop, the main conversation commits (D5), session brief, pauses, `assumed` decisions, close-out keeps the folder, report, merge question, delete-bump-merge order (D8), resuming | `plugin/skills/multi-session/SKILL.md`, "Autopilot" | done |
| S2 | S0's end message offers autopilot; "Resuming" and "Rules for every session" point to it; S0 leaves out `report.md` | `plugin/skills/multi-session/SKILL.md` | done |
| S2 | Templates: autopilot setup and resume lines; `assumed` answers; new `report.md` | `plugin/skills/multi-session/templates/` | done |
| S2 | `simple-session`, "Stop and report": autopilot rules come first | `plugin/skills/simple-session/SKILL.md` | done |
| S2 | Overview of autopilot for users | `README.md` (Sessions) | open (S3) |
| S2 | ADR-0007 decision 1 says autopilot is turned on "at the end of S0 or when resuming"; the skill matches | `docs/decisions/0007-…` | none (already says so) |
| S2 | The end's order changed by D8 (report and question before the folder delete and the bump): dated amendment | `docs/decisions/0007-autopilot-runs-sessions-in-subagents.md` | done |

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
- **Record:** S2 wrote `multi-session`, "Autopilot", the `report.md` template and the
  `assumed` answer; amended ADR-0007 for the order of the end (D8).
- **Backlog:** autopilot's main conversation grows by one review per session and may compact
  on a long run; trigger: a run that compacts. Option: hand review fixes to a fix agent.
- **Backlog:** test whether a subagent's edit marks the parent session for the `Stop` gate
  (F8), in a session where the plugin's hooks run (S1 could not).
