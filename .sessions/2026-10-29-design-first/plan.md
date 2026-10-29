# Plan

4 sessions. Clear context between them (marked ✂). Each session is one set of commits on the
assigned branch, small enough to finish in one context. Order: the fact (Architecture section)
first, since every skill change reads it; then the skills; then the evals that test them;
docs and version last so they describe the final state.

Status values: `todo`, `in progress`, `done`, `skipped`.

## Design

- **Modules touched:** `plugin/template/` (CLAUDE.md, scripts/check), `plugin/skills/`
  (simple-session, multi-session and its plan template, setup, spec), `plugin/evals/`
  (fixture, two new cases), `README.md`, both manifests.
- **Reused:** the existing named-section mechanism (skills read `CLAUDE.md` sections by name)
  carries the architecture facts; the existing stop-and-ask and report steps carry the new
  stops and lines; the built-in `/simplify` does the reuse review (D6); the shared eval
  fixture gets the helper and boundary both new cases need, rather than two scaffolds.
- **New:** one `CLAUDE.md` section structure, one skill step (design and reuse), one plan
  section, two eval cases. No new skill, hook or script.
- **Boundaries at risk:** "Keep the plugin generic" (root `CLAUDE.md`). Tool names in
  `scripts/check` stay commented examples only.

---

## S1 — Architecture as a fact (F1, F3, F6, F8; A1, A2, A8) — `done`

Branch: the assigned branch. Ask D5 first.

1. `plugin/template/CLAUDE.md`: structure `## Architecture`; add it to the header comment.
2. `plugin/template/scripts/check`: boundary and duplicate-code placeholders.
3. `plugin/skills/setup/SKILL.md`: fill in Architecture from the repo.
4. Eval fixture: an Architecture section in `CLAUDE.md`, and `src/text.js` as a shared helper
   with a test (so case 13 has something to reuse and case 14 a boundary).
5. "Before committing" checks, then propose a commit.

✂ **Clear context.**

## S2 — The method in the skills (F2, F4, F5, F7, F9; A3–A7) — `done`

Ask D6 first.

1. `simple-session`: read Architecture; new design-and-reuse step before code; the always-stop
   rule; review checks design and duplication; report lines.
2. `multi-session`: Design section in S0 and in `templates/plan.md`.
3. `spec`: note that Architecture now feeds the session's design step.
4. Checks, then propose a commit.

✂ **Clear context.**

## S3 — Evals (F8; A9) — `in progress`

Ask D7 first.

1. `13-reuse`: add a feature that should reuse `src/text.js`; graders check reuse and the
   report lines.
2. `14-boundary`: a request that tempts a boundary break; graders check it stops, asks and
   edits nothing under `src/`.
3. Validate; run the cases if D7 says yes; record results.

✂ **Clear context.**

## S4 — Docs, version, close-out (F10; A10) — `todo`

Ask D8 first.

1. `README.md`: the design idea, the Architecture section, cases 13–14, open work.
2. Bump the version in both manifests.
3. Full "Before committing" checks. Check each criterion A1–A10.
4. Ask before deleting this folder (its own commit).
