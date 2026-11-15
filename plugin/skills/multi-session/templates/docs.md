# Docs ledger

Every change a durable doc must reflect, logged by the session that made it. Close-out
works through this file; nothing here may be left `open` when the folder is deleted.

Status values: `done` (the doc was changed in that session), `open` (still to do; say who
does it), `none` (checked; no doc needs it, and why).

## Changes

| Session | What changed | Doc that owns it | Status |
|---|---|---|---|
| S1 | <behaviour, rule or interface that changed> | `docs/reference/<file>.md` | done |

## Renames and removals

Old names that docs may still use. Close-out greps `docs/` and CLAUDE.md for each one.

| Session | Old name | New name, or "removed" |
|---|---|---|
| S1 | `<old>` | `<new>` |

## For close-out

- **Record:** <what was built and why, in a line per session, for the record in `docs/records/`,
  written from `write-doc`'s record template>
- **Backlog:** <follow-ups found along the way, each with its trigger>
- **ADR candidates:** <decisions that may meet the ADR bar, with the session and the D-ID>
