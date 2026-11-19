# Spec — Session sizing by review, revert and decisions

Agreed <yyyy-mm-dd, on approval>. What must be true when this work is done. One page at most.

## Problem

The size check calls a change "too big for one session" by fixed structural tests and by
whether it fits one context. Context is rarely the limit for current models and matters less
with each release, while the tests both block changes that fit and pass ones too big to
review. Users need a size rule based on what still holds: how big a diff can be reviewed,
what can be reverted on its own, and where the user must decide.

## Scope

- The definition of a session, everywhere it is written.
- `simple-session`, "Check the size": signals, a scoping estimate, a project-set limit.
- A stop partway through a session that outgrows the limit.
- `multi-session` S0 sizing and autopilot's pause rule use the same signals.
- A `**Session size:**` line in `CLAUDE.md` (template, eval fixture, this repository), with
  an `upgrades.md` entry.
- An ADR for the new definition; one new eval case; README, site and backlog updates.

## Not in scope

- A lighter middle tier between `simple-session` and `multi-session` (D0: left out; a backlog
  entry instead).
- A hook that measures or blocks on diff size (see D3).
- Re-running the paid eval suite (asked for separately, per `CLAUDE.md`).

## Acceptance criteria

- **A1** — `simple-session` defines a session as one change that can be reviewed as one diff
  and reverted on its own, with its decisions settled before it starts, and names "fits in one
  context" as a backstop. The glossary, `multi-session`, its `plan.md` template, and the three
  `CLAUDE.md` copies (repository, template, eval fixture) use the same wording.
- **A2** — "Check the size" lists these signals: estimated diff over the limit; parts that
  could ship on their own; a decision that can only be made after part of the work; work that
  will span days, people or container resets; a step that cannot be undone. It no longer
  calls a change too big only because it touches a schema and code, adds more than one
  interface, or touches more than one package.
- **A3** — Before judging, the check states a one-line estimate (files and rough changed
  lines). The report repeats that estimate beside the real diff size.
- **A4** — The limit is read from a `**Session size:**` line in `CLAUDE.md`. When the line is
  missing or unfilled, the skill uses the default it states and says so once in the report.
  The template, the eval fixture and this repository have the line; `upgrades.md` has an
  entry; `scripts/test-install.sh` checks the installed line; `/yotamake:doctor` does not fail
  a repository that lacks it.
- **A5** — Needing an ADR leads to writing the ADR first, as its own session (or commit on an
  assigned branch), not to `multi-session` by itself.
- **A6** — While working, if the diff passes the limit or a decision appears that depends on
  the work's results, `simple-session` stops and offers `multi-session`, with the work so far
  as S1.
- **A7** — Autopilot's pause rule names the same triggers instead of "cannot finish within its
  plan", and after the user agrees, the main conversation may split the paused session in
  `plan.md`.
- **A8** — A new eval case asks for a mid-sized change that the old tests called too big (for
  example a small schema change plus the code that uses it) and grades that it runs as one
  session. Case 03 still grades too-big. Both have rows in the README's eval table.
- **A9** — `README.md` and the site pages sum up the size check without restating its tests;
  the backlog entry "The size check can misjudge a change" is updated; `scripts/check` passes.
