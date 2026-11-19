---
kind: record
date: 2026-11-19
status: current
---

# Session sizing by review, revert and decisions

**Date:** 2026-11-19 · **Status:** open, on the mother branch; released as 0.38.0 on merge ·
**Design:** [ADR-0011](../../decisions/0011-session-sized-by-review-revert-and-decisions.md)
(Proposed; the user accepts it with the effort's report).

The size check called a change "too big for one session" by five fixed structural tests and
by whether it fits one context. Context seldom binds for current models, and the tests both
blocked changes that fit (a schema change plus its code) and passed ones too big to review.
The backlog entry "The size check can misjudge a change" had asked to collect cases first;
the user chose to act now. It ran as a six-session effort (S1 to S6) on autopilot, one commit
per session on the assigned branch, with S0 planning it.

How it works now: [`simple-session`](../../../plugin/skills/simple-session/SKILL.md), "Check
the size" and "Stop partway"; [README.md](../../../README.md), "Sessions"; and ADR-0011.
This record holds what was built, in what order, and what was decided on the way.

## What was built

| Step | Branch | Commit | What |
|---|---|---|---|
| S0 | `ccr-670642ff-1n2a64` | `657bd24` | Analysis (findings F1–F14), spec A1–A9, plan S1–S6 |
| S1 | `ccr-670642ff-1n2a64` | `2f8f36d` | ADR-0011 (Proposed) and its row in the decisions index |
| S2 | `ccr-670642ff-1n2a64` | `43e3906` | A `**Session size:**` line (about 400 changed lines or 15 files) in **Branching and releases** of the template, the eval fixture and this repository's `CLAUDE.md`; "How to work here" points to `simple-session`, "Check the size"; `upgrades.md` 0.38.0 entry; a `scripts/test-install.sh` step; a `setup` sentence; a site line |
| S3 | `ccr-670642ff-1n2a64` | `213e8c7` | `simple-session`: new definition and description; "Check the size" with a one-line estimate, the limit and its stated default, the signals, context as a backstop, an ADR landed first; "Stop partway" in "Do the work" (also pointed to from `debugging`); the estimate beside the real size in the report. Glossary "Session". Lite-install docs path moved to `plugin/reference/missing-setup.md` to keep the skill at 250 lines |
| S4 | `ccr-670642ff-1n2a64` | `6810101` | `multi-session`: description, definition and S0 step 4 size sessions by "Check the size"; a rule to split a session that stops partway once the user agrees; `plan.md` template; `autopilot.md` returns `PAUSE: size` and the main conversation makes the split; template **Conventions** "Work too big for one session", with an upgrade step |
| S5 | `ccr-670642ff-1n2a64` | `179a188` | Eval case `24-should-fit` (a nullable column plus the code and doc that use it runs as one session, with an estimate) and its README row; the "separate changes" signal tightened in the skill, ADR-0011 and the spec |
| S6 | `ccr-670642ff-1n2a64` | `c438220` | README "Sessions" and skill tree; `site/how-it-works.html` (the five old tests replaced by one line and a link), `skills.html`, `get-started.html`; backlog entries |
| Close-out | `ccr-670642ff-1n2a64` | — | This record, ADR-0011's work record line, ledger check |

Tests: `scripts/test-install.sh` checks that the installed `CLAUDE.md` has a filled
`Session size` line under **Branching and releases**. `scripts/consistency.mjs` checks the
README eval table and quoted step names. Eval cases `03-too-big` (still too big: separately
shippable API, CLI and database) and `24-should-fit` cover the check; neither was run (they
cost money).

## Decisions taken along the way

D0 and D6 are the user's answers. Under autopilot, D1–D5 and D7 took the recommended answer
(`assumed`), for the user to confirm with the report.

- **No middle tier (D0, user).** A lighter tier between the two session skills (one branch,
  a step list, a commit per step, no folder) was left out; it is a backlog entry.
- **Autopilot for S1–S6 (D6, user).**
- **An ADR for the definition (D1, assumed).** ADR-0011, Proposed. The definition sits in
  about ten files and gates a skill. ADR-0007 still holds; ADR-0011 builds on it.
- **The limit as a bold `**Session size:**` line in Branching and releases (D2, assumed)**,
  like `**Test-first:**`. Rejected: a new `##` section; `project.conf` (no hook reads it).
- **No hook warns on diff size (D3, assumed).** Skill text only; a non-blocking hook is a
  backlog entry, since it would be a new kind of rule under ADR-0010.
- **Default limit about 400 changed lines or 15 files, not counting lockfiles and generated
  files (D4, assumed).** A judgment from common review guidance, not measured for model
  reviewers.
- **The heading "Check the size" stays (D5, assumed)**, so pointers by name stay valid.
- **The `CLAUDE.md` copies point to the skill instead of restating the definition (D7,
  assumed).** One owner per subject, and no upgrade step for each later rewording.
- **The skill states the default number itself**, rather than pointing at the template: the
  S3 design read found the pointer clashed with ADR-0002 and ADR-0011 §4.
- **The split is made by the main conversation, and the rule lives in `multi-session`** (S4),
  so a step-through effort can split too.

## Changes from the plan

- A7 asked autopilot's pause rule to name the new triggers *instead of* "cannot finish within
  its plan". S4 added `PAUSE: size` with the named triggers and kept the old phrase as a
  general trigger beside it.
- A1's "same wording" in the three `CLAUDE.md` copies became a pointer to the skill (D7).
  The glossary states the definition in short and points to the skill (close-out added
  "with its decisions settled first").
- S5 reworded the signal "parts that could ship on their own" to "bundles separate changes
  that could each ship, and be reviewed, alone", since the old wording could fairly fire on
  a column plus its code.
- S3 and S4 did not write their own estimate before starting; S5 and S6 did (S5: about 11
  files, +80, real 13 files, +115; S6: about 7 files, +70/−40, real about 7, +70/−25).
- `simple-session` is at exactly its 250-line cap.

## What is left

- Accept ADR-0011 — the user, with the effort's report.
- Run eval cases `03-too-big` and `24-should-fit` — the user decides (they cost money).
- The size check can still misjudge a change — [backlog entry](../../backlog.md#the-size-check-can-misjudge-a-change)
- A size warning hook — [backlog entry](../../backlog.md#size-warning-hook)
- A middle tier between the two session skills — [backlog entry](../../backlog.md#a-middle-tier-between-the-two-session-skills)
- The review window restarted during a cloud autopilot run — [backlog entry](../../backlog.md#the-review-window-restarted-during-a-cloud-autopilot-run)
