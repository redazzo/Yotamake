---
kind: decision
date: 2026-11-17
status: current
---

# ADR-0008: Hooks and scripts read their project facts from `.claude/yotamake/project.conf`

- **Status:** Accepted (2026-11-17)
- **Date:** 2026-11-17
- **Work record:** none yet
- **Amends:** [ADR-0002](./0002-project-facts-in-named-claude-md-sections.md): the facts
  that hooks and scripts read get a copy in a config file, which ADR-0002 rejected. Skills
  still read facts only from named `CLAUDE.md` sections.
- **Builds on:** [ADR-0001](./0001-harness-owned-and-project-owned-files.md) (the file is
  project-owned, copied once); [ADR-0004](./0004-project-session-start-hook-sets-hooks-path.md)
  (`session-context.sh` runs without the plugin, so it reads the file itself).

## Context

Hooks and scripts read two project facts by parsing `CLAUDE.md` prose:

- **The main branch.** The same `sed` on the ``- **Main branch:** `<name>` `` line sits in
  four places: `plugin/hooks/lib.sh` (`guarded_main_branch`), the template's
  `.claude/yotamake/session-context.sh` (in a different `sed` form), and both copies of
  `scripts/check`. A reworded bullet changes what they do without an error: `lib.sh` then
  guards both `main` and `master`, and `scripts/check` falls back to its default.
- **Which files are docs.** `plugin/hooks/post-edit-mark.sh` hard-codes the default
  `Docs-only` rule (files under `docs/`, Markdown at the root other than `CLAUDE.md`). A
  project whose `Docs-only` line names other paths is ignored, so editing those docs counts
  as code and the `Stop` gate asks for one check more than it needs.

Prose is right for skills and people, who read it. A hook needs a value it can read with
no parsing. `.claude/yotamake/*.conf` already holds per-repository hook settings
(`post-edit-checks.conf`, `protected-paths.conf`), each with its own reader.

## Decision

In the context of hooks and scripts that need project facts, facing a prose line that can
drift without an error, we decided for a small conf file that holds only the facts they
read, with `CLAUDE.md` still the source of truth (and against moving facts out of
`CLAUDE.md`, or leaving the prose parsing as it is), to make the hooks' facts exact,
accepting two copies of each fact and a check that they agree.

1. **File.** `.claude/yotamake/project.conf`, project-owned. It holds only what a hook or
   script reads today: `main-branch` and `docs`. A new key needs a hook that reads it.
2. **Format.** One `key value` pair per line; `#` starts a comment; blank lines are skipped.
   `main-branch` appears once. `docs` may repeat: one glob per line, matched against the
   path from the repository root, where a glob with no `/` matches only files at the root,
   and a `!` line is an exception that wins (as in `protected-paths.conf`). The template's
   lines are the default rule:

   ```
   main-branch main
   docs docs/*
   docs *.md
   docs !CLAUDE.md
   ```

3. **Source of truth.** `CLAUDE.md`. Skills and people read the prose (ADR-0002 stands for
   skills). The conf is a copy for machines. When the two disagree, the conf is changed to
   match `CLAUDE.md`, never the other way round without the user.
4. **Readers.** One `read_fact <root> <key>` helper in `plugin/hooks/lib.sh` serves the
   plugin's hooks (`guarded_main_branch`, `post-edit-mark.sh`). `session-context.sh` and
   both `scripts/check` copies run without the plugin, so each carries a few lines that read
   `main-branch` the same way.
5. **Fallback.** No file, or no key: today's behaviour. The main branch comes from the
   `CLAUDE.md` line, else `main` and `master` both count; docs follow the default rule.
   A line the reader cannot parse is skipped. Hooks still let the edit through when they
   cannot decide.
6. **Drift check.** `/yotamake:doctor` gains a check: `main-branch` must equal the
   `CLAUDE.md` line (fail if not); the `docs` globs are shown beside the `Docs-only` line and
   fail when they clearly name other paths. In this repository, `scripts/consistency.mjs`
   fails when `main-branch` and the `CLAUDE.md` line differ.
7. **Install and upgrade.** `install.sh` copies the template's `project.conf` when it is
   missing, like the other confs; it never rewrites one. `/yotamake:setup` fills it from the
   same facts it writes into `CLAUDE.md` (`Main branch`, `Docs-only`). Older installs get the
   file and the `scripts/check` change through an entry in `plugin/reference/upgrades.md`:
   check that `project.conf` exists and agrees with `CLAUDE.md`; apply by copying the
   template and setting both keys.

### Alternatives considered

- **Move the facts out of `CLAUDE.md` into the conf.** Skills and people would read two
  places, and ADR-0002's one file for every fact would be lost.
- **Keep parsing prose, with one shared parser.** Removes the copies of the `sed`, but a
  reworded line still fails silently, and `Docs-only` stays unreadable.
- **A `docs-paths.conf` for the `Docs-only` case alone.** Smaller, but leaves the main
  branch parsed four times and adds a conf per fact.
- **More keys now (integration mode, branch prefixes).** No hook reads them yet.

## Consequences

- **Positive:** hooks read the main branch and doc paths exactly; a project with docs
  outside `docs/` stops paying for an extra check; the `sed` copies stay only as the fallback
  for installs without the conf.
- **Negative / accepted trade-offs:** two copies of two facts, kept in step by `setup` and
  checked by `doctor`, not enforced on every edit in other repositories. Renaming a key is
  a breaking change, like renaming a `CLAUDE.md` section.
- **Invariants this protects:** `CLAUDE.md` stays the one place a person edits a fact; a
  hook never fails because the conf is missing or wrong.

## References

- `plugin/hooks/lib.sh`, `plugin/hooks/post-edit-mark.sh`
- `plugin/template/.claude/yotamake/session-context.sh`, `plugin/template/scripts/check`,
  `scripts/check`
- `plugin/install.sh`, `plugin/skills/setup/SKILL.md`, `plugin/skills/doctor/SKILL.md`
- [Backlog](../backlog.md), "A facts file that hooks can read"
