---
kind: decision
date: 2026-11-11
status: current
---

# ADR-0005: Independent sessions of one effort may run in parallel worktrees

- **Status:** Accepted (2026-11-11)
- **Date:** 2026-11-11
- **Work record:** none yet (effort "Subagents and worktrees")
- **Supersedes / amends:** none. Keeps [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md)
  as it is.

## Context

A multi-session effort runs its sessions one after another: one branch, one merge, then the
next. Some sessions do not depend on each other and touch different files, so they could run
at the same time. Git worktrees let several branches be checked out at once, and the
main-branch hook already allows edits in a linked worktree on its own branch.

Running sessions at once raises questions the method did not answer:

- **Where worktrees live.** Claude Code's own worktrees (`claude --worktree`,
  `EnterWorktree`) go in `.claude/worktrees/<name>/` on a branch named `worktree-<name>`. The
  caller cannot choose the branch name, and the folder is not git-ignored automatically. Its
  `.worktreeinclude` file copies ignored files only into worktrees Claude creates.
- **Which tree the hooks look at.** After `EnterWorktree`, `CLAUDE_PROJECT_DIR` stays at the
  main checkout while the hook's `cwd` moves to the worktree, so hooks that read
  `CLAUDE_PROJECT_DIR` check the wrong tree.
- **The working folder.** In the local setup it is git-ignored, so a new worktree has none.
  A committed folder would be copied per branch and conflict at merge.
- **Shared state.** Two sessions update the same `plan.md`, `log.md` and docs ledger.
- **Merges and releases.** Two branches cut from the same base both do the project's
  release steps (a version bump, say) and collide at the second merge.
- **Ignored files.** A new worktree has no `.env`, no `node_modules`, no build output. Local
  permission approvals are shared from the main checkout, but other ignored files are not.
- **Stop points.** Approving every commit in several conversations at once is tiring. A
  hook cannot remove the prompt: Claude Code evaluates `ask` rules whatever a `PreToolUse`
  hook returns, and no permission mode skips them.

Claude Code facts are from its documentation (worktrees, hooks, permissions and permission
modes pages), read on 2026-11-11.

## Decision

In the context of multi-session efforts with sessions that do not depend on each other,
facing the cost of running them strictly in turn, we decided to let such sessions run at the
same time, each in its own git worktree, under these rules:

1. **Place.** A parallel session's worktree is a sibling folder made with plain git:
   `git worktree add ../<repo>-s<N> -b <prefix>/<slug>`, cut from an up-to-date main branch,
   with the project's usual branch prefix.
2. **Driver.** The user opens a separate Claude Code conversation inside each worktree. Each
   conversation runs one session as usual, so its hooks see that worktree as the project.
3. **When.** Each session in `plan.md` has a `Needs:` line (`Needs: S1, S2` or
   `Needs: none`). A session may start only when every session it needs is done. Two sessions
   may run at the same time only when they change different files. Parallel sessions are
   for the local setup only.
4. **Working folder.** It stays in the main worktree. Sessions in other worktrees reach it by
   its absolute path. Each session edits only its own `## S<N>` section of `plan.md`, and only
   appends to `log.md` and the docs ledger.
5. **Setup.** A worktree may need setup steps before its checks pass (copy `.env`, install
   dependencies). These are project facts: they go in the project's `CLAUDE.md`, never in a
   skill.
6. **Commits.** An effort may opt in, in its `decisions.md`, to let worktree sessions commit
   on their own branch as soon as the checks and the review pass, without stopping to report
   and propose the commit first. The `ask` rule stays, so Claude Code still prompts for each
   commit. Merge, push, rebase, `reset --hard`, tag and the release keep their full stop.
7. **Merges.** Branches merge one at a time, from the main worktree. A branch that merges
   after another has landed first merges the main branch into itself, re-runs the checks, and
   only then does the project's release steps (`CLAUDE.md`, **Branching and releases**). After
   its merge, the worktree is removed.

We decided against:

- **Claude Code's own worktrees** (`.claude/worktrees/`). Their branch names ignore the
  project's prefixes, the folder must be git-ignored, and hooks there read the wrong project
  directory. A user may still prefer them; the rules above do not depend on the place.
- **One conversation driving worktree subagents.** The sessions would run without their own
  stop before commit, and hooks would need to find the right tree from inside a subagent,
  which Claude Code does not document.
- **Copying the working folder into each worktree.** The copies drift apart.
- **A committed working folder.** Each branch gets its own copy, and parallel sessions
  conflict on it at merge.
- **Letting a hook approve commits** (for now). It cannot override an `ask` rule. The only
  documented route is to drop the `ask` rule for `git commit` and have a project hook ask for
  every commit except opted-in worktree branches. That weakens a stop that today rests on
  Claude Code's own rules, so it waits in the backlog until the prompt proves too costly.

We accept that the user runs several conversations and decides the merge order, that each
new worktree may need setup, and that commits in parallel sessions still need a keypress.

## Consequences

- Independent sessions can run at once, and each keeps its own context, checks, review and
  stop before merge.
- `plan.md` gains a `Needs:` line per session. The order rule of `multi-session` still holds
  for sessions that depend on each other.
- Hooks and the session-start context must work when Claude Code is started inside a linked
  worktree: the session context lists efforts from the main worktree's working folder.
- Release steps move to merge time for parallel branches, so two branches never claim the
  same version.
- Projects that use parallel sessions name their worktree setup steps in `CLAUDE.md`.
- ADR-0003 is unchanged: every commit, merge, push, rebase, reset and tag still prompts.

## References

- `plugin/skills/multi-session/SKILL.md` (sessions, working folder, order)
- `plugin/hooks/lib.sh` (`repo_path_of`, `gate_file`), `plugin/hooks/pre-edit-main-branch.sh`
- `plugin/template/.claude/yotamake/session-context.sh` (lists efforts at session start)
- [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md),
  [ADR-0004](./0004-project-session-start-hook-sets-hooks-path.md)
- [Backlog](../backlog.md), "Let a hook approve commits in opted-in worktrees"

## Amendment (2026-11-12): autopilot may drive session subagents

[ADR-0007](./0007-autopilot-runs-sessions-in-subagents.md) allows one option this ADR
turned down, one conversation driving session subagents, for one case only: an effort the
user put on autopilot after approving its spec, plan and Design. Those sessions run one at a
time on one branch, not in parallel worktrees. Everything else here stands.
