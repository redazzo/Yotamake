---
kind: decision
date: 2026-11-09
status: current
---

# ADR-0004: A plugin SessionStart hook points git at .githooks/ when nothing else is set

- **Status:** Proposed
- **Date:** 2026-11-09
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
fresh cloud clone on 2026-11-09.

The plugin already ships hooks (`plugin/hooks/hooks.json`), so it runs code in every Claude Code
session in a repository where it is enabled. A `SessionStart` hook would run once at the start
of each of those sessions.

This change would reach every repository that uses the harness, not just this one. So it needs
a decision before it is built. It gets an ADR because it widens the **Style** line in
`CLAUDE.md`, not because it would be costly to reverse: today the plugin's hooks only enforce
(they check or block an edit), and this one would set something up on a person's machine.

## Decision

In the context of the pre-commit gate, facing a git setting that every clone must set by hand,
we propose to add a `SessionStart` hook to the plugin that sets `core.hooksPath` to
`.githooks`, and only when all of these hold:

1. The session is inside a git work tree.
2. `.githooks/pre-commit` exists at the root of that work tree.
3. `core.hooksPath` is not set at any level (local, global or system).
4. No other hook tool is in use: the same tests the installer makes today (a
   `.pre-commit-config.yaml`, a lefthook config, or an existing `.git/hooks/pre-commit`).

When it sets the value, it prints one line saying so and how to undo it. In every other case it
does nothing and prints nothing. It always exits 0, so a failure never blocks the session (as
**Boundaries** in `CLAUDE.md` asks of hooks).

The tests in 3 and 4 move out of `install.sh` into one shared script that both the installer
and the hook use, so the two cannot drift apart.

We decided against these alternatives:

- **Keep it manual, and document it** (today). Cheap, but it relies on each person reading the
  docs. The backlog entry exists because that has not been enough.
- **A step in `simple-session` or `multi-session` that sets it.** A skill may not fire (see
  ADR-0003, and the backlog entry on missed skills). It would also mix a one-time setup step
  into every session's method.
- **A check in `scripts/check` that warns when it is unset.** It would only warn, and only when
  someone runs the check. Claude runs it anyway; people who skip it would not see the warning.
  It also puts harness setup into a project-owned file.
- **A `SessionStart` hook in the template's `.claude/settings.json`.** It would reach only
  repositories installed or refreshed after the change, and the project would own and could
  change the copy. The plugin hook reaches every repository where the plugin is enabled, and
  is updated with the plugin.

We accept that the plugin then writes to a person's local git config without asking each time,
and that a person who never uses Claude Code still has to set it by hand.

## Consequences

- A teammate who opens Claude Code in a new clone gets the pre-commit gate from the first
  session, without running the installer.
- The plugin changes local git config by itself. It only fills an empty value; it never changes
  or removes one a person set. This is the same change the installer already makes. It is local
  only, so it does not fall under the stop points in ADR-0003, which cover git actions that are
  hard to undo or reach other people.
- A person who does not want the hook must set `core.hooksPath` to something else (for example
  `.git/hooks`, git's default) so that test 3 fails. There is no opt-out file. If people ask for
  one, it goes in `.claude/yotamake/*.conf`, as **Patterns** says.
- A repository with its own `.githooks/pre-commit` that is not the harness's would also have it
  turned on. That seems to be what such a repository wants, but it was not checked.
- A person who uses git without Claude Code gets nothing from this. CI stays the gate that
  covers everyone.
- The hook adds a few `git` calls to the start of every session. This has not been measured;
  it is expected to be small.
- Build work, if accepted: the hook script and its `hooks.json` entry, the shared detection
  script, test cases in `scripts/test-hooks.sh` and `scripts/test-install.sh`, updates to
  `README.md` (the "One gate, run by everyone" paragraph) and to the **Style** line in
  `CLAUDE.md` (hooks may also do safe one-time setup), a minor version bump, and deleting
  the backlog entry.

## Open questions

- Does Claude Code show a `SessionStart` hook's output to the person, or only add it to
  Claude's context? This decides whether the one-line notice reaches the person directly. It
  should be tested before building.
- Sessions without the plugin loaded (as in some cloud sessions) run no plugin hooks, so they
  are not covered. `CLAUDE.md` already tells Claude to set the value by hand there.

## References

- `plugin/install.sh` (the `core.hooksPath` block)
- `plugin/hooks/hooks.json`
- [README.md](../../README.md), "One gate, run by everyone"
- [docs/backlog.md](../backlog.md), "Each clone needs the pre-commit hook set up"
- [ADR-0003](./0003-stop-points-enforced-by-ask-rules.md)
