---
name: doctor
description: Check that the Yotamake harness is set up and working in the current repository — the pre-commit hook, the harness version and pending upgrades, FILL IN placeholders left in CLAUDE.md, whether scripts/check runs any project checks, and whether CI runs it — and print one screen of results with a fix for each problem. Read-only. Use when the user runs /yotamake:doctor or asks whether the harness is set up right.
disable-model-invocation: true
---

# Doctor

Check the harness in this repository and report on one screen. This skill only reads: it
edits no file, changes no git config and installs nothing. Each problem it finds comes with
the fix, and the user decides whether to run it.

Run every check from the repository root (`git rev-parse --show-toplevel`). Gather what the
checks need in as few commands as you can: one Bash call can read the version files,
`git config --get core.hooksPath`, and grep `CLAUDE.md`, `scripts/check` and the CI files.
If the directory is not a git repository, say so and stop. If it has no `scripts/check` and
no `.claude/yotamake/`, the harness is not installed: say so, suggest `/yotamake:setup`, and
stop.

Each check gets one of three results:

- **ok** — nothing to do.
- **warn** — works, but something is missing or left half done.
- **fail** — a part of the harness is not working.

## The checks

1. **Pre-commit hook.** If `.githooks/pre-commit` is listed in `.claude/yotamake/skip`: ok,
   opted out on purpose. Otherwise read
   `<this skill's directory>/../../template/.claude/yotamake/set-hooks-path.sh` and sort the
   repository the way it does. Do not run it: without `--install` it sets `core.hooksPath`.
   - `core.hooksPath` is `.githooks`, and `.githooks/pre-commit` exists and is executable:
     ok.
   - Another hook tool or folder is in use (pre-commit, lefthook, a hook in `.git/hooks`, or
     another `core.hooksPath`): ok if its config or hook calls `.githooks/pre-commit`,
     otherwise warn. Fix: the snippet the script prints for that case with `--install`.
   - Neither: fail. Commits skip `scripts/check --staged`. Fix:
     `git config core.hooksPath .githooks`.

2. **Harness version.** Run the plugin's own version hook, which prints nothing when the
   repository is up to date:
   `CLAUDE_PROJECT_DIR="$PWD" bash "<this skill's directory>/../../hooks/session-upgrades.sh"`.
   - Silent: ok, unless `.claude/yotamake/version` is newer than the plugin's version (in
     `<this skill's directory>/../../.claude-plugin/plugin.json`). Then warn. Fix:
     `claude plugin update yotamake@yotamake`.
   - It prints a line: read `<this skill's directory>/../../reference/upgrades.md` and run
     the **Check** of each entry newer than the repository's version, as
     `simple-session`, "Harness upgrades" does, all in one Bash call where you can. Warn if
     none fails, fail if any does, and list each failing entry by its heading. Fix:
     `/yotamake:setup`.

3. **CLAUDE.md placeholders.** List each section (the `##` heading above it) of `CLAUDE.md`
   that still holds `FILL IN`, on one line. None: ok. Some in a section `simple-session`
   names at its top as one it reads: fail, because the sessions read those as rules. Others:
   warn. A placeholder that says "or delete" can be met by deleting its section. Fix:
   `/yotamake:setup` fills them in from the repository. No `CLAUDE.md`: fail.

4. **Project checks.** Count the `run` lines in `scripts/check` that are not commented out,
   leaving out the docs linter between the `yotamake:docs` markers.
   - At least one: ok. Name them in one line. If the Architecture section lists Boundaries
     and no `run` line checks them (a boundary or duplicate-code tool), say so on that line.
   - None: fail. The gate runs only the docs linter, or nothing, so it passes whatever the
     code does. Fix: `/yotamake:setup` finds the project's type-check, lint and test
     commands.
   - `scripts/check` is missing or not executable: fail.

   Do not run `scripts/check` here: a full run can be slow, and this skill only reads. Say
   that `scripts/check --all` shows whether the checks pass.

5. **CI.** Find the CI files that run `scripts/check` with one search:
   `grep -rl scripts/check .github/workflows .gitlab-ci.yml .circleci azure-pipelines.yml bitbucket-pipelines.yml Jenkinsfile 2>/dev/null`.
   - Found, without a `FILL IN` line: ok. Name the file.
   - Found but still holding a `FILL IN` line (the template's toolchain step), or CI exists
     but none runs `scripts/check`: warn, and say which.
   - No CI: warn. Fix: the template's `.github/workflows/check.yml`, filled in by
     `/yotamake:setup`.

## Report

One screen, in this shape:

```
Yotamake doctor — <repo name>, harness <repo version>, plugin <plugin version>

ok    pre-commit hook   core.hooksPath is .githooks
fail  version           0.16.0 < 0.19.0; pending: 0.17.0 SessionStart hook tells Claude where it is
warn  CLAUDE.md         FILL IN left in: Deploying, Conventions
ok    project checks    lint, type-check, tests
warn  CI                none found

Fixes
- version: /yotamake:setup
- CLAUDE.md: /yotamake:setup, or delete the sections you do not need
- CI: copy the template's .github/workflows/check.yml (/yotamake:setup fills it in)
```

List fixes only for the checks that did not pass, fails first. When every check passes, say
so in one line after the table. Then offer to apply the fixes. Change nothing until the user
says yes. A fix that edits files runs as a session (`simple-session`), like any other change.
