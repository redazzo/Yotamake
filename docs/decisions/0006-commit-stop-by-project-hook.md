---
kind: decision
date: 2026-11-12
status: current
---

# ADR-0006: A project hook asks before commits, in place of the `ask` rule

- **Status:** Proposed. Nothing is built. It waits for the backlog trigger, and for the tests
  under "Before acceptance" to pass.
- **Date:** 2026-11-12
- **Work record:** none (effort "Low-priority backlog items")
- **Supersedes / amends:** would amend [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md)
  for `git commit` only. Builds on [ADR-0005](./0005-parallel-sessions-in-worktrees.md),
  rule 6.

## Context

ADR-0005 lets an effort opt in to worktree sessions that commit as soon as the checks and the
review pass (rule 6). Claude Code still prompts for each commit, because ADR-0003 puts
`Bash(git commit:*)` under `ask`. With several worktree conversations open at once, that is
one keypress per commit per conversation.

A `PreToolUse` hook cannot approve past an `ask` rule: Claude Code evaluates `ask` rules
whatever the hook returns. So the only documented way to drop the prompt for opted-in
branches is to remove the `ask` rule for `git commit` and let a hook decide instead: "ask"
for every commit, "allow" only on an opted-in branch.

That moves the commit stop from a permission rule to a script, which raises three problems:

- **Failing open.** If the script is missing, crashes or is skipped, nothing asks. A broad
  allow rule (`Bash(git:*)`, perhaps in the user's own settings) then lets the commit through
  silently. ADR-0003 rests on `ask` rules holding whatever else happens.
- **The Boundaries rule.** `CLAUDE.md` says hooks let the action through when they cannot
  decide. A commit hook that does so removes the stop.
- **Existing installs.** The installer merges `.claude/settings.json` and never removes
  anything, so it cannot take the `ask` rule out of a repository that already has it.

Claude Code facts are from its documentation (hooks and permissions pages), read on
2026-11-11, and are untested here. "Before acceptance" lists what must be tested.

## Decision

In the context of opted-in worktree sessions (ADR-0005, rule 6), facing one commit prompt per
commit per conversation, we propose to replace the `git commit` `ask` rule with a project
`PreToolUse` hook that fails closed, and against keeping the rule as it is, accepting that the
commit stop then depends on a script and on Claude Code running hooks.

The design, if accepted:

1. **Where.** A harness-owned script, `.claude/yotamake/commit-gate.sh`, run by a project
   `PreToolUse` hook on `Bash` in the template's `.claude/settings.json`, as ADR-0004 does for
   `SessionStart`. It works without the plugin.
2. **Fail closed in the hook command.** The command in `settings.json` runs the script and
   prints an "ask" decision itself when the script is missing, exits non-zero, or prints
   nothing for a command that mentions `commit`. A crash therefore asks. This is the one hook
   that does not let the action through when it cannot decide; the Boundaries line in
   `CLAUDE.md` would name it as the exception.
3. **What it matches.** Any Bash command that may run `git commit`: compound commands
   (`cd x && git commit`), `git -C <path> commit`, and aliases it cannot rule out. When unsure,
   it asks. Commands that are clearly not commits get no decision, so the normal rules apply.
4. **When it allows.** Only when all hold: the command runs in a linked worktree (the git dir
   differs from the common git dir), the branch is not the main branch, and that branch is
   opted in. Everything else gets "ask".
5. **The opt-in.** It cannot be read from the effort's `decisions.md`, which lives git-ignored
   in the main worktree. Instead `multi-session` writes a per-worktree marker when the user
   opts in (for example a file in the worktree's own git dir). Claude could write that marker
   too, so the step that writes it must itself be under `ask`, or the marker must be one the
   hook can check was set by the user. Which of these works is part of the tests below.
6. **Upgrade.** An `upgrades.md` entry adds the hook first, then removes `Bash(git commit:*)`
   from `ask` by hand (the installer cannot). Its check: the hook is present and the rule is
   gone. An install with the hook but still the rule keeps today's behaviour, so the order is
   safe.
7. **Everything else stays.** Merge, push, rebase, `reset --hard`, tag and the forced
   `switch` forms keep their `ask` rules (ADR-0003).

## Before acceptance

These must be tested with a current Claude Code, and the results written here as an
amendment, before the status moves to Accepted:

- a hook's "ask" still prompts under a broad `Bash(git:*)` allow rule, including one from a
  higher-priority settings source (user or managed settings);
- a hook's "allow" does not get past a `deny` rule, or an `ask` rule a project adds back;
- the hook command asks when the script is missing, exits non-zero, times out, or prints
  nothing;
- what happens when hooks are turned off (`disableAllHooks`) or the project settings are not
  trusted: if nothing asks then, that gap is written down as accepted or the design stops;
- the matcher catches the command forms in item 3, with a case in `scripts/test-hooks.sh`
  for each;
- the opt-in marker cannot be set by Claude without a prompt (item 5).

## Alternatives

- **Keep the `ask` rule (today).** One keypress per commit in opted-in worktree sessions. The
  stop rests on Claude Code's own rules. This stays in force until this ADR is accepted.
- **A hook that approves past the rule.** Not possible: `ask` rules win over a hook's "allow".
- **Drop the commit stop in worktrees without a hook.** Rejected: nothing would ask on a
  branch that is not opted in.

## Consequences

If accepted:

- Opted-in worktree sessions commit without a prompt. Every other commit still asks.
- The commit stop depends on Claude Code running project hooks and on the script; ADR-0003's
  guarantee no longer covers `git commit`.
- `CLAUDE.md` Boundaries gains its first exception: a hook that asks when it cannot decide.
- Existing installs keep the `ask` rule until someone applies the upgrade by hand.

While Proposed, nothing changes.

## References

- [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md),
  [ADR-0004](./0004-project-session-start-hook-sets-hooks-path.md),
  [ADR-0005](./0005-parallel-sessions-in-worktrees.md)
- `plugin/template/.claude/settings.json` (the `ask` list and the project hooks)
- `plugin/install.sh` (settings merge), `plugin/reference/upgrades.md`
- [Backlog](../backlog.md), "Let a hook approve commits in opted-in worktrees"
