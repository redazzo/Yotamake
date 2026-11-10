---
kind: decision
date: 2026-11-10
status: current
---

# ADR-0004: A project SessionStart hook points git at .githooks/ when nothing else is set

- **Status:** Proposed
- **Date:** 2026-11-10 (first drafted 2026-11-09 as a plugin hook; rewritten before it was
  accepted)
- **Work record:** none
- **Supersedes / amends:** none

## Context

The pre-commit hook in `.githooks/pre-commit` runs `scripts/check --staged`. Git only runs it
when `core.hooksPath` is `.githooks`. That setting lives in each clone's local git config, and
git does not clone it. Git has no way to ship hooks that turn on by themselves; this is on
purpose, so that cloning a repository never runs its code.

Today the installer sets it (`plugin/install.sh`), but only in the clone where it runs. Every
other person, in every other clone, has to run `./plugin/install.sh .` or
`git config core.hooksPath .githooks` by hand. Until they do, their commits skip the gate, and
only CI catches a failing check. `README.md` warns about this, and `docs/backlog.md` tracks it
("Each clone needs the pre-commit hook set up"). This repository itself was found unset in a
fresh cloud clone on 2026-11-09, in a session where the plugin was not loaded.

Claude Code runs a `SessionStart` hook once at the start of each session. Such a hook can come
from a plugin (`plugin/hooks/hooks.json`) or from the project's committed
`.claude/settings.json`. A project hook travels with the repository, so every clone has it,
and it runs whether or not the plugin is loaded.

This change would reach every repository that uses the harness, not just this one. So it needs
a decision before it is built. It gets an ADR because it widens the **Style** line in
`CLAUDE.md`, not because it would be costly to reverse: today the harness's hooks only enforce
(they check or block an edit), and this one would set something up on a person's machine.

## Decision

In the context of the pre-commit gate, facing a git setting that every clone must set by hand,
we propose a `SessionStart` hook in the template's `.claude/settings.json` that sets
`core.hooksPath` to `.githooks`, and only when all of these hold:

1. The session is inside a git work tree.
2. `.githooks/pre-commit` exists at the root of that work tree.
3. `core.hooksPath` is not set at any level (local, global or system).
4. No other hook tool is in use: the same tests the installer makes today (a
   `.pre-commit-config.yaml`, a lefthook config, or an existing `.git/hooks/pre-commit`).

When it sets the value, it tells the person in one line, with how to undo it. In every other
case it does nothing and prints nothing. It always exits 0, so a failure never blocks the
session (as **Boundaries** in `CLAUDE.md` asks of hooks).

The work is done by one script, `.claude/yotamake/set-hooks-path.sh`. It is harness-owned
(listed in `managed` in `install.sh`, per ADR-0001), so every installer run refreshes it. The
tests in 3 and 4 move out of `install.sh` into it, and the installer calls it too, so the two
cannot drift apart. It uses only `bash` and `git`, and nothing from the plugin, so it works
when the plugin is not loaded.

The hook's command checks that the script exists and exits 0 if it does not, so a deleted or
opted-out script never makes the hook fail.

The installer's merge of `.claude/settings.json` learns to add hook entries: it adds the
`SessionStart` entry once, keeps the repository's own hooks, and adds nothing on a re-run.

