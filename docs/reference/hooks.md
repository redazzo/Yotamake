---
kind: reference
status: current
updated: 2026-11-20
owns: [hooks, ask-rules]
---

# Hooks

How the harness's hooks and `ask` rules work: what each one blocks, how the `Stop` gate and
the commit gate decide, and what gets past them. Each rule in `CLAUDE.md` and what enforces
it is in [rules-and-enforcers.md](./rules-and-enforcers.md). The overview of the harness, with
a line per hook, is the [README](../../README.md); each skill's `SKILL.md` owns its own rules.

## Hooks in one paragraph

The plugin's hooks live in `plugin/hooks/`, registered in `hooks.json`. Some block one action
as it happens: an edit on the main branch, an edit or read of a protected file, a git command
with `--no-verify`. Two gate a step: the `Stop` hook and the commit gate ask one step
evaluator, `steps.mjs`, which reads the step order from `steps.json` and the session's event
log (ADR-0010). Beside them, the repository's `.claude/settings.json` puts risky git commands
under `ask` (not `git commit`, which the commit gate covers), and `.githooks/pre-commit` runs `scripts/check --staged`. A hook that cannot
decide lets the action through.

```
  Edit / Write ──► post-edit-mark ──►  yotamake-events  ◄── record-event (reviews, prompts)
  scripts/check passes ──────────────► yotamake-check-passed
  end of turn, git commit ──► steps.mjs (steps.json + events + stamp) ──► block or allow
```

## How it works

### The check stamp and the event log

When `scripts/check` passes (not with `--staged`), it touches `yotamake-check-passed` in the
git directory. A run in which no check ran (an empty gate, as in a lite install before
`/yotamake:setup`) writes no stamp and says so. When Claude edits a file with Edit or Write, a
hook appends an edit event to `yotamake-events` there: one JSON line per event, with the
session, the HEAD and the stamp it saw. Git-ignored files are not logged, and a doc edit is
marked as one. The hook reads which files are docs from the `docs` globs in
`.claude/yotamake/project.conf`, a copy of the `Docs-only` line
([ADR-0008](../decisions/0008-facts-hooks-read-in-project-conf.md)); without them it uses the
default rule (files under `docs/`, and Markdown at the root other than `CLAUDE.md`). The log
keeps only its newer half once it passes 512 KB.

### The Stop gate

Claude cannot end a turn with unchecked code. When Claude ends a turn, a `Stop` hook asks the
step evaluator (`plugin/hooks/steps.mjs`), which reads the `stop` row of `steps.json`
([ADR-0010](../decisions/0010-commit-gate-by-step-table.md)): if this session's last code edit
came after the last passing check, the hook blocks once and tells Claude to run the check. A
second stop goes through, so Claude can still stop to ask a question. A turn that edited no
code, such as a question or a docs-only change, is never blocked, and neither is a repository
whose `scripts/check` does not write the stamp (one set up before 0.15.0). Edits a subagent
made (its events carry an `agent_id`) do not count for the stop, so a background agent's edits
do not block the main conversation's turns; the commit gate below still counts them. When the
evaluator cannot read its input, the log or git, the turn ends.

### The commit gate

Claude cannot commit before the check and the review. The Bash hook asks the same evaluator
about each `git commit`, by the `commit` row of `steps.json`
([ADR-0010](../decisions/0010-commit-gate-by-step-table.md)). It refuses the commit, and names
what is missing and how to fix it, unless `scripts/check` passed after the last edit, code or
doc, and both `/simplify` and `/code-review` ran in the review window. A review counts when it
came after the window's first code edit. The window starts at the later of the last commit and
the last user prompt before the last code edit, so fixes made in the review's own turn count
as reviewed, and a change asked for in a later turn needs a new review. A hook records each
review: a Skill call by Claude, or the command typed by the user (exact names only; a plugin's
`x:simplify` is another skill). Another records each user prompt, but not the notice a
background agent sends when it finishes. Two cases need the check but no review: a branch
whose changes against the main branch are all docs (untracked files count, so a code file
about to be `git add`ed is seen), and a commit message with a `Review-skipped: <reason>`
trailer line, used for a trivial branch and for the release bump commit, which comes after
the review. The hook reads the message from `-m`, `--message`, `-F`/`--file` and the
`"$(cat <<'EOF' … EOF)"` form; one it cannot read counts as having no trailer. A commit that
finishes a merge is not gated, nor is `git merge`. When the evaluator cannot read its input,
the log or git, the commit goes through, and nothing else asks: `git commit` is under
`allow` ([ADR-0013](../decisions/0013-commit-gated-not-prompted.md)).

### Stop points: the ask rules

Stop points are enforced, not just asked for. The skills stop before commit, version bump,
merge and deploy. The repo's settings also put `git merge`, `push`, `rebase`,
`reset --hard` and `tag` under `ask`, so Claude Code asks every time, whatever a skill says.
Add your deploy command there too. `git commit` is under `allow`, so it does not prompt: the
skill has already asked, and the commit gate above refuses a commit before the check and the
review ([ADR-0013](../decisions/0013-commit-gated-not-prompted.md)). Older versions put it
under `ask`; the installer removes that rule when it merges the settings, and it is the only
rule the installer ever removes. To keep the prompt, put `Bash(git commit:*)` under `ask` in
`.claude/settings.local.json` or your user settings. An `ask` rule wins over a matching `allow` rule, including
a broad one such as `Bash(git:*)` and one from a higher-priority settings source (tested
2026-10-28 with Claude Code 2.1.312, in the same file and across sources). Cutting or
switching branches with `git switch`, staging files and a fast-forward pull are under
`allow`, so they do not prompt. `git switch` with `-f`, `--force`, `--discard-changes`, `-C`
or `--force-create` first in its options is under `ask`, since it drops uncommitted work or
resets a branch. Listing branches with `git branch` is under `allow`, but `git branch` with
`-D`, `-f`, `--force`, `-M`, `-C` or `--delete` first is under `ask`, since it deletes, moves
or overwrites a branch. The rules match from the start of the command, so the same flag later
on is not caught.

