---
kind: decision
date: 2026-11-20
status: current
---

# ADR-0013: `git commit` is gated by the hook, not prompted; other stop points keep their `ask` rules

- **Status:** Accepted (2026-11-20)
- **Date:** 2026-11-20
- **Work record:** none
- **Supersedes:** [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md), which this ADR
  restates with one change: `git commit` moves from `ask` to `allow`.
  [ADR-0006](./0006-commit-stop-by-project-hook.md), a proposal never built, whose fail-closed
  commit hook this ADR does without.
- **Amends:** [ADR-0010](./0010-commit-gate-by-step-table.md): its statements that the `ask`
  rule on `git commit` stays and that a commit which passes the gate still asks no longer
  hold, nor does its reason for needing no Boundary exception ("this gate does not replace
  anything"). The gate itself is unchanged.
  [ADR-0005](./0005-parallel-sessions-in-worktrees.md), rule 6: the effort's opt-in is the
  user's yes for its worktree commits; nothing prompts.
  [ADR-0012](./0012-autopilot-one-commit-per-effort.md), rule 5: `git merge` still prompts;
  `git commit` waits for the user's yes to the report, with no prompt.
- **Builds on:** [ADR-0010](./0010-commit-gate-by-step-table.md) (the commit gate refuses a
  commit until `scripts/check` and the review have run).

## Context

ADR-0003 put `git commit`, `merge`, `push`, `rebase`, `reset --hard` and `tag` under `ask`,
so Claude Code prompts for each, whatever a skill says. At the time nothing else checked a
commit.

Since ADR-0010, a plugin hook refuses `git commit` until `scripts/check` has passed since
the last edit and both review skills have run, and another refuses a commit on the main
branch. The skills also stop and ask the user before they commit (`simple-session`, "Stop
and report"). So the user has already said yes in the chat, and the hook has checked the
steps, by the time the commit runs. The permission prompt asks the same question a second
time. The one commit without a yes in the chat is an opted-in worktree session (ADR-0005,
rule 6), where the user's opt-in in `decisions.md` stands for that yes.

A commit is also the cheapest stop point to undo. It stays on the session's branch, reaches
no one until a merge or push, and `git reset` or a new commit reverses it. The merge, push,
rebase, `reset --hard` and tag stop points reach other people or lose work, and keep their
prompt.

ADR-0006 proposed a fail-closed hook that would ask in place of the rule. It was never
built: it needed tests of hook precedence and an opt-in marker. This ADR does not add a hook
that asks; it relies on the gate that already exists and on the skill's question.

## Decision

In the context of the stop points before outward-facing git actions, facing a permission
prompt on every commit that repeats a question the skill already asked and the gate already
checked, we decided to move `Bash(git commit:*)` from `ask` to `allow`, and against keeping
the prompt or building ADR-0006's hook, accepting that the commit stop now rests on the
skill and the commit gate rather than on Claude Code's own rules.

1. **The `ask` rules.** The installer merges `ask` rules for `git merge`, `push`, `rebase`,
   `reset --hard` and `tag` (and the forced `switch` and `branch` forms) into the
   repository's `.claude/settings.json`, so Claude Code asks every time. Projects add their
   deploy command to the same list. This rests on `ask` winning over a matching `allow`
   rule, including a broad one such as `Bash(git:*)` and one from a higher-priority settings
   source, as tested on 2026-10-28 with Claude Code 2.1.312.
2. **`git commit` is allowed.** The template's `.claude/settings.json` lists
   `Bash(git commit:*)` under `allow`. The commit gate (ADR-0010) and the main-branch rule in
   `pre-bash-git.sh` still refuse a commit they can decide against, and the pre-commit hook
   still runs `scripts/check --staged`.
3. **The installer drops the old rule.** When it merges settings, the installer removes
   `Bash(git commit:*)` from the `ask` list in `.claude/settings.json` on every run, so an
   existing install stops prompting. It is the only entry the installer ever removes: one
   the harness itself added and has retired. `CLAUDE.md`, Boundaries, names it as the
   exception. A repository that wants the prompt back adds the rule under `ask` in
   `.claude/settings.local.json` or user settings, which the installer does not touch.
4. **Amended stop points elsewhere.** An opted-in worktree session (ADR-0005, rule 6)
   commits on its own branch without a prompt: the opt-in is the user's yes for that
   effort's commits, and its merges still ask. Under autopilot (ADR-0012, rule 5) the
   effort's commit waits for the user's yes to the final report; the merge still prompts.
5. **Other commands with the same effect.** The rules match command text, so `CLAUDE.md`,
   Conventions, still says not to work around the remaining `ask` rules.

### Alternatives considered

- **Keep the prompt (ADR-0003).** Safe, but a second keypress for a question already
  answered, once per commit and once per worktree conversation.
- **ADR-0006's fail-closed project hook.** More moving parts and untested precedence, to
  keep a prompt this ADR finds redundant.
- **Leave the installer unchanged and document a manual removal.** Existing installs would
  keep prompting until someone edited their settings, and the next refresh would not help.

## Consequences

- **Positive:** a session or an autopilot effort commits after the user's yes without a
  second prompt. Parallel worktree sessions (ADR-0005, rule 6) commit without one keypress
  each.
- **Negative / accepted trade-offs:** the commit stop depends on the skills and on the
  plugin's hooks running. With the plugin not loaded or hooks turned off, nothing but the
  pre-commit hook stands between Claude and a commit. When the gate cannot decide, it lets
  the commit through (ADR-0010), and no prompt catches it: the gate now stands where the
  `ask` rule stood, yet still fails open, which ADR-0010 argued it would never need to. An
  opted-in worktree session commits with no yes beyond the opt-in. A commit is local and easy to
  undo, so this is accepted.
- **Invariants this protects:** merge, push, rebase, `reset --hard`, tag and the deploy
  command still prompt whatever a skill says. The installer removes nothing from
  `.claude/settings.json` but the retired commit rule.

## References

- `plugin/template/.claude/settings.json` (the `allow` and `ask` lists)
- `plugin/install.sh` (settings merge), `scripts/test-install.sh`
- `plugin/hooks/pre-bash-git.sh` (the commit gate and the main-branch rule)
- [docs/reference/hooks.md](../reference/hooks.md), "Stop points: the ask rules"
- `plugin/reference/upgrades.md`
