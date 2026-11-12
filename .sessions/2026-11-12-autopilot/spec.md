# Spec — Autopilot for multi-session efforts

Agreed 2026-11-12 (approved with the plan and ADR-0007 at the start of S1). What must be true when this work is done.

## Problem

A multi-session effort needs the user at the start of every session: a `/clear`, the resume
line, and a report to read before each commit. For an effort whose spec and plan are already
approved, that is a lot of waiting. The user wants to approve the plan once, let the
sessions run, and review the whole result at the end.

## Scope

- An autopilot option in `multi-session`, offered at the end of S0 and chosen by the user.
- All sessions after S0 run one after another without the user, on one mother branch.
- One report at the end, then one question: merge the mother branch into main (or, where
  the project works through pull requests or an assigned branch, push and open one).

## Not in scope

- Removing the commit and merge prompts. Claude Code still asks before each `git commit`
  and `git merge` (ADR-0003). That waits for ADR-0006 (D1, answered).
- Parallel sessions under autopilot. Autopilot runs one session at a time.
- Autopilot for `simple-session`. It is one session already.
- Pushing, merging into main, tagging or deploying without the user.

## Acceptance criteria

- **A1** — When S0 ends, the message offers autopilot next to the usual resume line, and
  nothing runs on autopilot until the user chooses it.
- **A2** — When the user chooses autopilot, the folder's `README.md` and `decisions.md`
  record it, and a mother branch is cut from an up-to-date main branch (or the assigned
  branch is used as the mother branch). No session branch is cut.
- **A3** — Each session runs in its own fresh context, so the main conversation holds only
  the folder's files and each session's short report, never a session's own reading.
- **A4** — Each session still does the `simple-session` steps: design check, work, owning
  doc, `scripts/check`, `/simplify` and `/code-review`, docs ledger. It then commits on the
  mother branch with `(S<N>)` in the summary, and updates `plan.md` and `log.md`.
- **A5** — A question in `decisions.md` with no answer does not stop the run: the session
  takes the recommendation, marks the row `assumed`, and the final report lists it.
- **A6** — The run pauses and asks the user when: a change would cross a Boundary, break a
  Constraint, go against an accepted ADR or bring in a new Style or Pattern; `scripts/check`
  still fails after two fix attempts; or a session cannot finish within its plan. It
  records the pause in `log.md`, so the user can resume autopilot with one line.
- **A7** — After the last session, close-out runs on the mother branch from `docs.md`: the
  owning docs, a record, backlog entries, and any ADR written as **Proposed**.
- **A8** — The version bump (if the project has one) runs once, as the last commit on the
  mother branch, not once per session.
- **A9** — The final report is written to `report.md` in the folder and shown to the user.
  It lists: ADRs added or changed; changes to the Architecture section and the plan's
  Design; a summary of code, test and docs changes, each with a diffstat; each acceptance
  criterion and how it was checked; check and review results; assumed decisions; the
  commit list; anything left open.
- **A10** — The report ends with one question: merge the mother branch into main (or push
  and open a pull request). Nothing is merged or pushed before the user says yes.
- **A11** — A session that ends early (the user stops it, the container is lost) can be
  resumed with "Read <folder>/README.md and continue autopilot", and it starts at the first
  session not `done`.
