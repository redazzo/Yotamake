---
kind: record
date: 2026-11-12
status: historical
---

# Autopilot for multi-session efforts

**Date:** 2026-11-12 · **Status:** live in 0.23.0

**Why.** A multi-session effort needed the user between every session: a `/clear`, the
resume line, and a report to read before each commit. When the spec and plan are already
approved in S0, most of that waiting adds little. The user wanted to approve once, let the
sessions run, and review the whole result at the end. It ran as a five-session effort
(S0 to S4) on one assigned branch, with each session stopping for the user as usual.

**Decided.**

- [ADR-0007](../../decisions/0007-autopilot-runs-sessions-in-subagents.md): an opt-in
  autopilot. The main conversation runs each session after S0 in a fresh built-in
  `general-purpose` agent, one after another, on one mother branch. It amends ADR-0005,
  which had rejected a conversation driving session subagents, for autopilot only.
- Kept: every `git commit` and `git merge` still prompts (ADR-0003). Removing the prompt
  waits for ADR-0006. Kept: the user approves the spec, plan and Design at the end of S0
  before autopilot starts.
- A question with no answer does not stop the run: the recommendation is taken, the row is
  marked `assumed`, and the final report lists it.
- The main conversation runs the review (`/simplify`, `/code-review`) and the commit for
  each session, after the agent returns. A test showed both review skills run inside a
  subagent, but that subagent had no `Agent` tool, so `/simplify` ran as one weaker inline
  pass. The docs' "agents up to three levels deep" did not hold there, so the session brief
  does not rely on it.
- Mother branch: the assigned branch if there is one, else `<prefix>/<effort-slug>`.
- The end: close-out (keeping the folder), `report.md`, one merge question. On yes, each as
  its own commit: delete the folder, the one version bump, then the merge or pull request.
  This changed the order in ADR-0007's first draft, so the ADR got a dated amendment.
- Rejected: one branch per session merged into the mother branch (twice the merge prompts);
  running every session in the main conversation (its context would fill); separate cloud
  sessions (not generic); parallel sessions under autopilot.

**Built.**

- 0.23.0 (S2): `multi-session`, "Autopilot": turning it on, the mother branch, the
  per-session loop, the session brief, pauses, `assumed` answers, the end, resuming. S0's end
  message offers it. Templates: autopilot lines in `README.md`, `assumed` in `decisions.md`,
  a new `report.md`. `simple-session`, "Stop and report", defers to it.
- 0.23.0 (S3): the "Autopilot" paragraph in `README.md`, and eval case
  `20-multi-session-autopilot-offer`: S0 offers autopilot and starts no session agent, though
  the prompt tempts it. 3 runs, score 1.00.

**Not tested.** Whether a subagent's edit marks the parent session for the `Stop` gate: the
plugin's hooks did not run in the cloud session used. A full autopilot run has no eval case;
it would be too slow and costly. This effort itself ran without autopilot.

**Left.** In [the backlog](../../backlog.md): "Spawn worktree sessions from the main
conversation" (now only the parallel case), "Autopilot context growth", "Test the `Stop`
gate after a subagent's edit" and "Shared copies of two eval graders".
