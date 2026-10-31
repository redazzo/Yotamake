# Yotamake

A development harness for Claude Code. It gives any repository the same working method:
small sessions on branches, design and reuse checked before code, one check command that
everyone runs, nothing committed or deployed without a "yes", and a docs system that stays
true.

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

If the repo has no `README.md`, a full install writes a stub, because `CLAUDE.md` links to
it and the docs check would fail without it.

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

When a new version needs something added to those files, such as a new line in `CLAUDE.md`,
`plugin/reference/upgrades.md` says what and how to check for it. The installer records the
version it ran in `.claude/yotamake/version`. When `simple-session` or `multi-session` starts in
a repo older than the plugin, it lists the upgrades still missing and asks: apply now (on a
`chore/yotamake-upgrade` branch of its own), not now, or skip these. `/yotamake:setup` applies
them on a refresh.

## How it is split

| Lives in | What | Who changes it |
|---|---|---|
| The plugin (`plugin/`) | Skills, hooks, output style, the installer and template | This repo; reaches every project on update |
| Each repository | `CLAUDE.md` facts, `scripts/check`, `docs/`, hook config, CI workflow | The project |
| Each repository, harness-owned | `scripts/docs/*.mjs`, `.githooks/pre-commit`, `.claude/yotamake/version` | Refreshed by the installer |

### The plugin

```
plugin/
  .claude-plugin/plugin.json
  skills/
    simple-session/   one change: size check, branch, work, docs, scripts/check, stop and ask
    multi-session/    work across several contexts, with a working folder that survives /clear
    write-doc/        pick the doc kind, write it, link it, lint it
    spec/             agree scope and acceptance criteria before code  (manual: /yotamake:spec)
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
  reference/architecture-styles.md styles with the boundaries, patterns and gates each implies
  reference/upgrades.md            per version: what to add to a repo's own files, and how
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
  version                       the plugin version the harness files were installed from
docs/                           README (rulebook and index), backlog, decisions, records, …
scripts/docs/                   docs linter and records index generator
```

## The three ideas

**Skills hold the method. `CLAUDE.md` holds the facts.** Skills read named sections
(Checks, Branching and releases, Migrations, Deploying, Conventions, Architecture). If one is
missing or unfilled, the skill says so and uses a stated default, or stops and asks. It never
guesses a deploy or migration command.

**Design comes before code.** The `Architecture` section of `CLAUDE.md` has six lines the
skills read: **Style** (the architecture style or styles, such as layered, hexagonal or
event-driven, and where each applies), **Modules** (the main parts and what each owns),
**Boundaries** (rules a change must not break), **Shared code** (where reusable code lives),
**Patterns** (the one way the project does errors, config, logging and other recurring things)
and **Constraints** (limits from outside the code, such as runtime versions, size budgets,
licences or data rules). In a full install it also points at the accepted ADRs.
`/yotamake:setup` proposes these lines from the repo, naming the style from a catalogue in
`plugin/reference/architecture-styles.md` that also lists the boundaries and gates each style
implies. Before writing code, `simple-session` looks for existing code to reuse, starting in
Shared code, and puts the change in the module that owns it. If a change would break a boundary
or a constraint, step outside the style, go against an ADR, bring in a pattern the project does
not use, or add a dependency that overlaps one it already has, it stops before any edit and
asks, with options. Other new dependencies go ahead and are named in the report. It does this
even when the user asked for exactly that change or said not to ask: changing the rule is a
separate decision. The report says what was reused and why any new code was needed. If the
section is unfilled, the skill follows the code's own structure and says so. `scripts/check`
has commented examples for a boundary check and a duplicate-code check (dependency-cruiser,
import-linter, jscpd); the project picks the tool.

**One gate, run by everyone.** `scripts/check` is the only list of checks. Claude runs it
before proposing a commit. The pre-commit hook runs its fast checks on staged changes; slow
ones (usually tests) sit behind `full` in the script and wait for Claude's run and CI. CI runs
all of it. A person's commit passes the same gate as Claude's, with one catch:
`core.hooksPath` is a local git setting and is not cloned. A teammate gets the pre-commit
hook only after running `/yotamake:setup` or `install.sh` (or
`git config core.hooksPath .githooks`) in their clone. Enabling the plugin alone does not set
it. CI covers everyone.

