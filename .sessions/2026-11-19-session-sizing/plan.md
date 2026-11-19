# Plan

6 sessions after S0. Clear context between them (marked ✂). Each session is one set of
commits on the assigned branch `ccr-670642ff-1n2a64`, small enough to finish in one context.
Order: the ADR first so later sessions follow it; the `CLAUDE.md` line before the skill that
reads it; `simple-session` (the owner) before `multi-session` and autopilot that point at it;
the eval once the rule is written; README, site and backlog last so they describe the final
state. One version bump (minor, 0.38.0) at the end, as autopilot says.

Status values: `todo`, `in progress`, `done`, `skipped`.

## Design

- **Style:** stays a plugin of Markdown skills, shell hooks and a copy-in template. The size
  rule stays in skill text; no hook and no `steps.json` rule (D3). The limit is a project fact
  in a named `CLAUDE.md` line, read by the skill with a stated default (Boundaries: skills
  read project facts only from named `CLAUDE.md` sections).
- **Modules touched:** `plugin/skills/` (simple-session, multi-session and its `plan.md`
  template, doctor if needed); `plugin/reference/` (autopilot.md, upgrades.md,
  harness-upgrades.md pointer check); `plugin/template/CLAUDE.md`; `plugin/evals/` (new case,
  fixture `CLAUDE.md`); `scripts/test-install.sh`; docs (glossary, ADR, backlog, README);
  `site/`.
- **Reused:** the `**Test-first:**` pattern (filled default line, upgrade entry) for
  `**Session size:**`; the existing heading "Check the size" (D5); autopilot's `PAUSE`
  channel for the mid-session stop; case 03's layout and the shared graders for the new case.
- **New:** one `CLAUDE.md` line; ADR-0011; eval case 24. No new script, hook, interface or
  dependency.
- **Boundaries and constraints at risk:** the plugin stays generic: the limit is a project
  fact with a default, not a stack-specific rule. The installer does not overwrite the
  project-owned `CLAUDE.md`; older installs get the line through `upgrades.md`. Doctor must not
  fail on a missing line (F10). No ADR is contradicted (F14).

---

## S0 — Analysis and planning — `done`

## S1 — ADR for the session definition (F1, F14; A1, A5) — `done`

Branch: the assigned branch.
Needs: none

Ask D1 first.

1. Read `docs/decisions/README.md` (bar and format) and the `write-doc` skill.
2. Write ADR-0011: a session is one change reviewable as one diff and revertable on its own,
   with its decisions settled first; context is a backstop; the signals in A2; the limit as a
   project fact; ADR needs are written first. Record the options against (keep the fixed tests;
   token budgets; a hook) and D0's middle tier as rejected for now.
3. Update `docs/decisions/README.md` index if it lists ADRs. Add rows to `docs.md`.
4. `scripts/check` (docs-only: no review), then propose the commit.

User involvement: approve the commit.

✂ **Clear context.**

## S2 — The `**Session size:**` line (F9, F10; A4) — `done`

Branch: the assigned branch.
Needs: S1

Ask D2 and D4 first.

1. Add `**Session size:**` with the default to `plugin/template/CLAUDE.md`, the eval fixture's
   `CLAUDE.md` and this repository's `CLAUDE.md`, in the section D2 names. Add it to the
   template's top comment if that lists lines skills read.
2. In the same three copies, change "will not fit one branch and one context" in "How to work
   here" to the new wording (A1).
3. Add an `upgrades.md` entry (Check / Apply), modelled on 0.24.0 "Test-first line".
4. Add a `scripts/test-install.sh` step checking the installed line.
5. Check `doctor` treats a missing line as not a failure (F10); change it if needed.
6. Docs that own what changed; `docs.md` rows. `scripts/check` and the review, then propose
   the commit.

User involvement: approve the commit.

✂ **Clear context.**

## S3 — Rewrite "Check the size" and add the mid-session stop (F1–F6, F11; A1–A3, A5, A6) — `done`

Branch: the assigned branch.
Needs: S2

Ask D3 and D5 first.

1. Verify F2–F6 still hold (read `plugin/skills/simple-session/SKILL.md`).
2. Rewrite the definition at the top (A1) and the frontmatter description.
3. Rewrite "Check the size": scoping estimate line, read **Session size** with its default,
   the signals (A2), ADR-first (A5). Keep the heading (D5).
4. Add the stop partway through to "Do the work" (A6), and fix the ADR routing at the old
   `:134`.
5. Report: add the estimate beside the real diff size (A3).
6. Glossary entry for "Session" (A1). `docs.md` rows; backlog row for D3's hook if D3 is no.
7. `scripts/check` and the review, then propose the commit.

User involvement: approve the commit.

✂ **Clear context.**

## S4 — multi-session S0 sizing and autopilot pauses (F5, F7, F11; A1, A7) — `todo`

Branch: the assigned branch.
Needs: S3

1. `multi-session/SKILL.md`: definition and description (A1); S0 step 4 sizes sessions by
   `simple-session`, "Check the size", not by context.
2. `multi-session/templates/plan.md`: same wording.
3. `plugin/reference/autopilot.md`: replace "cannot finish within its plan" with the A6
   triggers; on such a pause, after the user agrees, the main conversation may split the
   session in `plan.md` (A7). Update `:8,34` wording if it treats context as the limit.
4. Check `harness-upgrades.md`, `spec`, `improve-architecture` pointers still read true (F11).
4a. `plugin/template/CLAUDE.md`, **Conventions**, still says "Work that spans several contexts
   runs as numbered sessions" (found in S2). Reword it, and in the eval fixture and this
   repository's copy if present; add the step to the 0.38.0 `upgrades.md` entry.
5. `docs.md` rows. `scripts/check` and the review, then propose the commit.

User involvement: approve the commit.

✂ **Clear context.**

## S5 — Eval case for a change that should fit (F13; A8) — `todo`

Branch: the assigned branch.
Needs: S3

1. Read case 03 and `plugin/evals/_fixture/` to pick a change that the old tests call too big
   and the new signals let through (for example a small schema change plus the code using it).
2. Add `plugin/evals/24-should-fit/` (`case.yaml`, `prompt.md`, `scaffold.sh`, graders: skill
   fired, runs as one session, does not offer multi-session). Sync shared graders.
3. Check case 03's prompt still trips the new signals; adjust its graders' wording only if
   they quote old tests.
4. Add the README eval-table row. `docs.md` rows. `scripts/check` and the review, then propose
   the commit. Do not run the evals (they cost money); name them in the report.

User involvement: approve the commit; decide later whether to run cases 03 and 24.

✂ **Clear context.**

## S6 — README, site, backlog, changelog (F7, F8; A9) — `todo`

Branch: the assigned branch.
Needs: S4, S5

1. `README.md:128,322`: new definition, sum up, link to the skill.
2. `site/how-it-works.html:62-64,75,156`, `site/skills.html:45,53`,
   `site/get-started.html:114`: new wording; replace the restated tests with a one-line sum-up
   (F8).
3. `docs/backlog.md`: update "The size check can misjudge a change" (acted on; keep collecting
   misjudged cases with the new report line); add "Middle tier" (D0) and, if D3 is no,
   "Size warning hook", each with a trigger.
4. `CHANGELOG.md` `## Unreleased`: one line per change users see.
5. `docs.md` rows. `scripts/check` and the review, then propose the commit.

User involvement: approve the commit.

✂ **Clear context.**
