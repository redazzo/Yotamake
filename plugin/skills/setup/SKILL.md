---
name: setup
description: Set up the current repository for the Yotamake harness, or refresh its harness files after a plugin update — installs CLAUDE.md sections, scripts/check, the pre-commit hook, the docs skeleton and settings, then helps fill in the project facts. Use when the user says "set up yotamake", "install the harness", or "update the harness files".
disable-model-invocation: true
---

# Set up the harness in this repository

The method comes from this plugin. Each repository keeps its own facts and gates. This skill
installs those per-repo files with the plugin's `install.sh`.

## 1. Install

Run the installer that sits two directories above this skill (the plugin root), against the
repository root:

```bash
bash "<this skill's directory>/../../install.sh" "$(git rev-parse --show-toplevel)"
```

If the repository already has its own version of a template file (most often a docs linter
or records-index script), list the harness path in `.claude/yotamake/skip`, one per line,
before running. The installer never writes a listed path, on this run or later ones. Then
point `scripts/check` at the repository's own script.

For a small repository that does not want the docs system (ADRs, records, backlog), offer
lite mode: add `--lite` to the command. It leaves out `docs/` and `scripts/docs/`, and
records them in `.claude/yotamake/skip` so later runs leave them out too. Ask which the user
wants when the repository has no `docs/` folder yet and is small; otherwise install the full
set.

If the working tree has uncommitted changes, ask before running it. If the repository has
commits and is on its main branch, cut `chore/yotamake-harness` first: the plugin's hook
blocks edits on the main branch, so filling in the facts below would fail there.

Before running it on a repository already set up, note the version in
`.claude/yotamake/version` (or that the file is missing): the installer overwrites it, and
step 2 needs the old one.

Report what it printed: files copied, harness files refreshed, project files kept. Do not
re-run with `--force` unless the user asks; it overwrites project-owned files.

## 2. Fill in the facts

On a refresh of an existing install, read `<this skill's directory>/../../reference/upgrades.md`
first. Run the **Check** of each entry newer than the version `.claude/yotamake/version` held
before the installer ran (no file: before 0.11.0). Do the **Apply** of each one that fails,
oldest first, and list them in the report.

On a fresh install, offer to fill in the `FILL IN` placeholders. Work from the repository, not
from guesses:

- **`scripts/check`** — find the project's real type-check, lint and test commands (package
  scripts, a Makefile, CI config). Add each as a `run` line. Put a check that takes more than
  a few seconds (usually the test suite) behind `full`, so the pre-commit hook skips it. Run
  `scripts/check --all` and show the result.
- **`CLAUDE.md`** — Project overview, Commands, Branching and releases. For its `Docs-only`
  line, look at the Markdown outside `docs/`: name docs folders (a `guides/`, say) in the
  line, and leave out of it root files that hold prompts or agent instructions (an
  `AGENTS.md`, say). Tell the user that Markdown holding prompts or skills counts as code. For
  its `Worktree setup` line, name the git-ignored files the checks need (`.env`, installed
  dependencies) and how a new worktree gets them, or "none". Fill
  in Migrations and Deploying only from what the repository shows; if it shows nothing, ask
  whether to delete those sections.
- **`CLAUDE.md`, Architecture** — read the layout, the imports between top-level folders and
  any existing design docs or ADRs. Propose each line: **Style** (the style or styles the code
  follows and where, named from the "Signs in code" entries in
  `<this skill's directory>/../../reference/architecture-styles.md`), **Modules** (the main
  parts and what each owns), **Boundaries** (which parts never import which, as the code shows
  them today), **Shared code** (where the reused helpers live), **Patterns** (how the code
  already handles errors, config, logging and data access) and **Constraints** (limits the repository
  states, such as the runtime version in `package.json` `engines`, the CI matrix, or the
  licence). Use the style's entry in the catalogue to check the Boundaries and Patterns lines
  for rules the style implies that the code keeps but the lines leave out. Show the proposal
  and ask the user to confirm it: these lines become rules the sessions stop on, so a wrong
  boundary blocks real work. A boundary the code already breaks goes in the report, not in the
  line.
- **`scripts/check`, design gates** — if the repository already has a boundary or
  duplicate-code tool configured, add it as a `run` line. Otherwise leave the placeholders and
  mention them in the report, with the rules the style's "Gate" entry says a tool would
  check.
- **`.github/workflows/check.yml`** — the toolchain setup steps, or ask whether to delete it.
- **`.claude/yotamake/post-edit-checks.conf`** — one fast per-file linter line per language.

Leave a placeholder in place, and list it in the report, wherever the repository does not
answer the question.

## 3. Report

List what was installed, what you filled in, and what is still `FILL IN`. Propose a commit
message, then ask before committing.
