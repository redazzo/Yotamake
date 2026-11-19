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

## 2026-11-19 — S3: rewrite "Check the size", stop partway (autopilot)

- D3, D5 assumed. `simple-session`: new definition and description; "Check the size" states
  an estimate (not for trivial or docs-only), the `Session size` limit with its stated
  default, the signals, context as backstop; an ADR lands first as its own commit; "Stop
  partway" (also in `debugging`, which now points to it; inside an effort it stops and asks,
  or `PAUSE`); report line with estimate beside real size. Glossary "Session" points to the
  skill. Lite-install path moved to `missing-setup.md`. Changelog line.
- Review. `/simplify` (twice): estimate skipped for trivial changes; stop partway reuses step
  1's signals and measures once; shorter glossary and changelog; a needless re-wrap undone.
  Skipped: re-splitting the spec paragraph (line cap); dropping "container resets" or "a
  judgment" or the "not too big by themselves" sentence (A1/A2, and the limit is soft).
  `/code-review`: stop partway inside an effort and in bug fixes; step 4's ADR line matched to
  "ADR first"; default also for an unfilled line; `missing-setup.md` intro covers lite. Design
  read: pointing to the template for the default clashed with ADR-0002 and ADR-0011 §4, so
  the skill states the number again (undoing a `/simplify` suggestion).
  Left: autopilot's pause wording (S4); README and site (S6).
- Checks: all PASS. The S3 agent wrote no estimate before starting; real diff about 6 files,
  +65/−45. `simple-session` is exactly 250 lines: S4 must not add to it.
- Surprising: the commit gate's review window restarts at each "user prompt", and the stop
  hook's "please commit" messages count as prompts, so fixes made after one need the review
  again. Backlog candidate.
- Next: S4.

## 2026-11-19 — S4: multi-session sizing and autopilot pauses (autopilot)

- `multi-session`: description and definition point to `simple-session`, "Check the size";
  S0 step 4 sizes sessions by it (an irreversible step gets its own session; a signal the
  plan accounts for does not stop a session later); a new rule in "Rules for every session"
  splits a session that stops partway, once the user says yes. `plan.md` template points to
  the check. `autopilot.md`: `PAUSE: size — <reason>` beside the kept "cannot finish within
  its plan"; on a split the main conversation edits `plan.md` and tells the agent to stop and
  report. Template **Conventions** "Work too big for one session", with an upgrade step in
  the 0.38.0 entry. Changelog line.
- Review. Before it: cut two restatements of the definition in `multi-session`. `/simplify`:
  split rule moved from autopilot to `multi-session` (step-through needs it too); `PAUSE:
  size` marker; shorter description and plan template; dropped a duplicate sentence. Skipped:
  naming the **Session size** line in step 4 (pointer enough). `/code-review`: agent stops
  and reports after a split; split updates later `Needs:` and moves criteria; split waits for
  the user's yes; irreversible step and planned signals; kept the general pause trigger;
  clarified a parenthetical. Design read: no conflicts; two re-wraps.
- Checks: all PASS. Size: about 6 files, +45/−20 (no estimate written first).
- Surprising: a quoted step name split across blockquote lines fails `consistency`.
- Next: S5.
