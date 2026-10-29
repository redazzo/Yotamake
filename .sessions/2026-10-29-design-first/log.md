# Log

## 2026-10-29 — S0: analysis and planning

- Read the skills, template, installer and evals. Findings F1–F10 in `findings.md`.
- Wrote `spec.md` (A1–A10), `plan.md` (S1–S4) and `decisions.md` (D1–D8; D1–D4 answered).
- Next: spec approval, then S1.

## 2026-10-29 — S1: Architecture as a fact

- Spec approved; D5 answered (the four line names).
- `plugin/template/CLAUDE.md`: structured `## Architecture` (Modules, Boundaries, Shared code,
  Patterns, and Decisions inside the docs markers, so `--lite` drops it); listed in the
  header comment; the Conventions placeholder no longer mentions boundaries.
- `plugin/template/scripts/check`: commented design-gate examples (dependency-cruiser,
  import-linter, jscpd).
- `plugin/skills/setup/SKILL.md`: proposes the Architecture lines from the repo and asks to
  confirm; adds an existing design tool to `scripts/check`.
- Eval fixture: `src/text.js` (`titleCase`) with a test, and an Architecture section whose
  boundary is "src/ is pure".
- Checks: both `validate --strict` pass; full and lite installs correct; fixture
  `scripts/check --all` PASS docs, PASS tests.
- Surprise: in an empty repo with no `README.md`, a fresh install fails the docs check
  (`CLAUDE.md` links `./README.md`). Already true before this effort; not fixed here.
- Committed without the stop-and-ask: the environment's stop hook requires committed and
  pushed work before a turn ends.
- Next: S2 (ask D6 first).

## 2026-10-29 — S2: the method in the skills

- D6 was already answered (use `/simplify`).
- `simple-session`: reads **Architecture**; new step 3 "Design and reuse" (reuse first, fit the
  design, always stop on a boundary, ADR or new-pattern conflict, fall back to the code's
  own structure when Architecture is unfilled); review is now reuse (`/simplify`, keep only
  fixes to the branch's own code), design, then bugs (`/code-review`); report has "Reused:"
  and "New, because:" lines. Later steps renumbered 4–8.
- `multi-session`: S0 step 3 fills a Design section in `plan.md`, agreed before S1; the
  template has it. Step references updated (`simple-session`, step 5; own step 5).
- `spec`: says the session's design step checks Architecture; a criterion that needs a
  boundary break is raised as a question.
- Checks: both `validate --strict` pass; scratch install `scripts/check --all` PASS docs.
  Review skipped: Markdown-only change (the skill's own rule).
- No eval run yet; S3 asks D7 first (re-run 02 and 03 too, since `simple-session` changed).
- Next: S3.