### No edits on the main branch

A hook refuses Edit and Write while the file's repository is on its main branch
(`main-branch` in `.claude/yotamake/project.conf`, else the `Main branch` line in
`CLAUDE.md`, else `main` or `master`). Claude has to cut a branch first, even when a skill did
not fire. Files outside a repository are not affected, nor are git-ignored ones (such as a
multi-session `.scratchpad/` folder). A repository that works on main on purpose opts out
with an empty file at `.claude/yotamake/allow-edits-on-main`. The protected-paths list stops
Claude creating it with Edit or Write; a person makes it.

### No reading secrets

The same protected-paths hook also runs on Read, so a protected file such as `.env` or a key
does not land in Claude's context. The `!` exceptions, such as `.env.example`, can still be
read. A project that wants Claude to read a listed file takes its line out of the list, which
lets Claude edit it too.

### No skipped hooks, no commits on main

A hook on Bash refuses any git command with `--no-verify` (or `git commit -n`), so Claude
cannot step past the gate, even in a repository that opted out above. A person who wants to
skip it runs the command themselves with `! <command>`. The same hook refuses `git commit`
while the repository is on its main branch, read as above, unless a merge is being finished,
the repository has no commits yet, or it opted out. It reads the command with a small
quote-aware parser and follows `cd <dir>` and `git -C <dir>`; text inside quotes, such as a
commit message, does not count. It skips shell keywords and wrappers in front of git (`{`,
`if`, `then`, `do`, `!`, `time`, `env`, `nohup`, `command`, `exec`), and reads the script
given to `bash -c` or `sh -c` the same way. A command it cannot read goes through.

### The pre-commit hook in a clone

A person's commit passes the same gate as Claude's, with one catch: `core.hooksPath` is a
local git setting and is not cloned. The project's `SessionStart` hook sets it at a
teammate's first Claude Code session in the clone, with or without the plugin loaded, and
says so in one line. A teammate who never opens Claude Code there must run
`git config core.hooksPath .githooks` themselves. CI covers everyone.

### Worktrees

Every hook acts on the repository of the file being edited, else on the session's own
directory (the `cwd` in the hook's input), and only then on `CLAUDE_PROJECT_DIR`, which stays
at the main checkout after `EnterWorktree`. So the protected-paths list, the per-file checks,
the `Stop` gate and the upgrade notice work the same in a linked worktree (ADR-0005). The
`Stop` gate also looks in the repository's other worktrees, so an edit made by absolute path
into a linked worktree from the main checkout still needs a passing `scripts/check` in that
worktree. In a linked worktree, `session-context.sh` also lists the efforts in the main
worktree's `.scratchpad/`, by full path, because a worktree has no copy of that git-ignored
folder.

## Known gaps and concerns

What the hooks do not cover. The main-branch, protected-paths and edit-marking hooks watch
Edit, Write and NotebookEdit only (the protected-paths hook Read too, but not Grep). The Bash
hook above watches git commands only. A shell command gets past them: `sed -i`,
`echo > .env`, `touch` on the opt-out file, or a code change made from the shell, which
neither the `Stop` hook nor the commit gate sees (a known limit, ADR-0010). Claude Code's own
permission prompt for Bash is the guard there. The commit gate sees that a review skill was
called, not that its findings were fixed. The `ask` rules are separate, and `git -C . commit`
still asked in a test (one run, Claude Code 2.1.312).

## Key files

| File | What it holds |
|---|---|
| `plugin/hooks/hooks.json` | Which hook runs on which tool call or session event |
| `plugin/hooks/steps.json` | The steps each gated action needs, in order |
| `plugin/hooks/steps.mjs` | The step evaluator: logs events, decides, classifies docs |
| `plugin/hooks/lib.sh` | Shared by the bash hooks: reads the hook input and `project.conf` |
| `.claude/settings.json` | The `ask` and `allow` rules, and the project `SessionStart` hooks |
| `.claude/yotamake/protected-paths.conf` | Files Claude may not read or edit |
| `.claude/yotamake/project.conf` | The main branch and doc paths the hooks read |

## Where to go next

| You want | Read |
|---|---|
| Each `CLAUDE.md` rule and what enforces it | [rules-and-enforcers.md](./rules-and-enforcers.md) |
| Why stop points are `ask` rules, and `git commit` is not | [ADR-0013](../decisions/0013-commit-gated-not-prompted.md) |
| Why the gates read a step table | [ADR-0010](../decisions/0010-commit-gate-by-step-table.md) |
| Why hooks read facts from `project.conf` | [ADR-0008](../decisions/0008-facts-hooks-read-in-project-conf.md) |
| How the hooks behave in worktrees | [ADR-0005](../decisions/0005-parallel-sessions-in-worktrees.md) |
| To change a hook | [changing-the-harness.md](../guides/changing-the-harness.md) and `scripts/test-hooks.sh` |
