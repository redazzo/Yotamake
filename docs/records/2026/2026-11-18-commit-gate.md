---
kind: record
date: 2026-11-18
status: current
---

# Commit gate on session steps

**Date:** 2026-11-18 · **Status:** open, on `feat/commit-gate`; released as 0.37.0 when it
merges into `main` · **Design:** [ADR-0010](../../decisions/0010-commit-gate-by-step-table.md)
(Proposed; the user accepts it with the effort's report).

Sessions sometimes committed before `scripts/check` or the review had run on the final diff.
Each miss had been fixed with more skill wording, and `simple-session` was at 245 of its 250
lines. The backlog entry "Enforce the session steps in order with hooks" asked for a hook to
refuse the commit instead. It ran as a six-session effort (S1 to S6) on autopilot, one commit
per session on the mother branch.

How it works now: [README.md](../../../README.md), "Claude cannot end a turn with unchecked
code" and "Claude cannot commit before the check and the review", and ADR-0010. This record
holds what was built, in what order, and what was decided on the way.

## What was built

| Step | Branch | Commit | What |
|---|---|---|---|
| S1 | none | — | A probe: four headless `claude -p` runs with a hook that logged every event. No repository file changed |
| S2 | `feat/commit-gate` | `0ddd182` | ADR-0010 (Proposed) and its row in the decisions index; the backlog entry pointed at it |
| S3 | `feat/commit-gate` | `1a10741` | `plugin/hooks/steps.json` (the step table) and `steps.mjs` (the evaluator, with the docs classifier moved out of `post-edit-mark.sh`); the per-worktree events log `yotamake-events`; `post-edit-mark.sh` logs edits; `stop-check-ran.sh` decides through the evaluator; ADR-0008 amendment; CLAUDE.md Style, Shared code and Patterns |
| S4 | `feat/commit-gate` | `6b77a2b` | The commit gate in `pre-bash-git.sh`, with the commit message read from `-m`, `-F` and heredocs for the `Review-skipped:` trailer; `record-event.sh` for review and prompt events, registered in `hooks.json`; `mainOnly` on the stop row; `integrate.md` runs the check before the bump commit and adds the trailer; README, site pages, CHANGELOG |
| S5 | `feat/commit-gate` | `e8827c1` | `simple-session` proposes `Review-skipped: trivial` for a trivial branch; `integrate.md` says to do the step a refusal names; the old `yotamake-edited` marker removed; backlog cleaned up |
| S6 | `feat/commit-gate` | — | Close-out: ADR-0007 amendment, glossary, this record, backlog check |

Tests: `scripts/test-hooks.sh` feeds the evaluator event sequences through the real hooks
(the `seq` helper: check and review order, the review window, task notifications, docs-only
and trailer skips, subagent events, an unreadable log, no merge base). Its commit-gate cases
run `pre-bash-git.sh` on real commands for spec A1–A4 and A9, merges, `MERGE_HEAD` and the
message forms. A parity test keeps `readFact` in `steps.mjs` equal to `read_fact` in
`lib.sh`. The existing `Stop` gate cases pass unchanged.

## Decisions taken along the way

Under autopilot, D9 and D10 took the recommended answer (`assumed`). The user answered D11.
D1–D8 were accepted with the plan.

- **Events keyed by worktree, not by session (D2).** A subagent's edits and reviews count for
  the checkout they touched, whatever its session id. Rejected: state keyed by `session_id`.
- **"Check passed" from the existing stamp (D3).** Each edit event records the stamp's mtime
  it saw; the check counts when the stamp is newer now. No clock compare, and the
  project-owned `scripts/check` does not change.
- **A `Review-skipped: <reason>` trailer (D4)** for a trivial branch and the release bump,
  so the skip is in history. Only the commit's own message counts: the review found that
  searching the whole command let `echo 'Review-skipped: x'; git commit -m y` through.
- **The gate in the plugin's `pre-bash-git.sh` (D5)**, leaving ADR-0006 Proposed and
  separate. The evaluator is dependency-free Node (D6).
- **Edits made through Bash are a known limit (D7)**, not a diff of the worktree on each
  commit.
- **A review window, not "reviews after the last edit" (D9).** The probe showed that rule
  would refuse every reviewed commit whose review led to a fix. The window starts at the
  later of the last commit and the last user prompt before the last code edit.
- **Review events from both `PreToolUse` on `Skill` and `UserPromptExpansion` (D10).** The
  probe showed a typed `/simplify` fires only the second.
- **A second `project.conf` reader in Node (D11).** ADR-0010 amends ADR-0008 item 4 rather
  than have the bash hooks resolve facts and pass them in, which would cost one more Node
  start per hook call.
- **Subagent edits do not count for the `Stop` gate (`mainOnly`).** A background agent's
  edits blocked the main conversation's turns; the commit gate still counts them. This
  closed a backlog line and changed ADR-0010 item 6 from S2's text.

## Changes from the plan

- S5 planned to cut the wording in `simple-session` that the gate enforces. The review undid
  the cut: with the plugin off, the gate sees nothing, so the wording still carries the
  rule. Only the trailer line was added (245 to 246 lines).
- The line telling Claude to do the step a refusal names went into `integrate.md`, which
  owns committing, not into `simple-session`.
- The "Two gaps left in the `Stop` gate" backlog entry lost one gap: each event names its
  session, so two sessions editing one tree no longer clash.

## What is left

- Accept ADR-0010 — the user, with the effort's report.
- An eval case that commits — [backlog entry](../../backlog.md#an-eval-case-for-the-commit-gate-and-the-stop-gate)
- Edits made through Bash get past the gates — [backlog entry](../../backlog.md#shell-commands-get-past-the-edit-hooks)
- An edit into a separate repository by absolute path gets past the `Stop` gate — [backlog entry](../../backlog.md#a-gap-left-in-the-stop-gate)
