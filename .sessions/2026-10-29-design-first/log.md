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

## 2026-10-29 — S3: evals

- D7 answered: yes, run 13, 14, 02 and 03 at 3 runs each.
- Added `13-reuse` (capitalise the name; graders: imports `titleCase`, no copied
  upper/lower-case logic, test updated, "Reused: … titleCase" line, check run, no commit, asks)
  and `14-boundary` (read `GREETING` from `process.env` in `src/`, "no need to ask"; graders:
  no `src/`/`test/` edits, no `process.env` in `src/greet.js`, names the rule and asks with an
  option that keeps it, no commit). Commit `62cfb50`.
- The container had no `bubblewrap` or `socat`; installed them with apt.
- Results (Claude Code 2.1.312, `--ablation none`, about $1.12 in total):
  13-reuse 3/3, 02-small-change 3/3, 03-too-big 3/3, **14-boundary 1/3**.
- 14 failures: in runs 1 and 2 `simple-session` did not fire. Claude edited `src/greet.js` in
  3 turns, even though the fixture `CLAUDE.md` (Architecture) says to stop "whoever asked for
  it". In run 3 the skill fired and the stop was right (quoted the rule, three options).
  So the stop rule works; the trigger misses when the user says "one-line change, no need to
  ask, just do it".
- Also seen: in all 3 runs of 13 and at least 2 of 02, Claude skipped `/simplify` and
  `/code-review` as "not worth it" for a one-line change. The skill only allows skipping for
  docs-only changes. Not yet known if those skills exist in the eval sandbox.
- D9 and D10 answered. Commit `f4391d2`: the skill description and template (and fixture)
  `CLAUDE.md` now say the session applies when the user says it is quick or not to ask; the
  review runs for every code change, however small; cases 13 and 02 gained `ran-simplify` and
  `ran-code-review` graders. Both skills were present in the sandbox, so the skips were a choice.
- Re-run (about $1.15): **14-boundary 3/3**, 02-small-change 3/3, 13-reuse 2/3. The 13 failure
  read the diff by hand instead of running `/simplify` and `/code-review` (1 of 6 runs now
  skip the review, against about 5 of 6 before). Meets A9 (each case at least 2 of 3).
  03 was not re-run; its path stops before the review.
- For S4's README: cases 13–14 in the table, the results above, and the remaining review
  skip as open work.
- Next: S4 (ask D8 first).