**Stop points are enforced, not just asked for.** The skills stop before commit, version
bump, merge and deploy. The repo's settings also put `git commit`, `merge`, `push`,
`rebase`, `reset --hard` and `tag` under `ask`, so Claude Code asks every time, whatever a
skill says. Add your deploy command there too. An `ask` rule wins over a matching `allow`
rule, including a broad one such as `Bash(git:*)` and one from a higher-priority settings
source (tested 2026-10-28 with Claude Code 2.1.312, in the same file and across sources).

**No edits on the main branch.** A hook refuses Edit and Write while the file's repository is
on its main branch (the `Main branch` line in `CLAUDE.md`, else `main` or `master`). Claude
has to cut a branch first, even when a skill did not fire. Files outside a repository are not
affected, nor are git-ignored ones (such as a multi-session `.scratchpad/` folder). A repository that works on main on purpose opts out with an empty file at
`.claude/yotamake/allow-edits-on-main`. The protected-paths list stops Claude creating it
with Edit or Write; a person makes it.

**What the hooks do not cover.** The main-branch and protected-paths hooks watch Edit and
Write only. A shell command gets past them: `sed -i`, `echo > .env`, or `touch` on the
opt-out file. Claude Code's own permission prompt for Bash is the guard there. The `ask`
rules are separate, and `git -C . commit` still asked in a test (one run, Claude Code
2.1.312).

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

**Specs.** For a new feature, or a behaviour change where "done" is unclear, run
`/yotamake:spec` first. It asks one question at a time, then writes one short `spec.md`: the
problem, scope, what is not in scope, and numbered acceptance criteria (A1, A2, …). It edits
no code until you approve it. Then it hands over to `simple-session` (the report lists how
each criterion was checked) or `multi-session` (the spec lives in the working folder and each
session names the criteria it delivers). A multi-session effort that builds new behaviour
writes the spec in S0 without the command. A spec written before any session is one file,
`spec-<date>-<slug>.md`, in `.scratchpad/` (or committed in `.sessions/` in an ephemeral
environment), so it is never mistaken for a working folder. The spec is deleted when the
work is done; behaviour that lasts goes into the reference doc that owns it, so there is no
second, drifting copy. Fixes, renames and refactors skip it. The skill is manual so that it
does not compete with `simple-session` for the trigger.

Once per session, after the checks pass and before it reports, `simple-session` reviews the
whole branch diff in three parts: reuse (the built-in `/simplify`, keeping only fixes to the
branch's own code), design (the diff against Architecture), and bugs (the built-in
`/code-review` at low effort). It runs for any branch that changes code, however small, but
never after each edit, and fixing its findings does not start a second review. Docs-only
branches skip it. A `multi-session` plan for code has a Design section (modules touched, code
reused, new interfaces, boundaries and constraints at risk), agreed before S1. When the `Integration` line in
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

`plugin/evals/` holds seventeen cases. Each runs against a small Node project built fresh by
`evals/_fixture/setup.sh` with the harness installed (case 11 builds its own):