A repository opts out by listing the script in `.claude/yotamake/skip`. The installer then
does not copy the script, and the merge leaves the hook entry out while the script is absent.
This is the rule the merge already uses for allow rules that name a skipped script. Setting
`core.hooksPath` to anything else (for example `.git/hooks`, git's default) also stops it,
since test 3 then fails.

We decided against these alternatives:

- **Keep it manual, and document it** (today). Cheap, but it relies on each person reading the
  docs. The backlog entry exists because that has not been enough.
- **A step in `simple-session` or `multi-session` that sets it.** A skill may not fire (see
  ADR-0003, and the backlog entry on missed skills). It would also mix a one-time setup step
  into every session's method.
- **A check in `scripts/check` that warns when it is unset.** It would only warn, and only when
  someone runs the check. Claude runs it anyway; people who skip it would not see the warning.
  It also puts harness setup into a project-owned file.
- **A `SessionStart` hook in the plugin** (`plugin/hooks/hooks.json`). This ADR's first draft
  chose it, because it reaches every repository where the plugin is enabled and updates with
  the plugin. It was dropped because it runs only when the plugin is loaded, and the case
  that started this, a cloud clone without the plugin, is exactly when it would not run. The
  project hook covers that case. Its reach to older installs comes through the existing path
  for template changes: an entry in `plugin/reference/upgrades.md` that the sessions offer
  (ADR-0001), and the installer's merge on the next refresh.

We accept that the harness then writes to a person's local git config without asking each
time, that older installs get the hook only after a refresh, and that a person who never uses
Claude Code still has to set it by hand.

## Consequences

- A teammate who opens Claude Code in a new clone gets the pre-commit gate from the first
  session, with or without the plugin, and without running the installer.
- The harness changes local git config by itself. It only fills an empty value; it never
  changes or removes one a person set. This is the same change the installer already makes.
  It is local only, so it does not fall under the stop points in ADR-0003, which cover git
  actions that are hard to undo or reach other people.
- The hook entry lives in a project-owned file. A project can edit or delete it; a deleted
  entry comes back on the next installer run unless the script is in the skip file.
- A repository with its own `.githooks/pre-commit` that is not the harness's would also have it
  turned on. That seems to be what such a repository wants, but it was not checked.
- A person who uses git without Claude Code gets nothing from this. CI stays the gate that
  covers everyone.
- The hook adds a few `git` calls to the start of every session. This has not been measured;
  it is expected to be small.
- Build work, if accepted: the script and its `managed` entry, the template's `SessionStart`
  entry, the `hooks` branch of the settings merge, test cases in `scripts/test-install.sh`
  (and `scripts/test-hooks.sh` if they fit there), an `upgrades.md` entry, updates to
  `README.md` (the "One gate, run by everyone" paragraph and the `.claude/yotamake/` layout)
  and to `CLAUDE.md` (the **Style** line, and the fallback for when the plugin is not loaded),
  a minor version bump, and deleting the backlog entry.

## Open questions

- Does Claude Code show a `SessionStart` hook's output to the person, or only add it to
  Claude's context? This decides how the one-line notice reaches the person: plain output, or
  JSON with a `systemMessage`. It is tested before building.

## References

- `plugin/install.sh` (the settings merge and the `core.hooksPath` block)
- `plugin/template/.claude/settings.json`
- `plugin/reference/upgrades.md`
- [README.md](../../README.md), "One gate, run by everyone"
- [docs/backlog.md](../backlog.md), "Each clone needs the pre-commit hook set up"
- [ADR-0001](./0001-harness-owned-and-project-owned-files.md)
- [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md)

## Amendment (2026-11-10): the hook also tells Claude where it is

Added while the ADR is still Proposed, so both parts are accepted or rejected together. The
decision above stands. This section adds a second job for the same hook entry.

**Context.** Skills do not always fire. In case `19-claude-md-only`, `simple-session` did not
fire in one of three runs, and Claude edited `CLAUDE.md` with no session (backlog, "`simple-session`
can miss a `CLAUDE.md`-only edit"). ADR-0003 already notes that a skill may not fire.
Superpowers deals with this through a `SessionStart` hook that puts its rules into Claude's
context at the start of every session. Our skills also do file reads at the start that a hook
could do instead: `simple-session`, "Harness upgrades", compares two version files, and
resuming a multi-session effort means finding its folder and its next session by hand.

**Decision.** In the context of the start of a session, facing skills that do not always fire
and start-up facts that each skill looks up for itself, we propose that the `SessionStart` entry
in the template's `.claude/settings.json` run a second script,
`.claude/yotamake/session-context.sh`. It prints a few plain lines that Claude Code adds to
Claude's context:

1. The current branch, and whether it is the main branch. The main branch comes from the
   `**Main branch:**` line in `CLAUDE.md`, read the way `pre-edit-main-branch.sh` reads it.
2. Each active multi-session effort: a folder under `.scratchpad/` or `.sessions/` that has a
   `plan.md`, with the first session in it whose heading is not marked `done`.
3. One fixed line: every change to code, tests or docs runs as a session, through
   `yotamake:simple-session` or `yotamake:multi-session`, and when those skills are not
   offered, Claude follows the fallback in `CLAUDE.md`, "How to work here". The script does
   not repeat that fallback, so `CLAUDE.md` stays its one owner.

It prints at most about ten lines, and nothing about an effort when there is none. Like
`set-hooks-path.sh`, it is harness-owned, uses only `bash` and `git`, always exits 0, and is
skipped when it is missing or listed in `.claude/yotamake/skip`. The two scripts are separate,
so a repository can opt out of one and keep the other, and the installer goes on calling only
`set-hooks-path.sh`.

**Pending harness upgrades go in a plugin hook, not the project script.** Only the plugin knows
its own version and has `upgrades.md`. A project script cannot find the plugin reliably,
and the upgrades only matter when the plugin is loaded. So a `SessionStart` entry in
`plugin/hooks/hooks.json` runs `session-upgrades.sh`. It compares
`.claude/yotamake/version` with the plugin's version and, when they differ, prints one line
that says so and names `simple-session`, "Harness upgrades". It does not run the entries'
checks; the skill still does that, so the hook stays fast and the method stays in the skill.

We decided against these alternatives:

- **A stronger skill description, or more lines in `CLAUDE.md`.** Both are already in place
  (version 0.7.3 moved the trigger to the front of the description, and the template
  `CLAUDE.md` says the same), and case 19 still missed. Text Claude reads when it decides is
  what is not enough. A hook puts the rule in front of Claude every time.
- **Everything in the plugin hook.** It would not run in a clone without the plugin, which is
  the case this ADR started from, and when the session rule matters most.
- **Everything in one project script.** It cannot see the plugin's version, so it could not
  report pending upgrades. It would also tie the hooks-path setup and the context lines to one
  opt-out.

**Consequences.**

- **Style** in `CLAUDE.md` widens again: hooks now enforce, set up, and add context. The Style
  line says so when this is built.
- Every session starts with a few extra lines in Claude's context. That costs tokens in every
  session, including ones with no edit. The lines are kept few and factual for that reason.
- What the hook prints must stay true. A wrong branch or a stale effort would mislead Claude
  more than no line at all. So the script prints only what git and the files say, and tests
  cover each line.
- `simple-session`, "Harness upgrades", can then start from the hook's line instead of reading
  the two version files. It keeps its own reads as the fallback when the line is not there
  (an older install, or the plugin hook skipped).
- `multi-session` can say: when the context names an active effort, offer to resume it.
- Whether this makes skills fire is not proven. Case `19-claude-md-only` and the
  `skill-fired` grader are the measure: run it before and after, with `--runs 3` or more.
- More build work, on top of the list above: `session-context.sh` and its `managed` entry, a
  second command in the template's `SessionStart` entry, `session-upgrades.sh` and its entry
  in `plugin/hooks/hooks.json`, test cases in `scripts/test-hooks.sh`, the `upgrades.md`
  entry covering both scripts, the edits to `simple-session` and `multi-session` above,
  `README.md` (the hooks list), and deleting the backlog entries "A `SessionStart` hook that
  tells Claude where it is" and, if case 19 then passes, "`simple-session` can miss a
  `CLAUDE.md`-only edit".

**Open questions.**

- The open question above, on whether the person sees `SessionStart` output, matters here
  too. These lines are meant for Claude. If Claude Code also shows plain output to the person,
  the context lines may need the JSON `additionalContext` field so they stay out of sight.
- Does a project `SessionStart` hook also run after `/clear` and on resume? If it does, an
  effort's next session shows up right after the `/clear` that `multi-session` asks for.
  Tested before building.
