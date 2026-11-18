---
kind: decision
date: 2026-11-12
status: current
---

# ADR-0007: Autopilot runs an approved effort's sessions in subagents on one branch

- **Status:** Accepted (2026-11-12), amended 2026-11-17 and 2026-11-18, with the effort's spec and plan. The tests are below.
- **Date:** 2026-11-12
- **Work record:** [Autopilot for multi-session efforts](../records/2026/2026-11-12-autopilot.md)
- **Supersedes / amends:** amends [ADR-0005](./0005-parallel-sessions-in-worktrees.md),
  which rejected "one conversation driving worktree subagents", for autopilot only. Keeps
  [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md) as it is.

## Context

A multi-session effort needs the user between every session: a `/clear`, the resume line,
and a report to read before each commit. When the spec, the plan and its Design section are
already approved in S0, most of that waiting adds little. Users want to approve once, let
the sessions run, and review the whole result at the end.

ADR-0005 rejected a main conversation that drives sessions as subagents, because each
session would lose its own stop before commit. Autopilot gives up that stop on purpose and
puts one review of the whole effort at the end instead.

Claude Code facts below are from its documentation (sub-agents, hooks, permissions and
permission modes pages), read on 2026-11-12 through an agent, and are untested here:

- a subagent can start agents of its own, up to three levels below the main conversation;
- a subagent can call plugin and project skills; the docs do not say whether built-in skills
  such as `/simplify` and `/code-review` are reachable;
- hooks from settings and plugins fire inside subagents;
- `ask` rules prompt in every permission mode, and a foreground subagent passes the prompt
  to the user;
- a subagent compacts its own context as it fills.

## Decision

In the context of a multi-session effort whose spec, plan and Design the user approved in
S0, facing a stop and a `/clear` between every session, we decided to offer an autopilot
option that runs the remaining sessions without the user, and against keeping the
per-session stop as the only way, accepting that the user reviews the work once, at the end,
instead of after each session.

1. **Opt-in.** Only the user turns it on, at the end of S0 or when resuming. It is recorded
   in the effort's `README.md` and `decisions.md`.
2. **One mother branch.** In the local setup, one branch is cut for the effort from an
   up-to-date main branch. In a committed setup on an assigned branch, that branch is the
   mother branch. Each session lands as commits on it, with `(S<N>)` in the summary. No
   session branches.
3. **One subagent per session.** The main conversation starts one built-in agent per
   session, in turn, with a brief written in the skill. The subagent's fresh context stands
   in for `/clear`. Each session still follows `simple-session`: design check, work, owning
   doc, `scripts/check`, the docs ledger. The main conversation runs the review
   (`/simplify` and `/code-review`) on each session's diff when the subagent returns, as
   `simple-session`, "Review", already says (see Tested).
4. **Stops kept.** Every `git commit` and `git merge` still prompts (ADR-0003). Autopilot
   never pushes, merges into the main branch, tags or deploys without a yes.
5. **Pauses.** The run stops and asks on a design conflict (as `simple-session`, "Design and
   reuse"), on a check that still fails after two fix attempts, and on a session that cannot
   finish within its plan. A decision with no answer does not stop it: the session takes the
   recommendation and marks it `assumed`.
6. **One end.** After the last session, close-out runs on the mother branch, then one
   version bump (if the project has one), then a report of the whole effort, and one
   question: merge into the main branch, or push and open a pull request.

We decided against:

- **Removing the commit prompt for autopilot now.** That needs ADR-0006, which is Proposed
  and untested.
- **One branch per session merged into the mother branch.** Twice the merge prompts for no
  gain over commits tagged `(S<N>)`.
- **Running every session in the main conversation and relying on compaction.** Each
  session's reading would crowd out the plan and the later sessions.
- **Spawning separate cloud sessions.** Not generic: only some environments have it.
- **Parallel sessions under autopilot.** More moving parts; ADR-0005 still covers parallel
  work run by the user.

## Tested

Run on 2026-11-12, in a Claude Code 2.1.322 cloud session in this repository, on a
throwaway branch with a one-line diff.

- **Review skills in a subagent: they run, but weaker.** A built-in `general-purpose`
  subagent had the `Skill` tool and both `simplify` and `code-review` were offered. Both
  calls succeeded. The subagent had no `Agent` tool, so `/simplify` said so and ran as one
  inline pass instead of its parallel reviewers. `/code-review` ran as a fork and returned
  only its result, so whether it started reviewers of its own could not be seen. The
  documentation's "agents up to three levels deep" did not hold for this subagent.
  Decision (D4): the main conversation runs both on each session's diff.
- **The `Stop` gate in a subagent: not tested.** The plugin's hooks did not run in that
  session: its skills were not offered, and an edit by the main conversation left no
  `yotamake-edited` marker. So a subagent's edit could not be checked either. Whether a
  subagent's edit carries the parent's `session_id` is still the documentation's word. If it
  does not, the gate only misses a check after a subagent's edit; it does not block wrongly.
  The main conversation runs `scripts/check` on each session's work before its commit
  anyway.

## Consequences

- An approved effort can run to the end with one keypress per commit and one question at the
  end.
- The review of each session still happens, but the user reads the effort's work once, in
  the final report, not session by session.
- `multi-session` gains an Autopilot section, a `report.md` template and an `assumed`
  decision state.
- The main conversation runs the review on each session's diff, so the review's findings
  and fixes land in its context, though not the session's own reading.

## References

- `plugin/skills/multi-session/SKILL.md`, `plugin/skills/simple-session/SKILL.md`
- `plugin/hooks/stop-check-ran.sh`
- [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md),
  [ADR-0005](./0005-parallel-sessions-in-worktrees.md),
  [ADR-0006](./0006-commit-stop-by-project-hook.md)
- [Backlog](../backlog.md), "Spawn worktree sessions from the main conversation"

## Amendment (2026-11-12): the order of the end

Decision 6 put the version bump before the report. Writing the skill showed the effort's
folder holds the report, so it must last until the user answers the merge question. The
order is now: close-out (keeping the folder), the report, the one question; then, on yes,
each as its own commit: delete the folder, the version bump (still once, and still the last
commit on the mother branch), and the merge or pull request. On no, nothing is deleted or
bumped. The rest of the decision stands.

## Amendment (2026-11-17): autopilot becomes the default

[ADR-0009](./0009-autopilot-is-the-default.md) (Accepted) changes decision 1: autopilot
starts when the user approves S0, unless they turn it off. Everything else here stands.

## Amendment (2026-11-18): the `Stop` gate in a subagent, tested

"Tested" left open whether a subagent's hook calls carry the parent's `session_id`. A probe
on 2026-11-18 (Claude Code 2.1.327, headless runs with a hook that logged every event) shows
they do, and add `agent_id` and `agent_type`. This holds for Agent-tool subagents and for the
fork `/code-review` starts. [ADR-0010](./0010-commit-gate-by-step-table.md) builds on it: the
`Stop` gate now leaves out edits that carry an `agent_id`, so a background agent's edits do
not block the main conversation's turns, and the commit gate counts them for the worktree
they touched. The rest of this decision stands.
