---
kind: decision
date: 2026-11-19
status: current
---

# ADR-0011: A session is sized by review, revert and decisions, with context as a backstop

- **Status:** Accepted (2026-11-19), at the end of effort "Session sizing".
- **Date:** 2026-11-19
- **Work record:** [Session sizing by review, revert and decisions](../records/2026/2026-11-19-session-sizing.md)
- **Builds on:** [ADR-0002](./0002-project-facts-in-named-claude-md-sections.md), for the
  limit as a fact in a named `CLAUDE.md` line;
  [ADR-0007](./0007-autopilot-runs-sessions-in-subagents.md), whose pause on "a session that
  cannot finish within its plan" now has named triggers;
  [ADR-0010](./0010-commit-gate-by-step-table.md), which this leaves as it is (no new step
  rule). Keeps "one branch, one merge" and the `/clear` between sessions, which
  [ADR-0005](./0005-parallel-sessions-in-worktrees.md) and
  [ADR-0009](./0009-autopilot-is-the-default.md) rely on.

## Context

The harness defines a session as "one branch and one merge that fits in one context". The
definition is written in about ten files (skills, the `plan.md` template, three `CLAUDE.md`
copies, the glossary, the README and the site). It drives the gate at the start of
`simple-session`, which sends work to `multi-session`.

That gate has two problems.

1. **Context is a weak limit.** Current models have large context windows, compact their
   context automatically, and can hand reading to subagents. So "fits in one context" seldom
   decides anything, and it will decide less with each model release. This is a judgment from
   how sessions in this repository have run, not a measurement. A model is also unlikely to
   know up front whether it "would want to `/clear`", so that test is self-report.
2. **The fixed tests measure structure, not size.** A change is "too big" if it touches a
   schema and code, adds more than one interface, touches more than one package, or needs an
   ADR. A small schema change with the code that uses it is often best as one change. A
   rename across packages can be trivial. Yet a large change inside one package passes. The
   backlog entry "The size check can misjudge a change" records this. No numbers are stated
   when the check runs, so misjudged cases are never recorded.

Nothing checks the size again once a session has started. Autopilot pauses on "a session
that cannot finish within its plan", but nothing says what that means.

What still limits a session, whatever the model:

- **Review.** The user and the review skills read one diff. A diff too big to read with care
  gets a weaker review.
- **Revert.** A part that could ship alone is safer in its own commit, so it can be undone
  alone.
- **Decisions.** A choice that can only be made after part of the work is a stop for the
  user, which a session cannot hold open.
- **Durable state.** Work that spans days, people or container resets needs a working folder
  to survive, which `multi-session` gives and a single session does not.

## Decision

In the context of the size check that decides between `simple-session` and `multi-session`,
facing a check that rests on context and fixed structural tests, we decided to size a
session by review, revert and decisions, with context kept only as a backstop (and against
keeping the fixed tests, token budgets, or a hook), to achieve a check that holds as models
change and that blocks only work that is really too big, accepting that the check is a
judgment against a rough estimate, not a measurement.

1. **The definition.** A session is one change that can be reviewed as one diff and reverted
   on its own, with its decisions settled before it starts. It still runs on one branch with
   one merge. "Fits in one context" stays as a backstop: if a session clearly will not fit,
   it is too big, but fitting does not make it small enough.
2. **Signals, not fixed tests.** A change is too big for one session when any of these hold:
   - its estimated diff is over the project's limit;
   - it bundles separate changes that could each ship, and be reviewed, alone;
   - a decision can only be made after part of the work is done;
   - it will span days, people or container resets;
   - it has a step that cannot be undone.

   A schema change with code, more than one interface, or more than one package is no longer
   too big by itself. These may still point to one of the signals.
3. **An estimate first.** Before judging, the session states a one-line estimate: files and
   rough changed lines. The report repeats it beside the real diff size, so misjudged cases
   can be collected.
4. **The limit is a project fact.** It is read from a named line in `CLAUDE.md`, as ADR-0002
   requires, and the skill states a default for when the line is missing or unfilled. The
   default is a judgment, not a measured number. The exact line, its place and the default are
   set in the skill and the template, not here.
5. **A stop partway through.** While working, if the diff passes the limit, or a decision
   appears that depends on the work's results, the session stops and offers `multi-session`,
   with the work so far as S1. Autopilot's pause names the same triggers, beside its general
   pause on a session that cannot finish within its plan.
6. **ADR first.** A change that needs an ADR writes the ADR first, as its own session (or its
   own commit on an assigned branch). Needing an ADR no longer sends work to `multi-session`
   by itself.

### Alternatives considered

- **Keep the fixed tests.** They are easy to apply, but they block changes that fit and pass
  ones too big to review well (see Context).
- **A token or context budget.** It measures the backstop, not the limits that matter, and a
  model cannot judge it well up front. It would also go stale as context windows grow.
- **A hook that measures the diff and warns or blocks.** No hook deals with size today, and a
  threshold would be a new kind of rule under ADR-0010. Skill text comes first; a
  non-blocking warning may follow if the text is not enough.
- **A middle tier between `simple-session` and `multi-session`** (one branch, a step list, a
  commit per step, no working folder). Rejected for now to keep two tiers; kept as a backlog
  entry.

## Consequences

- **Positive:** a mid-sized change that is one reviewable diff runs as one session, without
  a working folder. The check no longer depends on how large a model's context is. Each
  report states an estimate and the real size, so the default limit can be tuned from real
  cases. A session that outgrows its estimate stops instead of going on.
- **Negative / accepted trade-offs:** the signals need judgment, and the estimate can be
  wrong. The default limit is a guess until cases are collected. Older installs lack the
  `CLAUDE.md` line and use the default until they add it. The definition must be reworded in
  every file that states it.
- **Invariants this protects:** a session is still one branch and one merge. Every change
  still runs as a session. Stop points (ADR-0003) and the review are unchanged. The skills
  stay generic: the limit is a project fact with a default, not a rule for one stack.

## References

- `plugin/skills/simple-session/SKILL.md`, "Check the size" and "Do the work"
- `plugin/skills/multi-session/SKILL.md`, `plugin/reference/autopilot.md`
- `docs/reference/glossary.md`, "Session"
- [Backlog](../backlog.md), "The size check can misjudge a change"
