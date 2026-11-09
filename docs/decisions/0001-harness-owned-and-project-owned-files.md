---
kind: decision
date: 2026-11-09
status: current
---

# ADR-0001: Template files are either harness-owned or project-owned

- **Status:** Accepted
- **Date:** 2026-11-09 (written after the fact; in force since the plugin's first release,
  2026-10-28)
- **Work record:** none
- **Supersedes / amends:** none

## Context

`install.sh` copies `plugin/template/` into each repository. Some of those files are pure
tooling that every repository should run in its latest form (the docs linter, the records
index generator, the pre-commit hook). Others hold facts only the project knows
(`CLAUDE.md`, `scripts/check`, the docs skeleton, the hook config). Re-running the installer
has to update the first kind without losing the second.

This ADR records a choice already in the code and `README.md`. The rationale below is
inferred from them.

## Decision

In the context of installing and refreshing the harness in a repository, facing the need to
ship tooling fixes without overwriting project facts, we decided to split every template file
into one of two kinds, and against a single kind that is always or never overwritten:

- **Harness-owned** files are listed in `managed` in `install.sh` and refreshed on every run.
- **Project-owned** files are copied only when missing and never overwritten.

A change to a project-owned template file reaches older installs through an entry in
`plugin/reference/upgrades.md` (a **Check** and an **Apply**), which the sessions and
`/yotamake:setup` offer to apply. `.claude/yotamake/version` records the version a
repository was last installed from. A repository can opt out of a template path with
`.claude/yotamake/skip`.

We accept that project-owned files drift from the template, and that every change to one
needs an upgrades entry.

## Consequences

- Tooling fixes reach every repository on the next install, with no merge.
- The installer is safe to re-run: it never destroys project edits.
- Adding a file to `managed` is a promise that no project will need to edit it.
- `scripts/check` here fails when a project-owned template file changes without an
  `upgrades.md` entry, and when this repository's own harness-owned copies differ from the
  template.

## References

- `plugin/install.sh` (`managed`)
- `plugin/reference/upgrades.md`
- [README.md](../../README.md), "How it is split" and "Updating"
