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
