---
kind: record
date: 2026-11-11
status: historical
---

# Subagents for S0, and parallel sessions in worktrees

**Date:** 2026-11-11 · **Status:** live in 0.22.0

**Why.** The backlog item "Use subagents and worktrees" asked for two things. First, run
`multi-session`'s S0 analysis and the session review in subagents, so the main context stays
small. Second, let independent sessions of one effort run at the same time in git worktrees.
It ran as a five-session effort.

**Decided.**

- Delegation uses Claude Code's built-in agents, with the brief written in the skill. No
  plugin `agents/` folder, so the Architecture Style is unchanged.
- The review stays in the main context. `/simplify` and `/code-review` already run their own
  agents, and the eval graders probably miss Skill calls made inside a subagent. (Not
  documented; neither was whether a subagent may call the Skill tool.) A test showed that a
  subagent's hook calls carry the parent's `session_id`, so the `Stop` gate would have held.
- [ADR-0005](../../decisions/0005-parallel-sessions-in-worktrees.md): worktrees are sibling
  folders made with `git worktree add`, not Claude Code's `.claude/worktrees/`, so branch
  prefixes stay. The user opens one Claude Code conversation per worktree, rather than the
  main conversation spawning a worktree subagent, so every session keeps its own stop
  (ADR-0003). The working folder stays in the main worktree. Each session gets a `Needs:`
  line. Merges go one at a time, and the release steps happen at merge time.
- Commit opt-in: an effort may let worktree sessions commit on their own branch as soon as
  checks and review pass, without the stop-and-report exchange. Claude Code still prompts:
  the docs say a `PreToolUse` hook "allow" cannot beat an `ask` rule. Dropping the `ask` rule
  in favour of a deciding hook was left in the backlog.
- Worktree setup became one `Worktree setup` line in **Branching and releases**, not a new
  `CLAUDE.md` section. So the template gained one line and an `upgrades.md` entry.

**Built.**

- 0.21.0 (S1): `multi-session` S0 hands its reading to built-in agents, one per area.
  `simple-session`, "Review", says why the review stays inline.
- 0.21.1 (S3): `lib.sh` `hook_root`. Hooks take their root from the edited file's
  repository, else the hook input's `cwd` (which follows `EnterWorktree`, unlike
  `CLAUDE_PROJECT_DIR`), else `CLAUDE_PROJECT_DIR`. `pre-edit-protect.sh` had let protected
  patterns with a slash through in a linked worktree; fixed. `session-context.sh` in a
  linked worktree says "Worktree of <main>" and lists the main worktree's efforts.
  `scripts/test-hooks.sh` tests with a real linked worktree. It also unsets the `GIT_*`
  variables git exports to hooks, which had made `git add` in a test repository fail under
  the pre-commit hook.
- 0.22.0 (S4): `multi-session`, "Running sessions in parallel", the `Needs:` line, and the
  `Worktree setup` line. `simple-session` skips the branch cut in a worktree session.

**Not tested.** What `CLAUDE_PROJECT_DIR` is when `claude` starts inside a
`git worktree add` tree. This no longer matters, since hooks prefer `cwd`. A conversation
that edits a linked worktree by absolute path without `EnterWorktree` still escapes the
`Stop` gate, because its `cwd` is the main tree. ADR-0005 does not support that flow. The
eval cases that cover these changes were not run.

**Left.** In [the backlog](../../backlog.md): "Delegate the review's design read", "Let a
hook approve commits in opted-in worktrees", "Spawn worktree sessions from the main
conversation" and "Plugin agent definitions".
