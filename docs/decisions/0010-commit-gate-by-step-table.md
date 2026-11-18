---
kind: decision
date: 2026-11-18
status: current
---

# ADR-0010: A plugin hook refuses `git commit` until the check and the review are done, by one step table

- **Status:** Accepted (2026-11-18)
- **Date:** 2026-11-18
- **Work record:** [Commit gate on session steps](../records/2026/2026-11-18-commit-gate.md)
- **Amends:** [ADR-0008](./0008-facts-hooks-read-in-project-conf.md), item 4 ("Readers"):
  `plugin/hooks/steps.mjs` is a second reader of `project.conf` inside the plugin, in Node.
  It also reads the edited path itself, not with `tool_file_path`. See "Readers" below.
- **Builds on:** [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md) (the `ask` rule
  on `git commit` stays; this adds a refusal in front of it);
  [ADR-0008](./0008-facts-hooks-read-in-project-conf.md) (the gate reads `main-branch` and
  `docs` from `project.conf`).

## Context

A session should run `scripts/check` and both review skills (`/simplify`, `/code-review`)
on the final diff before it commits. Sessions sometimes commit before one of these has run.
Each past miss was fixed by adding wording to a skill. More wording makes the next miss more
likely, and there is little room left: `scripts/check` caps a `SKILL.md` at 250 lines, and
`simple-session` is at 245.

One step is already enforced by a hook. `stop-check-ran.sh` stops a turn from ending when
code was edited after the last passing check. It compares the mtimes of two marker files in
the git dir: `yotamake-edited` and the `yotamake-check-passed` stamp that `scripts/check`
writes. Nothing records whether a review ran, and no hook looks at the check or the review
before a commit. `pre-bash-git.sh` already parses `git commit` out of compound commands, but
it only blocks `--no-verify` and commits on the main branch.

Before this ADR, a probe (2026-11-18, Claude Code 2.1.327, four headless runs with a hook
that logged every event) found what hooks can see:

- A Skill call made by Claude fires `PreToolUse` with `tool_name` `Skill` and `tool_input`
  `{"skill":"simplify"}` or `{"skill":"code-review","args":"low"}`. Built-in skills have no
  prefix; a plugin skill is `"<plugin>:<name>"`.
- A command the user types (`/simplify`) fires no `PreToolUse`. It fires
  `UserPromptExpansion` with `"command_name":"simplify"`.
- Hook calls from a subagent carry the parent's `session_id`, plus `agent_id` and
  `agent_type`. This holds for Agent-tool subagents and for the fork `/code-review` starts.
- `cwd` is the folder `claude` started in, even after a `cd`. Only a subagent with
  `isolation: worktree` has its worktree as `cwd`.
- A failing Bash command fires `PostToolUseFailure`, not `PostToolUse`.
- `/simplify` runs inline and Claude applies its fixes with Edit afterwards. `/code-review`
  forks, and Claude fixes its findings when the fork ends. So after any fix, the last review
  is older than the last edit. A rule of "both reviews after the last edit" would refuse every
  reviewed commit that fixed something.

## Decision

