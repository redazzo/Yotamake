#!/usr/bin/env bash
# The fixture plus a local multi-session folder: S1 done, S2 ready (D1 answered),
# with a docs ledger. Starts on S2's branch, since the sandbox cannot write .git.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh" feat/farewell
d=.scratchpad/2026-10-20-greeter-polish
mkdir -p "$d"
cat > "$d/README.md" <<'MD'
# Greeter polish — working memory

Started 2026-10-20. Small improvements to the greeter, run as sessions.

**Setup:** local. This folder is git-ignored; each session is its own branch cut from `main`.

The user resumes with: **"Read .scratchpad/2026-10-20-greeter-polish/README.md and start the
next session."**

## Files

- `plan.md` — sessions and their status.
- `findings.md` — what the analysis found.
- `decisions.md` — questions for the user and their answers.
- `log.md` — one entry per session.
- `docs.md` — the docs ledger: every change a durable doc must reflect, and whether it is
  done. Close-out works from it.
MD
cat > "$d/plan.md" <<'MD'
# Plan

2 sessions after S0. Status values: `todo`, `in progress`, `done`, `skipped`.

## S0 — Analysis and planning — `done`

## S1 — Trim whitespace in names (F1) — `done`

## S2 — Add a farewell function (F2) — `todo`

Branch: `feat/farewell`

Ask D1 first.

1. Add `farewell(name)` to `src/greet.js`, worded per D1, with a test.
2. Update the docs that own what changed, and add this session's rows to `docs.md`.
3. `scripts/check` and the review, then propose commit and merge.

✂ **Clear context.**
MD
cat > "$d/findings.md" <<'MD'
# Findings

**F1 — Names are not trimmed (low).** `greet("  Ada ")` keeps the spaces. Closed in S1.

**F2 — No farewell (low).** Users asked for a matching `farewell(name)`.
MD
cat > "$d/decisions.md" <<'MD'
# Decisions

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D1 | S2 | How should `farewell` word it: "Goodbye, Ada." or "Bye, Ada."? Recommendation: "Goodbye, Ada.", to match the formal greeting. | "Goodbye, Ada." (2026-10-21) |
MD
cat > "$d/log.md" <<'MD'
# Log

## 2026-10-20 — S0: analysis

- Two findings (F1, F2). Plan written.

## 2026-10-21 — S1: trim whitespace

- Decided to leave trimming out: the user prefers callers to pass clean names. No code change.
- D1 answered: "Goodbye, Ada."
- Next: S2.
MD
cat > "$d/docs.md" <<'MD'
# Docs ledger

Every change a durable doc must reflect, logged by the session that made it. Close-out
works through this file; nothing here may be left `open` when the folder is deleted.

Status values: `done` (the doc was changed in that session), `open` (still to do; say who
does it), `none` (checked; no doc needs it, and why).

## Changes

| Session | What changed | Doc that owns it | Status |
|---|---|---|---|
| S1 | Trimming dropped; `greet` unchanged | — | none (no behaviour changed) |

## Renames and removals

Old names that docs may still use. Close-out greps `docs/` and CLAUDE.md for each one.

| Session | Old name | New name, or "removed" |
|---|---|---|

## For close-out

- **Record:** S1: trimming dropped by the user's choice.
- **Backlog:** none yet.
- **ADR candidates:** none.
MD
