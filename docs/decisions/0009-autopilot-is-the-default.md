---
kind: decision
date: 2026-11-17
status: superseded
---

# ADR-0009: Autopilot is the default for a multi-session effort once S0 is approved

- **Status:** Superseded by [ADR-0012](./0012-autopilot-one-commit-per-effort.md) (2026-11-20). Was Accepted (2026-11-17), when `multi-session`, `plugin/reference/autopilot.md`
  and eval case 22 changed to match.
- **Date:** 2026-11-17
- **Work record:** none yet
- **Amends:** [ADR-0007](./0007-autopilot-runs-sessions-in-subagents.md), decision 1
  ("Opt-in"): autopilot is now on unless the user turns it off. The rest of ADR-0007 stands.
- **Builds on:** [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md) (every commit and
  merge still prompts); [ADR-0007](./0007-autopilot-runs-sessions-in-subagents.md) (how
  autopilot runs: one mother branch, one subagent per session, pauses, one report at the end).

## Context

Under ADR-0007, S0 ends with a request to approve the spec and plan, and an offer: say "run
autopilot" and the remaining sessions run without the user. Without those words, each
session stops for a report, a commit and a `/clear`, and the user resumes the next one by
hand.

The user wants autopilot to be the default. Once the spec, the plan and its Design section
are approved, the stop between sessions mostly asks the user to read work they already
agreed to in outline. Users who want to read each session should say so, not the other way
round.

The risks were reviewed before deciding (2026-11-17, in conversation, not measured):

- **Decisions become assumptions.** S0 leaves each question open until the session that
  needs it. Under autopilot an open question takes its recommendation and is marked
  `assumed`. As the default, that becomes the normal path, and a wrong guess early carries
  into later sessions.
- **Not fully hands-off.** Every `git commit` still prompts (ADR-0003), so a run waits at
  each session's commit until someone answers.
- **One review at the end.** The user reads the effort once, as one mother branch, not
  session by session. A problem found then costs more rework.
- **Little evidence.** Autopilot dates from 2026-11-12. Whether the `Stop` gate works in a
  subagent is untested (ADR-0007, "Tested"). Eval case 22 checks only the offer, and no case
  runs a whole autopilot effort. The eval cases that need git are blocked (backlog, "Eval
  sandbox denies `git`"). The cost of a run is unmeasured.

A narrower default was considered: autopilot by default only when S0 leaves no open
decisions. The user chose the plain default.

## Decision

In the context of a multi-session effort whose spec, plan and Design the user approves at
the end of S0, facing a stop and a `/clear` between every session that most users do not
want, we decided for autopilot as the default (and against keeping it opt-in, or making it
the default only when no decisions are open) to let an approved effort run to the end
without the user steering each session, accepting that open decisions are more often taken
as `assumed` and that the user reviews the work once, at the end.

1. **On by default.** When the user approves S0's spec and plan, autopilot starts, unless
   they turn it off in the same answer. S0's last message says this, and how to turn it off
   (for example, "approve, step through"). S0 itself still starts no session before the
   approval.
2. **Opt-out is recorded.** The folder's `README.md` says `Autopilot: on` or
   `Autopilot: off` under **Setup**, and `decisions.md` has a row saying which the user
   chose. Turned off, the effort runs session by session as `multi-session` already says.
   The user can turn it on or off again when resuming.
3. **Open decisions shown up front.** S0's last message lists each open decision in
   `decisions.md` with the recommendation autopilot will take for it, so approving the plan
   is a visible choice to accept them. The user can answer any of them there. Questions
   still stay open in `decisions.md` until their session, as now.
4. **Everything else in ADR-0007 stands:** the stops kept (every commit and merge prompts;
   no push, merge into the main branch, tag or deploy without a yes), the pauses, the one
   mother branch, the review of each session's diff in the main conversation, and the one
   report and merge question at the end.

### Alternatives considered

- **Keep autopilot opt-in (ADR-0007).** Rejected by the user: the common case should not
  need a phrase to remember.
- **Default only when S0 leaves no open decisions.** Safer on the `assumed` risk, but rejected
  by the user in favour of one simple rule.
- **Remove the commit prompt so autopilot runs unattended.** Out of scope: that needs
  [ADR-0006](./0006-commit-stop-by-project-hook.md), which is Proposed and untested.

## Consequences

- **Positive:** an approved effort runs to the end with one keypress per commit and one
  question at the end, with no phrase to remember.
- **Negative / accepted trade-offs:** more decisions are made as `assumed` and seen only in
  the final report; the user reads the work once, at the end; the least-tested path in the
  harness becomes the common one; the site's "Small steps, and a person decides" needs
  rewording.
- **Invariants this protects:** autopilot never starts before the user approves S0; turning
  it off is always possible, at S0 or when resuming; every commit and merge still prompts.

**Work that follows,** in one branch with a minor version bump: `multi-session` step 6 of
"Starting a new effort" and its "Autopilot" section; `plugin/reference/autopilot.md`,
"Turning it on"; eval case 22's prompt and graders (it now expects autopilot to start on
approval, and nothing before it); `README.md`, Autopilot; the `site/` pages that describe
autopilot or the session flow; `CHANGELOG.md`. Then set this ADR to Accepted.

## References

- `plugin/skills/multi-session/SKILL.md`, `plugin/reference/autopilot.md`
- `plugin/evals/22-multi-session-autopilot-offer/`
- [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md),
  [ADR-0006](./0006-commit-stop-by-project-hook.md),
  [ADR-0007](./0007-autopilot-runs-sessions-in-subagents.md)
- [Backlog](../backlog.md), "Eval sandbox denies `git`" and "Show that the harness helps"
