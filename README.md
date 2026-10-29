# Yotamake

A development harness for Claude Code. It gives any repository the same working method:
small sessions on branches, one check command that everyone runs, nothing committed or
deployed without a "yes", and a docs system that stays true.

It started as the `.claude/` setup and docs rules of a single application project.

## Install

**1. Add the plugin** (once per machine), in Claude Code:

```
/plugin install yotamake --marketplace redazzo/Yotamake
```

or from a shell: `claude plugin marketplace add redazzo/Yotamake`, then
`claude plugin install yotamake@yotamake`.

**2. Set up each repository.** In Claude Code, inside the repo, run `/yotamake:setup`. It runs
the plugin's `install.sh` and then helps fill in the project facts from the repo itself. Or
run it by hand from a clone of this repo:

```bash
./plugin/install.sh /path/to/your/repo
```

The repo's `.claude/settings.json` then names this marketplace and enables the plugin, so
teammates who open the repo in Claude Code are prompted to install it.

The installer points git at `.githooks/` (`core.hooksPath`). It leaves that setting alone when
the repo already uses another hook tool (a `.pre-commit-config.yaml`, a lefthook config, or a
hook in `.git/hooks/`), because git would stop running that tool's hooks. It then prints the
lines that call `.githooks/pre-commit` from the other tool.

If the repo already has its own version of a template file, such as a docs linter, list the
harness path in `.claude/yotamake/skip` (one per line). The installer never writes a listed
path, and adds no `allow` rule for a listed script the repo does not have.

**Lite mode.** For a small repo that does not want the docs system (ADRs, records, backlog),
run `install.sh <repo> --lite`, or ask `/yotamake:setup` for lite mode. It installs
`CLAUDE.md`, `scripts/check`, the pre-commit hook, the hook config and settings, but nothing
under `docs/` or `scripts/docs/`. It writes those paths into `.claude/yotamake/skip`, so later
runs leave them out too, and drops the docs lines from the new `CLAUDE.md` and
`scripts/check`. To add the docs system later, delete those lines from the skip file, re-run
the installer, and add the docs check to `scripts/check` by hand.

**Updating.** `claude plugin update yotamake@yotamake` updates the method for every repo at
once. Re-run `/yotamake:setup` (or `install.sh`) in a repo to refresh its harness-owned
scripts; it never overwrites the files that belong to the project.

## How it is split

| Lives in | What | Who changes it |
|---|---|---|
| The plugin (`plugin/`) | Skills, hooks, output style, the installer and template | This repo; reaches every project on update |
| Each repository | `CLAUDE.md` facts, `scripts/check`, `docs/`, hook config, CI workflow | The project |
| Each repository, harness-owned | `scripts/docs/*.mjs`, `.githooks/pre-commit` | Refreshed by the installer |

### The plugin

```
plugin/
  .claude-plugin/plugin.json
  skills/
    simple-session/   one change: size check, branch, work, docs, scripts/check, stop and ask
    multi-session/    work across several contexts, with a working folder that survives /clear
    write-doc/        pick the doc kind, write it, link it, lint it
    release-check/    guided deploy with pre-flight and gotchas      (manual: /yotamake:release-check)
    new-migration/    scaffold a timestamped migration file         (manual: /yotamake:new-migration)
    setup/            install or refresh the per-repo files         (manual: /yotamake:setup)
    drawio/           draw.io diagrams
  hooks/
    hooks.json                     registers the three hooks below
    pre-edit-protect.sh            blocks edits to protected files (.env, keys, certificates)
    pre-edit-main-branch.sh        blocks edits while the repository is on its main branch
    post-edit-check.sh             runs a fast per-file check after each edit
    protected-paths.default.conf   used when a repo has no list of its own
  output-styles/plain-english.md   short sentences, plain words (pick it with /output-style)
  install.sh                       installs template/ into a repo
  template/                        the per-repo files
  evals/                           the eval suite (see below)
```

### Each repository

```
CLAUDE.md                       facts the skills read, by section name
scripts/check                   the one gate: skills, the pre-commit hook and CI all run it
.githooks/pre-commit            runs scripts/check --staged (fast checks only)
.github/workflows/check.yml     runs scripts/check --all
.claude/settings.json           enables the plugin; "ask" rules for commit, merge, push, …
.claude/yotamake/
  protected-paths.conf          files Claude may not edit
  post-edit-checks.conf         glob → per-file check command
  skip                          optional: template paths the installer must never write
docs/                           README (rulebook and index), backlog, decisions, records, …
scripts/docs/                   docs linter and records index generator
```

