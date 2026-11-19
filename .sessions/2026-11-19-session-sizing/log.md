# Log

## 2026-11-19 — S0: analysis and planning

- Analysed the size rule across skills, reference, template, hooks, docs, site and evals with
  three read-only agents; findings F1–F14 in `findings.md`.
- D0 answered: the middle tier is out of scope.
- Wrote `spec.md` (A1–A9), `plan.md` (S1–S6) and `decisions.md` (D1–D5 open).
- Next: user approval of spec and plan, then S1.

## 2026-11-19 — S1: ADR for the session definition (autopilot)

- Wrote ADR-0011 (Proposed; D1 assumed) and its index row in `docs/decisions/README.md`.
  It leaves the default limit and the line's place to S2 (D2, D4). Commit `2f8f36d`.
- Checks: all PASS (`s1-checks.log`). Review: skipped, docs-only.
- Left: ADR-0011 Proposed → Accepted on the user's word (open `docs.md` row, close-out).
- Surprising: the commit gate counts `.sessions/` as code, so a docs-only session needs a
  `Review-skipped:` trailer. This entry and S1's `done` status were written late, in S2,
  because a blocked commit command also dropped them.

## 2026-11-19 — S2: the `**Session size:**` line (autopilot)

- D2, D4 assumed. Added `**Session size:**` (about 400 changed lines or 15 files) to
  **Branching and releases** in the template, the eval fixture and this repository's
  `CLAUDE.md`; an `upgrades.md` 0.38.0 entry; a `test-install.sh` step; a `setup` sentence;
  a site line; a `## Unreleased` changelog line.
- Review. `/simplify`: "How to work here" now points to `simple-session`, "Check the size",
  instead of restating the definition (D7 assumed, one owner); the upgrade entry points to the
  template instead of repeating the default; the test is simpler and does not pin the
  default. Skipped: generalising the `labels` lint in `consistency.mjs` (outside the diff).
  `/code-review`: the upgrade Check now also covers the rewording; the test checks a number
  and the wrapped line; changelog and setup lines added. Left: the line says
  `simple-session` reads it, which is true only after S3 (no release before the end bump).
  Design read: no clash with an accepted ADR; notes the work builds on ADR-0011, still
  Proposed; glossary is S3's.
- Checks: all PASS (`s2-checks.log`). `scripts/check` names eval cases 01–23; not run (cost).
- Next: S3.
