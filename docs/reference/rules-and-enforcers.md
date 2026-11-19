---
kind: reference
status: current
updated: 2026-11-20
owns: [rule-enforcers]
---

# Rules and what enforces them

Each rule in this repository's [CLAUDE.md](../../CLAUDE.md) and what enforces it. A rule
held only by text depends on Claude remembering it, and that is where repeated mistakes come
from.

The enforcers, strongest first:

- **Hook:** a plugin hook in `plugin/hooks/` blocks the action as it happens. How each one
  works, and what gets past them (edits made from the shell), is in the README,
  [The three ideas](../../README.md#the-three-ideas).
- **Permission:** the `ask` list in `.claude/settings.json`, so a person approves the command.
- **Check:** `scripts/check` fails. The name in brackets is the check's name in its output,
  or the rule name `scripts/consistency.mjs` prints.
- **Review:** a reviewer reads the diff (`simple-session`, "Review"). A judgment, not a
  guarantee.
- **Nothing:** only the text.

`scripts/check` also enforces rules that `CLAUDE.md` does not state. Their list is in the
header comments of `scripts/consistency.mjs` and `scripts/docs/lint-docs.mjs`, not here.

## How to use this table

- **A new or changed rule**, or a step in `plugin/hooks/steps.json` (ADR-0010), updates its
  row in the same branch, naming its enforcer or "Nothing".
- **A mistake corrected twice:** find its row. If it says "Nothing" or "Review", add an
  enforcer higher up the list: a hook, then a check, then a clearer line of text. Then change
  the row.

## Sessions and branches

| Rule | Enforcer |
|---|---|
| Every change to code, tests or docs runs as a session | Nothing. `session-context.sh` restates it at session start. The rows below cover its checks and review |
| No edits while the main branch is checked out | Hook: `pre-edit-main-branch.sh` |
| No commits on the main branch | Hook: `pre-bash-git.sh` |
| Leave the files in `.claude/yotamake/protected-paths.conf` alone | Hook: `pre-edit-protect.sh` |
| Branch names use one of the prefixes | Nothing |
| A change fits in one session (about 400 lines or 15 files) | Nothing. `simple-session`, "Check the size", is a judgment |
| Commits follow Conventional Commits | Nothing |

## Checks and review

| Rule | Enforcer |
|---|---|
| Run `scripts/check` after the last code edit, before the turn ends | Hook: `stop-check-ran.sh`, for this session's own edits. The commit gate catches the rest |
| `scripts/check` passes before a commit | Hook: `pre-bash-git.sh` (the commit gate). The git pre-commit hook also runs `scripts/check --staged` |
| Both review skills run before a commit | Hook: `pre-bash-git.sh` (the commit gate), except on a docs-only branch or with a `Review-skipped:` trailer |
| Never skip the git hook with `--no-verify` | Hook: `pre-bash-git.sh` |
| Stop and ask before commit, merge, push, rebase, `reset --hard` and tag | Permission |
| A hook or installer change adds a case to `scripts/test-hooks.sh` or `scripts/test-install.sh` | Nothing. `scripts/check` runs the tests but does not see a missing case |
| Ask before running the eval cases | Nothing. `scripts/check` notes which cases cover the change |

## Releases

| Rule | Enforcer |
|---|---|
| The version files agree, and the version has a `CHANGELOG.md` entry | Check (`version`) |
| A change under `plugin/` that reaches users bumps the version | Nothing. The check only sees that the files agree |
| Tag the merge commit `vX.Y.Z` | Nothing |

## Keeping the repository in step

| Rule | Enforcer |
|---|---|
| `main-branch` in `project.conf` matches the Main branch line | Check (`project conf`) |
| A project-owned template change, a section rename, a pointer to another skill's step: [changing-the-harness.md](../guides/changing-the-harness.md) | Check (`upgrades`, `sections`, `step refs`) |
| A branch that changes something a site page sums up updates that page | Nothing. `scripts/check` names the pages to read |
| The plugin and the marketplace pass `claude plugin validate --strict` | Check (`validate`) |
| A new or changed rule, or `steps.json` step, updates its row in this table | Nothing |

## Design and code

| Rule | Enforcer |
|---|---|
| The plugin stays generic: nothing specific to one stack or project | Review (the design read) |
| Skills read project facts only from named `CLAUDE.md` sections | Check (`sections`) for the names. Review for the rest |
| Hooks let the edit through (exit 0) when they cannot decide | Review, and the cases in `scripts/test-hooks.sh` |
| Only `bash`, `git` and Node 18+; no npm dependencies | Nothing. Check (`syntax`) only sees that files parse |
| Use `sed -i.bak`, not `sed -i` | Check (`portable sed`) |
| Look in Shared code before writing new code | Review (`/simplify` and the design read) |
| A change that crosses a Boundary or goes against an ADR stops and asks | Review (the design read), after the change is made |

## Docs

| Rule | Enforcer |
|---|---|
| A change in behaviour updates the doc that owns it | Review |
| ADRs are never edited, only superseded or amended | Nothing |
| Plain English and short sentences | Nothing |