## The three ideas

**Skills hold the method. `CLAUDE.md` holds the facts.** Skills read named sections
(Checks, Branching and releases, Migrations, Deploying, Conventions). If one is missing or
unfilled, the skill says so and uses a stated default, or stops and asks. It never guesses a
deploy or migration command.

**One gate, run by everyone.** `scripts/check` is the only list of checks. Claude runs it
before proposing a commit. The pre-commit hook runs its fast checks on staged changes; slow
ones (usually tests) sit behind `full` in the script and wait for Claude's run and CI. CI runs
all of it. A person's commit passes the same gate as Claude's.

**Stop points are enforced, not just asked for.** The skills stop before commit, version
bump, merge and deploy. The repo's settings also put `git commit`, `merge`, `push`,
`rebase`, `reset --hard` and `tag` under `ask`, so Claude Code asks every time, whatever a
skill says. Add your deploy command there too. An `ask` rule wins over a matching `allow`
rule, including a broad one such as `Bash(git:*)` and one from a higher-priority settings
source (tested 2026-10-28 with Claude Code 2.1.312, in the same file and across sources).

**No edits on the main branch.** A hook refuses Edit and Write while the file's repository is
on its main branch (the `Main branch` line in `CLAUDE.md`, else `main` or `master`). Claude
has to cut a branch first, even when a skill did not fire. Files outside a repository are not
affected. A repository that works on main on purpose opts out with an empty file at
`.claude/yotamake/allow-edits-on-main`. The protected-paths list stops Claude creating it
with Edit or Write; a person makes it.

## Sessions

A session is one branch and one merge that fits in one context. `simple-session` first checks
the size against concrete tests (a schema change plus other code, more than one new
interface, more than one service, needs an ADR). If the change is too big, it offers
`multi-session`, which keeps `plan.md`, `findings.md`, `decisions.md` and `log.md` in a
git-ignored `.scratchpad/<date>-<slug>/`. You `/clear` between sessions and resume with:
"Read .scratchpad/<folder>/README.md and start the next session."

In an ephemeral environment (a cloud container), or when the environment assigns one branch,
the folder is committed at `.sessions/<date>-<slug>/` instead, and each session is a set of
commits on that branch, pushed at the end of the session.

Before it stops and reports, `simple-session` runs the built-in `/code-review` at low effort
when the branch changes code (docs-only branches skip it). When the `Integration` line in
`CLAUDE.md` says the project works through pull requests, the last step pushes the branch and
opens a pull request instead of merging locally.

## Docs

Four kinds, each maintained differently: reference (corrected in place), guides (corrected
in place), decisions (never edited, only superseded) and records (written once). When they
disagree: code > decisions > reference > records. Each subject has one owning doc, named in
the "Owns" table in `docs/README.md`. The linter fails on broken links, docs nothing links to,
bad front-matter and a stale records index.

For a repo with existing link debt, run `node scripts/docs/lint-docs.mjs --update-baseline`
once. After that the linter fails on new problems, and on fixed ones still listed.

## Evals

`plugin/evals/` holds six cases. Each runs against a small Node project built fresh by
`evals/_fixture/setup.sh` with the harness installed:

| Case | Checks that Claude… |
|---|---|
| 01-branches-first | tries to branch before editing, and edits nothing on `main` |
| 02-small-change | changes code, test and the owning doc, runs `scripts/check`, proposes a commit and asks |
| 03-too-big | refuses to start a four-part feature and offers a multi-session plan |
| 04-docs-only | fixes a guide, runs the docs check, plans no version bump |
| 05-work-record | writes a valid record and regenerates the index |
| 06-question | answers a question without starting a session (should not fire) |

Run them (needs `bubblewrap` and `socat` on Linux for the sandbox; costs money on your
account, about $3.50 for the full suite with the baseline arm):

```bash
cd plugin
claude plugin eval . --scaffold --allow-tools Bash Write Edit --ablation with-without
```

The headline number is Δ: the score with the plugin minus the score without it. The eval
sandbox does not let Claude write inside `.git`, so cases that need work done start on a
pre-made branch (as an assigned branch would in a cloud session).

## Requirements

`bash`, `git` and Node 18+ (the hooks and installer use it to read JSON; the docs scripts
need it too). Nothing has npm dependencies.
