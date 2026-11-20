---
kind: decision
date: 2026-11-20
status: current
---

# ADR-0012: Autopilot runs an approved effort in subagents, and commits and reviews it once

- **Status:** Accepted (2026-11-20), amended 2026-11-20
- **Date:** 2026-11-20
- **Work record:** none yet
- **Supersedes:** [ADR-0007](./0007-autopilot-runs-sessions-in-subagents.md) (with its three
  amendments) and [ADR-0009](./0009-autopilot-is-the-default.md). This ADR restates both as
  they stand, and changes how commits and the review work.
- **Amends:** [ADR-0010](./0010-commit-gate-by-step-table.md), item 5: its last sentence
  ("each autopilot session … needs its own review") holds only in the committed setup.
  [ADR-0011](./0011-session-sized-by-review-revert-and-decisions.md): under autopilot in the
  local setup, an effort is reviewed and reverted as one diff.
- **Builds on:** [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md) (every commit and
  merge prompts); [ADR-0005](./0005-parallel-sessions-in-worktrees.md), which rejected a
  conversation driving sessions as subagents, for work run by the user.

## Context

A multi-session effort needs the user between every session: a `/clear`, the resume line
and a report before each commit. Once S0's spec, plan and Design are approved, most of that
waiting adds little. ADR-0007 (2026-11-12) added autopilot as an opt-in. ADR-0009
(2026-11-17) made it the default. ADR-0007 was amended three times: the order of its end
steps (2026-11-12), the pointer to ADR-0009 (2026-11-17), and a test showing a subagent's
hook calls carry the parent's `session_id` (2026-11-18).

Under those ADRs each session landed as its own commit, after its own review. Every commit
prompts (ADR-0003), so an effort of four sessions cost about seven prompts. The user asked
for one commit per effort (2026-11-20). Without per-session commits, a per-session review
would re-read every earlier session, since both review skills read the whole
`git diff HEAD`.

## Decision

In the context of a multi-session effort whose spec, plan and Design the user approved in
S0, facing a stop, a `/clear` and a commit between every session, we decided for autopilot
on by default, running each session in a subagent on one mother branch, and in the local
setup reviewing and committing the effort once at the end (and against opt-in autopilot, or
a commit and review per session) to let an approved effort run to the end with three
prompts, accepting that the one review reads a diff over the session limit and that the
effort is reverted as a whole.

1. **On by default.** Approving S0's spec and plan starts autopilot, unless the user turns
   it off in the same answer ("approve, step through"). S0's last message says so, and lists
   each open decision with the recommendation autopilot will take. The folder's `README.md`
   records `Autopilot: on` or `off`, and `decisions.md` has a row for the choice. The user
   can turn it on or off when resuming.
2. **One mother branch, one subagent per session.** No session gets a branch. The main
   conversation starts one built-in agent per session, in turn; its fresh context stands in
   for `/clear`. Each session still follows `simple-session`: design check, work, owning
   doc, `scripts/check`, the docs ledger. The main conversation runs `scripts/check` again
   when the agent returns.
3. **Local setup: one review, one commit.** Sessions neither review nor commit. After
   close-out, the main conversation runs the review (`/simplify`, the design read,
   `/code-review`) once, on the whole uncommitted effort. On the user's yes the effort lands
   as one commit, then the version bump as its own commit, then the merge or pull request.
4. **Committed setup: as before.** Its container can be thrown away, so each session is
   reviewed, committed as `(S<N>)` and pushed. At the end it deletes its folder in a commit
   of its own, then bumps.
5. **Stops kept.** Every `git commit` and `git merge` prompts (ADR-0003). Autopilot never
   pushes, merges into the main branch, tags or deploys without a yes.
6. **Pauses.** The run stops and asks on a design conflict, on a check that still fails
   after two fix attempts, and on a session that cannot finish within its plan. An open
   decision does not stop it: the session takes the recommendation, marked `assumed`.
7. **One end.** Close-out (keeping the folder), the review (local setup), one report, and
   one question: commit and merge, or commit, push and open a pull request. On no, nothing
   is committed, deleted or bumped.
8. **Turned off partway.** In the local setup, the work done so far is reviewed and
   committed as one, with the same trade-off; then the effort runs session by session.

### Alternatives considered

- **Opt-in autopilot (ADR-0007).** Rejected: the common case should not need a phrase.
- **Default only when S0 leaves no open decision.** Safer on `assumed` answers; rejected for
  one simple rule.
- **A commit and a review per session (ADR-0007).** One prompt per session; rejected by the
  user.
- **One commit, with a review per session on the growing diff.** Re-reads earlier sessions
  each time and repeats findings.
- **Removing the commit prompt.** Needs [ADR-0006](./0006-commit-stop-by-project-hook.md),
  still Proposed.
- **One branch per session merged into the mother branch.** Twice the merge prompts.
- **Parallel sessions under autopilot.** More moving parts; ADR-0005 still covers parallel
  work run by the user.

## Consequences

- **Positive:** an approved local effort costs three prompts: the effort commit, the bump
  and the merge. Review runs once instead of once per session.
- **Negative / accepted trade-offs:** the review reads a diff over the session limit by
  construction, so it is weaker than a per-session one (ADR-0011, "Review"). Findings arrive
  at the end. One session cannot be reverted alone. Open decisions are more often
  `assumed`.
- **Invariants this protects:** each session is still sized by `simple-session`, "Check the
  size", runs in one agent and passes `scripts/check`. The commit gate (ADR-0010) needs no
  code change: in the local setup the one review comes after every edit in its window.

## Tested

From ADR-0007, 2026-11-12 (Claude Code 2.1.322): a built-in subagent can call `/simplify`
and `/code-review`, but `/simplify` ran without its parallel reviewers, so the main
conversation runs the review. 2026-11-18 (2.1.327): a subagent's hook calls carry the
parent's `session_id`, plus `agent_id`; the `Stop` gate leaves such edits out.

## References

- `plugin/reference/autopilot.md`, `plugin/skills/multi-session/SKILL.md`,
  `plugin/skills/multi-session/templates/report.md`
- `plugin/hooks/steps.json`, `plugin/hooks/steps.mjs`
- `plugin/evals/22-multi-session-autopilot-offer/`

## Amendment (2026-11-20): the commit no longer prompts

[ADR-0013](./0013-commit-gated-not-prompted.md) moves `git commit` from `ask` to `allow`. In
rule 5, `git merge` still prompts; `git commit` no longer does, and waits for the user's yes
to the final report instead. The rest of this decision stands.
