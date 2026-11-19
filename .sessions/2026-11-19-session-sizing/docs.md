# Docs ledger

Every change a durable doc must reflect, logged by the session that made it. Close-out
works through this file; nothing here may be left `open` when the folder is deleted.

Status values: `done` (the doc was changed in that session), `open` (still to do; say who
does it), `none` (checked; no doc needs it, and why).

## Changes

| Session | What changed | Doc that owns it | Status |
|---|---|---|---|
| S1 | New session definition decided: review, revert, decisions; context as backstop; signals; limit as project fact; mid-session stop; ADR first | `docs/decisions/0011-session-sized-by-review-revert-and-decisions.md` (Proposed; user accepts at the end) | done |
| S1 | ADR index gains 0011 | `docs/decisions/README.md` | done |
| S1 | ADR-0011 status Proposed → Accepted once the user accepts it | `docs/decisions/0011-…` and `docs/decisions/README.md` | open (close-out) |
| S2 | New `**Session size:**` line (default about 400 changed lines or 15 files) in **Branching and releases**; "How to work here" points to `simple-session`, "Check the size" (D7) | `plugin/template/CLAUDE.md`, `CLAUDE.md`, `plugin/evals/_fixture/files/CLAUDE.md` | done |
| S2 | Older installs get the line and the wording | `plugin/reference/upgrades.md` (0.38.0 entry) | done |
| S2 | Installer test checks the installed line | `scripts/test-install.sh` | done |
| S2 | Site lists what **Branching and releases** holds | `site/get-started.html` | done |
| S2 | README names the `Session size` line where it names `Worktree setup` and `Docs-only` | `README.md` | open (S6) |
| S2 | Doctor: no change; the filled default has no `FILL IN`. A repository whose version is older than 0.38.0 and lacks the line fails step 2 (pending upgrade), as for any pending entry | `plugin/skills/doctor/SKILL.md` | none |
| S2 | Template "Work that spans several contexts" convention still sizes by context | `plugin/template/CLAUDE.md` | open (S4, task 4a) |
| S2 | `/yotamake:setup` keeps the line's default unless the user names another | `plugin/skills/setup/SKILL.md` | done |
| S2 | Changelog line for the new line and wording | `CHANGELOG.md` (`## Unreleased`) | done |

## Renames and removals

Old names that docs may still use. Close-out greps `docs/` and CLAUDE.md for each one.

| Session | Old name | New name, or "removed" |
|---|---|---|

## For close-out

- **Record:** —
- **Backlog:** middle tier between simple-session and multi-session (D0).
- **ADR candidates:** the session definition (S1, D1).
