# Plan

4 sessions. Clear context between them (marked ✂). Each session is one set of commits on the
assigned branch, small enough to finish in one context. Order: the ADR and the open facts
first, since the skill text depends on them; then the skill; then the overview, eval and
release; close-out last so it describes the final state.

Status values: `todo`, `in progress`, `done`, `skipped`.

## Design

- **Style:** stays inside the current Style: declarative Markdown skill text plus templates.
  Sessions run in Claude Code's built-in `general-purpose` agent with the brief written in
  the skill, as S0 already does for reading. No plugin agent definitions, no new hook. The
  one change of method (a conversation drives session subagents, which ADR-0005 rejected)
  gets ADR-0007.
- **Modules touched:**
  - `plugin/skills/multi-session/SKILL.md`: a new section, "Autopilot": how S0 offers it,
    the mother branch, the per-session brief, assumed decisions, when to pause, how to
    resume, close-out, the single bump, the report and the merge question. "Starting a new
    effort" step 6 and "Closing out" get a pointer to it.
  - `plugin/skills/multi-session/templates/`: `README.md` (a setup line for autopilot and
    its resume line), `decisions.md` (an `assumed` answer), new `report.md` (the final
    report's headings, A9).
  - `plugin/skills/simple-session/SKILL.md`: one sentence in "Stop and report", next to the
    worktree one, saying `multi-session` autopilot rules on commits come first.
  - `README.md`: a short "Autopilot" paragraph and the new eval row.
  - `plugin/evals/20-multi-session-autopilot-offer/`: new case (A1).
  - `docs/decisions/0007-…` (new) and an amendment line on ADR-0005.
- **Reused:** the committed setup's one-branch shape (F5); `simple-session` steps for each
  session, unchanged; the docs ledger and close-out; the S0 agent-brief pattern
  (`multi-session`, "Starting a new effort", step 2); the eval fixture and graders in
  `plugin/evals/_fixture/` and `_graders/`.
- **New:** the `report.md` template (no existing file holds an end-of-effort report); the
  `assumed` decision state; the eval case.
- **Boundaries and constraints at risk:** ADR-0003 is kept: every commit and merge still
  prompts, and autopilot never pushes, merges into main, tags or deploys without a yes.
  ADR-0005 is amended by ADR-0007 for autopilot only. The plugin stays generic: the mother
  branch takes the project's own prefix from CLAUDE.md. No new dependency.

---

## S1 — ADR-0007 and the open facts (F2, F4, F8) — `done`

Branch: the assigned branch.
Needs: none

Ask D4 first if S1's test fails.

1. Re-read ADR-0005 and ADR-0003. Move ADR-0007 from Proposed to Accepted if the user
   approved it with this plan; add a dated amendment to ADR-0005 pointing to it; update
   the ADR index.
2. Test, in this repository, on a throwaway branch: a `general-purpose` subagent asked to
   run `/simplify` and `/code-review` on a one-line diff. Record whether both ran (F4).
   Check that a subagent's edit leaves a `yotamake-edited` marker with this session's id
   (F8). Write both results in `findings.md`, and into ADR-0007's "Tested" section.
3. Delete the throwaway branch (ask). `scripts/check`, docs ledger rows.
4. Propose the commit.

User involvement: approve the commit; answer D4 if the test fails.

✂ **Clear context.**

## S2 — The autopilot skill text (A1–A11) — `done`

Branch: the assigned branch.
Needs: S1

Ask D5, D6, D8 first.

1. Verify F1, F5, F6, F7 still hold.
2. Write `multi-session`, "Autopilot", and the pointers from S0 step 6 and "Closing out".
3. Templates: `README.md`, `decisions.md`, new `report.md`.
4. The one sentence in `simple-session`, "Stop and report".
5. Docs ledger rows. `scripts/check` and the review, then propose the commit.

User involvement: approve the commit.

✂ **Clear context.**

## S3 — Overview, eval and release (A1, F9, F10) — `todo`

Branch: the assigned branch.
Needs: S2

Ask D7 first.

1. `README.md`: the Autopilot paragraph and the eval row.
2. The eval case `20-multi-session-autopilot-offer` (A1), with graders.
3. `scripts/check` and the review. Run the eval only if D7 says yes.
4. Propose the commit, then the minor bump to 0.23.0 as its own commit with
   `./plugin/install.sh .`.

User involvement: approve the commits; D7.

✂ **Clear context.**

## S4 — Close-out — `todo`

Branch: the assigned branch.
Needs: S3

1. Work through `docs.md`: owning docs, a record in `docs/records/2026/`, backlog (update
   "Spawn worktree sessions from the main conversation"), regenerate the records index.
2. Check each criterion A1–A11 against the final skill text.
3. Close-out entry in `log.md`; ask before deleting this folder (its own commit).
4. Push and ask whether to open a pull request.

User involvement: approve the commits, the push and the pull request.