| Case | Checks that Claude… |
|---|---|
| 01-branches-first | tries to branch before editing, and edits nothing on `main` |
| 02-small-change | changes code, test and the owning doc, runs `scripts/check`, `/simplify` and `/code-review`, proposes a commit and asks |
| 03-too-big | refuses to start a four-part feature and offers a multi-session plan |
| 04-docs-only | fixes a guide, runs the docs check, plans no version bump |
| 05-work-record | writes a valid record and regenerates the index |
| 06-question | answers a question without starting a session (should not fire) |
| 07-multi-session-start | writes a `.scratchpad/` plan for a multi-session effort, edits no code, gives the resume line |
| 08-multi-session-resume | resumes at the first session not done and asks its open decision before editing |
| 09-release-check-no-section | refuses to deploy when CLAUDE.md has no Deploying section, and guesses no command |
| 10-new-migration | names the migration with the next sequence number and warns about the remote command |
| 11-setup-fill-in | fills in `scripts/check` and CLAUDE.md after an install, runs the check, asks before committing |
| 12-spec-first | writes a `spec-*.md` file with numbered acceptance criteria, edits no code, asks for approval |
| 13-reuse | reuses the shared `titleCase` helper instead of copying its logic, reports "Reused:", runs the review |
| 14-boundary | told "no need to ask", still stops before breaking the fixture's "src/ is pure" boundary, and asks |
| 15-follow-up-review | after a reported change, asked for one more, runs `/simplify` and `/code-review` exactly once more |
| 16-multi-session-reuse | plans a multi-session feature whose `plan.md` Design section reuses the shared `titleCase` helper, edits no code, asks to agree the design |
| 17-upgrade-offer | in a repo set up before 0.11.0, names the missing Style line and asks whether to apply it before editing anything |

Run them (needs `bubblewrap` and `socat` on Linux for the sandbox; costs money on your
account, about $7 for the full suite with the baseline arm):

```bash
cd plugin
claude plugin eval . --scaffold --allow-tools Bash Write Edit --ablation with-without
```

The headline number is Δ: the score with the plugin minus the score without it. The eval
sandbox does not let Claude write inside `.git`, so cases that need work done start on a
pre-made branch (as an assigned branch would in a cloud session). It also keeps `.claude/`
read-only, so `install.sh` cannot run inside a case; case 11's scaffold runs it instead.
Cases 09–12 start with a slash command, since those skills are not model-invoked.
Case 15 resumes a recorded first turn (`history.jsonl`, a run of case 13) and its prompt is
the next message. The history holds the `simple-session` text, the system prompt and the
Claude Code version from when it was recorded. So after changing that skill or upgrading
Claude Code, re-record it with `bash evals/15-follow-up-review/record.sh` (from `plugin/`; it
costs one run and strips the user's email from the transcript).

## Open work

- **CI is written but not active.** `docs/ci.yml` runs the "Before committing" checks from
  `CLAUDE.md`. The GitHub App cannot push under `.github/workflows/`, so it needs adding there
  by hand. Then add a line about it to `CLAUDE.md`, "Before committing" (it pins the Claude
  Code CLI version; bump that on purpose).
- **`simple-session` can miss when the user names a branch.** After a first fix it fired in
  5 of 6 eval runs (`02-small-change`). Version 0.7.3 moves the trigger to the front of the
  skill description and says the same in the template `CLAUDE.md`. It then fired in 10 of 10
  runs (2026-10-29, Claude Code 2.1.312, one model). Likely fixed; re-check on the next full
  suite run.
- **`spec` is only partly tested.** Case 12 passed 3 of 3 runs (2026-10-29, Claude Code
  2.1.312, one model). Nothing yet tests the question-at-a-time path or the hand-over to a
  session. A recorded history, as in case 15, could test both.
- **The review was often skipped.** Before 0.9.0, Claude skipped `/simplify` and
  `/code-review` in about 5 of 6 code-change eval runs; after it, in 1 of 6, by reading the
  diff by hand. Versions 0.9.1 to 0.9.3 say that reading the diff does not replace the two
  skills, that the review runs once per session (never per edit), and that a follow-up
  change gets one more full review. Latest runs (2026-10-29, Claude Code 2.1.312, one model):
  13-reuse and 02-small-change passed 3 of 3 each, with each skill called exactly once per
  run. Case 15 (0.9.4, with its clarified graders) passed 3 of 3, each skill called exactly
  once per run. Likely fixed; re-check on the next full suite run.
- **No plugin icon.** `claude plugin validate` warns `ICON_MISSING`.
- **Untested paths.** No eval case for `simple-session`'s pull-request path, or for `setup`'s
  install step (the eval sandbox keeps `.claude/` read-only).
- **Stale-docs check: designed, not built.** See `docs/stale-docs-check.md`, which says when
  to build it.

## Requirements

`bash`, `git` and Node 18+ (the hooks and installer use it to read JSON; the docs scripts
need it too). Nothing has npm dependencies.