In the context of a session's commit, facing steps that skill wording does not reliably
enforce, we decided for a plugin hook that refuses `git commit` while a step is missing,
driven by one step table and one evaluator over a per-worktree events log (and against a
workflow framework, a bash evaluator, state keyed by session, or "review after the last
edit"), to move the commit order out of skill text, accepting that the hook sees only what
Claude Code reports to it.

1. **One step table.** `plugin/hooks/steps.json` lists, for each gated action (`commit`,
   and the existing `stop`), the events that must come after the last `edit`, the events
   that must fall in the review window (item 5), and the skips (item 7). The order lives in
   this one file. Adding a step is a table change, not a new hook.
2. **One evaluator.** `plugin/hooks/steps.mjs`, dependency-free Node (hooks already need
   Node 18+). It parses the hook input once, appends events, and answers allow or refuse
   for an action. `stop-check-ran.sh` moves onto it, so the Stop gate and the commit gate
   use the same rules.
3. **An events log per worktree.** `yotamake-events` in the worktree's git dir, beside the
   existing markers. One JSON line per event, in the order written, each with the HEAD it
   saw. It is keyed by worktree, not by session: a subagent's edits and reviews count for
   the checkout they touched. An edit event uses the git dir of the edited file, as
   `gate_file` does; a Skill or prompt event, which has no path, uses the git dir of `cwd`.
4. **Event sources.**
   - `edit`: `PostToolUse` on the edit tools. A doc edit is marked `doc` (the `docs` globs
     in `project.conf`); git-ignored files are left out.
   - `review`: `PreToolUse` on `Skill` whose `skill` is exactly `simplify` or
     `code-review`, and `UserPromptExpansion` whose `command_name` is one of those. A
     plugin's `x:simplify` is a different skill and does not count.
   - `prompt`: `UserPromptSubmit`, skipping prompts that start with `<task-notification>`
     (a background agent finishing fires it too).
   - `check`: the `yotamake-check-passed` stamp that `scripts/check` already writes on a
     passing full run, read as it is now. The project-owned `scripts/check` does not change.
5. **The review rule.** Both review skills must have run inside the review window, after
   the window's first code edit. The window starts at the later of two points: the last
   commit (the first event whose HEAD differs from the one before), and the last user prompt
   before the last code edit. Fixes made in the review's own turn therefore count as
   reviewed. A change asked for in a later turn needs a new review, as `simple-session`
   step 6 says. The commit boundary means each autopilot session, which runs inside one
   parent turn, needs its own review.
6. **The check rule.** For a turn's end, the check must have passed after this session's
   last code edit; this is the rule `stop-check-ran.sh` had before, except that edits a
   subagent made (`agent_id` set) do not count, so a background agent's edits do not block
   the main conversation's turns. For a commit, it must
   have passed after the last edit of any kind, docs included, so a docs-only branch is
   checked too (item 7).
7. **Skips.** On a branch whose changes against the main branch are all docs (the `docs`
   globs in `project.conf`), the commit needs the check but no review. Untracked files
   count as changes, so a code file about to be added by `git add x && git commit` is
   seen. A commit message with
   a `Review-skipped: <reason>` trailer needs no review events either, so the skip is in
   history. The release bump commit in `plugin/reference/integrate.md` carries one, because
   it edits version files after the review. Neither skip waives the check.
8. **Where.** In the plugin's `pre-bash-git.sh`, which already recognises a `git commit`.
   It refuses with exit 2 and names the missing step on stderr, as the other hooks do. It
   reads the message from `-m`, `--message`, `-F`/`--file` and the heredoc forms; a message
   it cannot read counts as having no trailer. A commit that finishes a merge (`MERGE_HEAD`
   exists) is not gated, as `git merge` is not.

**The Boundary holds.** `CLAUDE.md` says hooks let the edit through when they cannot decide.
The gate refuses only when it can decide: it read its input, the events log and git, and
sees a step missing. A parse error, a missing or unreadable log, a git error or a missing
Node lets the commit through. ADR-0006 needed an exception to the Boundary because it
replaced the `ask` rule and had to fail closed. This gate does not replace anything, so it
needs no exception.

**Relation to other ADRs.**

- [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md): the `ask` rule on `git commit`
  stays. A commit that passes the gate still asks the user.
- [ADR-0006](./0006-commit-stop-by-project-hook.md) stays Proposed and separate. Its
  project-side, fail-closed hook would replace the `ask` rule in opted-in worktrees. This
  gate does not need it and does not build on it.
- [ADR-0008](./0008-facts-hooks-read-in-project-conf.md): events are runtime state in the
  git dir, not facts. They do not go in `project.conf`.
- **Readers (amends ADR-0008 item 4).** The evaluator reads `project.conf` (`docs`,
  `main-branch`), the main branch and the edited path in Node, rather than having the bash
  hooks resolve them with `lib.sh` and pass them in. That would cost one more Node start per
  hook call, since `lib.sh`'s reader starts Node too, and more plumbing. So the plugin has
  one reader per language: `read_fact` in `lib.sh` for bash hooks, `readFact` in
  `steps.mjs` for the evaluator. `scripts/test-hooks.sh` checks that both read the same
  file the same way. Chosen by the user on 2026-11-18. One short-cut stays in bash: `record-event.sh`
  reads `cwd` with a text match and drops events that cannot count (no events log yet, a
  Skill that names neither review skill, a `<task-notification>` prompt) before starting
  Node. Anything it does not drop goes to `steps.mjs`, which decides exactly.
- [ADR-0007](./0007-autopilot-runs-sessions-in-subagents.md): its "Tested" section left
  open whether a subagent's hook calls carry the parent's `session_id`. The probe shows they
  do. The events log is keyed by worktree anyway, so the gate does not depend on it.

### Alternatives considered

- **A DAG or workflow framework.** Rejected. It would bring an npm dependency, which the
  Constraints rule out, and the hard part is not ordering steps but seeing the events.
- **The evaluator in bash.** Rejected. Reading JSON lines and comparing positions in bash
  is fragile, and the hooks already call Node.
- **State keyed by `session_id`.** Rejected. It ties the gate to how Claude Code assigns
  ids. Keying by worktree covers subagents whatever their id, and a worktree subagent's
  edits land in its own worktree.
- **Both reviews after the last code edit.** Rejected. The probe showed it refuses every
  reviewed commit whose review led to a fix.
- **Both reviews after any edit since the last commit.** Simpler, but a change asked for in
  a later turn would pass on the old review. Rejected for the review window in item 5.

## Consequences

- **Positive:** a commit without a passing check, or without both reviews on a code branch,
  is refused with the missing step named. Skill wording that only repeats the order can be
  cut. The Stop gate and the commit gate share one table and one evaluator, and the events
  log orders events by line, so tests no longer need mtime sleeps.
- **Negative / accepted trade-offs:**
  - Edits made through Bash (`sed`, heredocs, scripts) fire no edit event, so the gate does
    not see them. This is a known limit with a backlog entry.
  - A new change made in the same turn after the review passes unreviewed, because the
    window does not end at the review.
  - With the plugin off (a cloud session without it, or hooks disabled), nothing refuses.
    Only the `ask` rule stops the commit.
  - A review called from the main conversation counts for the checkout `claude` started
    in, because a Skill event has no path.
  - The gate trusts the events. It sees that a review skill was called, not that its
    findings were fixed.
- **Invariants this protects:** the step order lives only in `steps.json`; the gate
  refuses only when it can decide; the `ask` rule on `git commit` stays; the project-owned
  `scripts/check` does not change.

## References

- `plugin/hooks/pre-bash-git.sh`, `plugin/hooks/stop-check-ran.sh`,
  `plugin/hooks/post-edit-mark.sh`, `plugin/hooks/lib.sh`, `plugin/hooks/hooks.json`
- `scripts/check` (the `yotamake-check-passed` stamp), `scripts/test-hooks.sh`
- `plugin/reference/integrate.md` (the release bump commit)
- `plugin/skills/simple-session/SKILL.md`, step 6
- The backlog entry "Enforce the session steps in order with hooks", which this work closed
