# Spec — Commit gate for opted-in worktree sessions

Agreed <yyyy-mm-dd>. What must be true when this work is done. One page at most.

## Problem

Parallel worktree sessions that opted in to committing (ADR-0005, rule 6) still get one
commit prompt per commit, per conversation. ADR-0006 proposes a hook that drops that prompt
on opted-in worktree branches only, if its "Before acceptance" tests pass.

## Scope

- Run ADR-0006's "Before acceptance" tests and record them in the ADR.
- If they pass: a harness-owned `commit-gate.sh` run by a project `PreToolUse` hook, the
  `Bash(git commit:*)` `ask` rule removed from the template, an opt-in marker that
  `multi-session` writes, an `upgrades.md` entry, and the docs.

## Not in scope

- Merge, push, rebase, `reset --hard`, tag and forced `switch`: they keep their `ask` rules.
- Removing the `ask` rule from existing installs automatically (the installer cannot).
- Spawning worktree sessions from the main conversation (separate backlog item).

## Acceptance criteria

- **A1** — In a linked worktree, on a branch that is not the main branch and is opted in, a
  plain `git commit` (also via `cd x &&` or `git -C <worktree>`) runs with no prompt.
- **A2** — Any other `git commit` prompts: in the main worktree, on the main branch, on a
  branch that is not opted in, or with `-C` pointing outside the opted-in worktree.
- **A3** — A command that may commit but that the gate cannot read for sure (`bash -c`,
  `eval`, `$(...)`, backticks, `env`, `sudo`, `xargs`, a git alias, an unclosed quote)
  prompts. A command that clearly does not commit gets no decision.
- **A4** — If the script is missing, exits non-zero, prints nothing for a command that
  mentions `commit`, or times out, the commit does not go through without a prompt (asked,
  or blocked).
- **A5** — Claude cannot set the opt-in marker without a prompt.
- **A6** — A fresh install has the hook and no `Bash(git commit:*)` rule. Skipping
  `commit-gate.sh` keeps a commit stop. Re-running the installer on an older install adds the
  hook and keeps the existing rule.
- **A7** — An `upgrades.md` entry lets an older install check and move to the gate by hand.
- **A8** — `scripts/test-hooks.sh` has a case for each command form in A1–A3 and each failure
  in A4; `scripts/test-install.sh` has the cases in A6.
