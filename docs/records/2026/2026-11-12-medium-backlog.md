---
kind: record
date: 2026-11-12
status: historical
---

# The medium-priority backlog: cost, trivial tier, test-first, debugging, design read

**Date:** 2026-11-12 · **Status:** live in 0.26.0

**Why.** Four backlog entries carried **Priority: Medium**: measure what a session costs,
delegate the review's design read, add a debugging skill, and make test-first a project
choice. They ran as one five-session effort.

**Decided.**

- Cost: measure from the eval results already saved, and add a trivial review tier. Only
  comments and typos in prose count as trivial. String literals, identifiers and config
  values never do, since they change behaviour. When unsure, the full review runs.
- Test-first: a `Test-first:` line in **Checks**, `no` by default and asked by `setup`.
  With `yes`, it covers any change in behaviour. Refactors, docs-only and trivial branches
  are exempt.
- Debugging: a model-invoked skill, so it fires on a bug fix without a slash command. It
  always writes a failing test where tests exist, whatever `Test-first` says.
- Design read: find out first whether eval graders see a subagent's calls, then decide. A
  probe case showed they do: a `tool_used` grader counted a Bash call made inside a
  subagent (the trace links it to its parent Agent call, and names the tool `Agent`, not
  `Task`). So the design read moved to one agent that returns conflicts only. `/simplify`
  and `/code-review` stay in the main context, since they start their own agents.

**Built.**

- S1, scripts only: `scripts/eval-costs.mjs` summarises saved eval results per case (runs,
  pass rate, mean cost, turns, seconds, versions). Over 22 saved runs it confirmed the
  baseline means.
- 0.23.0 (S2): the trivial tier in `simple-session`, and eval case `20-trivial-change`.
  Case 20 passed ($0.21).
- 0.24.0 (S3): the `Test-first:` line, read by `simple-session`, `spec` and `setup`, with an
  `upgrades.md` entry.
- 0.25.0 (S4): the `debugging` skill and case `21-debugging`. In case 21 the planted bug
  crashes one helper away from its cause, so only a fix at the cause passes.
- 0.26.0 (S5): `simple-session`, "Review", hands the design read to an agent. Case 02 gained
  a grader for it.

**Not tested.** Case 07, run to answer the design-read question, passed ($0.52) but started
no subagent: the project was small enough to read inline. A throwaway probe case ($0.21)
answered it instead. Case 02 failed one run in S2 because the sandbox denied git (backlog,
"Eval sandbox denies `git`"). Cases 02, 11, 12, 17 and 21 were not run after their changes.

**Left.** In [the backlog](../../backlog.md): "Copied graders and a shared word", and under
"Untested paths", a Skill call made inside a subagent.
