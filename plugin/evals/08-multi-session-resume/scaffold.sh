#!/usr/bin/env bash
# The fixture plus a local multi-session folder: S1 done, S2 waits on decision D1.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"
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
2. Update `docs/reference/greeting.md`.
3. `scripts/check` and the review, then propose commit and merge.

✂ **Clear context.**
MD
cat > "$d/findings.md" <<'MD'
# Findings

**F1 — Names are not trimmed (low).** `greet("  Ada ")` keeps the spaces. Fixed in S1.

**F2 — No farewell (low).** Users asked for a matching `farewell(name)`.
MD
cat > "$d/decisions.md" <<'MD'
# Decisions

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D1 | S2 | How should `farewell` word it: "Goodbye, Ada." or "Bye, Ada."? Recommendation: "Goodbye, Ada.", to match the formal greeting. | — |
MD
cat > "$d/log.md" <<'MD'
# Log

## 2026-10-20 — S0: analysis

- Two findings (F1, F2). Plan written.

## 2026-10-21 — S1: trim whitespace

- Decided to leave trimming out after all: the user prefers callers to pass clean names.
  Marked done with no code change.
- Next: S2. Ask D1 first.
MD
