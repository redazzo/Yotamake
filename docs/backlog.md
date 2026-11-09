---
kind: reference
status: current
updated: 2026-11-09
owns: [open-work-register]
---

# Backlog

**The** register of open engineering work: everything outstanding that is not already an ADR
or an in-flight branch.

**Format.** One `##` entry per item, each carrying **Added** and a **Trigger to act**: the
observable condition that should make someone pick it up. An item with no trigger is a wish,
not a backlog entry. Items with substantial written analysis keep a detail document in
`backlog/` and link to it from here. An entry may carry **Priority: High**; those sit at the
top.

**Done means gone.** Delete the entry when the work lands, and write a
[record](./records/README.md) if it was worth explaining.

---

## CI is written but not active

**Priority: High** · **Added:** 2026-10-29 · **Trigger to act:** someone who can push under
`.github/workflows/` has a few minutes.

[`docs/ci.yml`](./ci.yml) runs `scripts/check --all`. The GitHub App cannot push under
`.github/workflows/` (re-tried 2026-11-09: GitHub refused the push for lack of the
`workflows` permission), so a person adds it by hand: copy `docs/ci.yml` to
`.github/workflows/ci.yml`, push it to main, and check that the first run passes. Then delete
`docs/ci.yml` and this entry. The workflow pins the Claude Code CLI version; bump that on
purpose.

## Each clone needs the pre-commit hook set up

**Added:** 2026-11-09 · **Trigger to act:** someone starts working in a new clone of this
repository.

The pre-commit hook runs `scripts/check --staged`, but git's `core.hooksPath` setting is local
to a clone and is not cloned. So each person, in each clone, runs `./plugin/install.sh .`
once (or `git config core.hooksPath .githooks`). Until then their commits skip the hook, and
only CI (once active) catches a failing check.

A lasting fix would set it for them, e.g. a plugin `SessionStart` hook that sets
`core.hooksPath` when `.githooks/` exists and nothing else is set. That reaches every
repository using the harness, so it needs its own decision. If it is built, delete this entry.

## "Docs-only" in `simple-session` means any Markdown

**Added:** 2026-11-09 · **Trigger to act:** a session skips design or review on a Markdown
change that is code, here or in another repository.

`simple-session` skips its design and review steps for a branch that "changes only docs
(Markdown files and `docs/`)". In this repository, and in any whose prompts or skills are
Markdown, that skips the steps that matter most. `CLAUDE.md`, How to work here, overrides it
for this repository only. A lasting fix would define docs-only as the docs system's files and
let a named `CLAUDE.md` line widen it. That changes a skill and the template, so it needs a
version bump, an `upgrades.md` entry, the eval fixture's `CLAUDE.md`, and a re-run of
`04-docs-only`. When it lands, drop the override from `CLAUDE.md` and delete this entry.

## Re-check two fixes on the next full eval run

**Added:** 2026-10-29 · **Trigger to act:** the next full suite run
(`claude plugin eval . --scaffold --allow-tools Bash Write Edit --ablation with-without`).

- **`simple-session` could miss when the user names a branch.** After a first fix it fired in
  5 of 6 runs of `02-small-change`. Version 0.7.3 moved the trigger to the front of the skill
  description and said the same in the template `CLAUDE.md`. It then fired in 10 of 10 runs
  (2026-10-29, Claude Code 2.1.312, one model).
- **The review was often skipped.** Before 0.9.0, Claude skipped `/simplify` and
  `/code-review` in about 5 of 6 code-change runs; after it, in 1 of 6, by reading the diff by
  hand. Versions 0.9.1 to 0.9.3 say that reading the diff does not replace the two skills,
  that the review runs once per session, and that a follow-up change gets one more full
  review. Latest runs (2026-10-29): 13-reuse, 02-small-change and 15-follow-up-review passed
  3 of 3 each, with each skill called exactly once per run.

Both look fixed. Delete this entry if the full run agrees.

## Untested paths

**Added:** 2026-10-29 · **Trigger to act:** the next change to one of these paths.

- `spec`: case 12 passed 3 of 3 runs, but nothing tests the question-at-a-time path or the
  hand-over to a session. A recorded history, as in case 15, could test both.
- `simple-session`'s pull-request path has no eval case.
- `setup`'s install step has no eval case (the eval sandbox keeps `.claude/` read-only).
  `scripts/test-install.sh` covers `install.sh` itself.

## No plugin icon

**Added:** 2026-10-29 · **Trigger to act:** `claude plugin validate --strict` turns
`ICON_MISSING` from a warning into an error, or the plugin is listed somewhere public.

## Stale-docs check: designed, not built

**Added:** 2026-10-29 · **Trigger to act:** a reference doc is found wrong in use, and this
check would have flagged it.

A report of reference docs whose code changed after their `updated:` date. Design,
measurements and build plan: [backlog/stale-docs-check.md](./backlog/stale-docs-check.md).
