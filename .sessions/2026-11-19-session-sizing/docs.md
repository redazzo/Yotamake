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

## Renames and removals

Old names that docs may still use. Close-out greps `docs/` and CLAUDE.md for each one.

| Session | Old name | New name, or "removed" |
|---|---|---|

## For close-out

- **Record:** —
- **Backlog:** middle tier between simple-session and multi-session (D0).
- **ADR candidates:** the session definition (S1, D1).
