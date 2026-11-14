# Yotamake

A development harness for Claude Code. It gives any repository the same working method:
small sessions on branches, design and reuse checked before code, one check command that
everyone runs, nothing committed or deployed without a "yes", and a docs system that stays
true.

It started as the `.claude/` setup and docs rules of a single application project.

The website, [redazzo.github.io/Yotamake](https://redazzo.github.io/Yotamake/), introduces
the harness and walks through getting started. This README holds the detail.

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
lines that call `.githooks/pre-commit` from the other tool. The same tests run at the start of
every Claude Code session, from a `SessionStart` hook in the repo's `.claude/settings.json`
(ADR-0004), so a fresh clone gets the setting too.

If the repo already has its own version of a template file, such as a docs linter, list the
harness path in `.claude/yotamake/skip` (one per line). The installer never writes a listed
path, and adds no `allow` rule or hook entry for a listed script the repo does not have.
To turn off the `SessionStart` hook that sets `core.hooksPath`, list
`.claude/yotamake/set-hooks-path.sh` there and delete the file. The same goes for
`.claude/yotamake/session-context.sh`, the second `SessionStart` hook: at the start of each
session it adds a few lines to Claude's context (the branch and whether it is the main
branch, any active multi-session effort and its next session, and the rule that every change
runs as a session), so the method holds even when a skill does not fire.

**Lite mode.** For a small repo that does not want the docs system (ADRs, records, backlog),
run `install.sh <repo> --lite`, or ask `/yotamake:setup` for lite mode. It installs
`CLAUDE.md`, `scripts/check`, the pre-commit hook, the hook config and settings, but nothing
under `docs/` or `scripts/docs/`. It writes those paths into `.claude/yotamake/skip`, so later
runs leave them out too, and drops the docs lines from the new `CLAUDE.md` and
`scripts/check`. To add the docs system later, delete those lines from the skip file, re-run
the installer, and add the docs check to `scripts/check` by hand.

**Updating.** `claude plugin update yotamake@yotamake` updates the method for every repo at
once. Re-run `/yotamake:setup` (or `install.sh`) in a repo to refresh its harness-owned
scripts; it never overwrites the files that belong to the project. It also regenerates
`docs/records/README.md` when it is stale. That file is generated, not written by hand, and
a refreshed generator could otherwise leave the docs check failing.

When a new version needs something added to those files, such as a new line in `CLAUDE.md`,
`plugin/reference/upgrades.md` says what and how to check for it. The installer records the
version it ran in `.claude/yotamake/version`. When a session starts in a repo older than the
plugin, the plugin's `SessionStart` hook tells Claude so in one line, and Claude offers the
upgrades still missing (`simple-session`, "Harness upgrades").
`/yotamake:setup` applies them on a refresh.

## How it is split

| Lives in | What | Who changes it |
|---|---|---|
| The plugin (`plugin/`) | Skills, hooks, output style, the installer and template | This repo; reaches every project on update |
| Each repository | `CLAUDE.md` facts, `scripts/check`, `docs/`, hook config, CI workflow | The project |
| Each repository, harness-owned | `scripts/docs/*.mjs`, `.githooks/pre-commit`, `.claude/yotamake/set-hooks-path.sh`, `.claude/yotamake/session-context.sh`, `.claude/yotamake/version` | Refreshed by the installer |

### The plugin

```
plugin/
  .claude-plugin/plugin.json
  skills/
    simple-session/   one change: size check, branch, work, docs, scripts/check, stop and ask
    multi-session/    work across several contexts, with a working folder that survives /clear
    debugging/        a bug fix inside a session: reproduce, failing test, root cause, fix
    write-doc/        pick the doc kind, write it, link it, lint it
    spec/             agree scope and acceptance criteria before code  (manual: /yotamake:spec)
    release-check/    guided deploy with pre-flight and gotchas      (manual: /yotamake:release-check)
    new-migration/    scaffold a timestamped migration file         (manual: /yotamake:new-migration)
    setup/            install or refresh the per-repo files         (manual: /yotamake:setup)
    doctor/           check the harness works in this repo, read-only (manual: /yotamake:doctor)
    drawio/           draw.io diagrams
  hooks/
    hooks.json                     registers the seven hooks below
    pre-edit-protect.sh            blocks edits to protected files (.env, keys, certificates)
    pre-edit-main-branch.sh        blocks edits while the repository is on its main branch
    pre-bash-git.sh                blocks --no-verify, and git commit on the main branch, from Bash
    post-edit-check.sh             runs a fast per-file check after each edit
    post-edit-mark.sh              notes that this session edited a code file
    stop-check-ran.sh              blocks the end of a turn once when scripts/check has not passed since
    session-upgrades.sh            at session start, tells Claude when the repo's harness is older than the plugin
    lib.sh                         shared by the hooks: reads the hook input, finds the gate files
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
.claude/settings.json           enables the plugin; "ask" rules for commit, merge, push, …;
                                SessionStart hooks that run the two scripts below
.claude/yotamake/
  set-hooks-path.sh             sets core.hooksPath to .githooks in a clone that lacks it
  session-context.sh            tells Claude the branch, active efforts and the session rule
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
skills read: **Style**, **Modules**, **Boundaries**, **Shared code**, **Patterns** and
**Constraints**, plus the accepted ADRs in a full install. The template explains each line.
`/yotamake:setup` proposes them from the repo, naming the style from
`plugin/reference/architecture-styles.md`. Before any edit, `simple-session` looks for code to
reuse, and stops and asks when a change would break the design, even when told not to ask.
The rules are in `simple-session`, "Design and reuse". `scripts/check` has commented examples
for a boundary check and a duplicate-code check; the project picks the tool.

**One gate, run by everyone.** `scripts/check` is the only list of checks. Claude runs it
before proposing a commit. The pre-commit hook runs its fast checks on staged changes; slow
ones (usually tests) sit behind `full` in the script and wait for Claude's run and CI. CI runs
all of it. A person's commit passes the same gate as Claude's, with one catch:
`core.hooksPath` is a local git setting and is not cloned. The project's `SessionStart` hook
sets it at a teammate's first Claude Code session in the clone, with or without the plugin
loaded, and says so in one line. A teammate who never opens Claude Code there must run
`git config core.hooksPath .githooks` themselves. CI covers everyone.

**Claude cannot end a turn with unchecked code.** When `scripts/check` passes (not with
`--staged`), it touches `yotamake-check-passed` in the git directory. When Claude edits a code
file with Edit or Write, a hook writes the session id to `yotamake-edited` there. Docs and
git-ignored files do not count. The hook uses the default `Docs-only` rule (files under
`docs/`, and Markdown at the root other than `CLAUDE.md`): it cannot read a project's own
`Docs-only` line, so other doc paths count as code and cost one extra check run. When Claude ends a turn after
editing code in this session and the stamp is older than that edit, a `Stop` hook blocks
once and tells it to run the check. A second stop goes through, so Claude can still stop to
ask a question. A turn that edited no code, such as a question, is never blocked, and neither
is a repository whose `scripts/check` does not write the stamp (one set up before 0.15.0).

**Stop points are enforced, not just asked for.** The skills stop before commit, version
bump, merge and deploy. The repo's settings also put `git commit`, `merge`, `push`,
`rebase`, `reset --hard` and `tag` under `ask`, so Claude Code asks every time, whatever a
skill says. Add your deploy command there too. An `ask` rule wins over a matching `allow`
rule, including a broad one such as `Bash(git:*)` and one from a higher-priority settings
source (tested 2026-10-28 with Claude Code 2.1.312, in the same file and across sources).
Cutting or switching branches with `git switch`, staging files and a fast-forward pull are
under `allow`, so they do not prompt. `git switch` with `-f`, `--force`,
`--discard-changes`, `-C` or `--force-create` first in its options is under `ask`, since it
drops uncommitted work or resets a branch. The rules match from the start of the command, so
the same flag later on is not caught.

**No edits on the main branch.** A hook refuses Edit and Write while the file's repository is
on its main branch (the `Main branch` line in `CLAUDE.md`, else `main` or `master`). Claude
has to cut a branch first, even when a skill did not fire. Files outside a repository are not
affected, nor are git-ignored ones (such as a multi-session `.scratchpad/` folder). A repository that works on main on purpose opts out with an empty file at
`.claude/yotamake/allow-edits-on-main`. The protected-paths list stops Claude creating it
with Edit or Write; a person makes it.

**No skipped hooks, no commits on main.** A hook on Bash refuses any git command with
`--no-verify` (or `git commit -n`), so Claude cannot step past the gate, even in a repository
that opted out above. A person who wants to skip it runs the command themselves with
`! <command>`. The same hook refuses `git commit` while the repository is on its main branch,
read as above, unless a merge is being finished, the repository has no commits yet, or it
opted out. It reads the
command with a small quote-aware parser and follows `cd <dir>` and `git -C <dir>`; text inside
quotes, such as a commit message, does not count. A command it cannot read goes through.

**Worktrees.** Every hook acts on the repository of the file being edited, else on the
session's own directory (the `cwd` in the hook's input), and only then on
`CLAUDE_PROJECT_DIR`, which stays at the main checkout after `EnterWorktree`. So the
protected-paths list, the per-file checks, the `Stop` gate and the upgrade notice work the
same in a linked worktree (ADR-0005). The `Stop` gate also looks in the repository's other
worktrees, so an edit made by absolute path into a linked worktree from the main checkout
still needs a passing `scripts/check` in that worktree. In a linked worktree, `session-context.sh` also lists
the efforts in the main worktree's `.scratchpad/`, by full path, because a worktree has no
copy of that git-ignored folder.

**What the hooks do not cover.** The main-branch, protected-paths and edit-marking hooks
watch Edit and Write only. The Bash hook above watches git commands only. A shell command gets past them: `sed -i`, `echo > .env`, `touch`
on the opt-out file, or a code change made from the shell, which the `Stop` hook never sees. Claude Code's own permission prompt for Bash is the guard there. The `ask`
rules are separate, and `git -C . commit` still asked in a test (one run, Claude Code
2.1.312).

## Sessions

This section is an overview. Each skill's `SKILL.md` holds its rules and is the one to change.

A session is one branch and one merge that fits in one context
([`simple-session`](./plugin/skills/simple-session/SKILL.md)). It checks the size first, and
with `Test-first: yes` in `CLAUDE.md` it writes a failing test before a change in behaviour. A
bug fix follows [`debugging`](./plugin/skills/debugging/SKILL.md): reproduce it, write a
failing test, find and name the root cause, then fix it. A change too big for one session becomes a
[`multi-session`](./plugin/skills/multi-session/SKILL.md) effort, with a working folder that
survives `/clear`: git-ignored at `.scratchpad/<date>-<slug>/`, or committed at
`.sessions/<date>-<slug>/` in an ephemeral environment or on an assigned branch. You `/clear`
between sessions and resume with:
"Read .scratchpad/<folder>/README.md and start the next session."

**Specs.** For a new feature, or a change where "done" is unclear, run `/yotamake:spec`
first ([`spec`](./plugin/skills/spec/SKILL.md)). It agrees the scope and numbered acceptance
criteria in one short file before any code, then hands over to a session. Fixes, renames and
refactors skip it.

**Review.** Once per session, after the checks pass, `simple-session` reviews the whole
branch diff with the built-in `/simplify` and `/code-review`, and against Architecture.
Docs-only branches skip it, and so do trivial ones (every changed line a comment or a prose
typo). The `Docs-only` line in `CLAUDE.md` says which files are docs; the top of
`simple-session` has the default and says what counts as trivial. When the `Integration`
line in `CLAUDE.md` says the project works through pull requests, the session ends by
pushing and opening one instead of merging locally.

**Parallel sessions.** Two sessions of one effort that need nothing from each other and
change different files may run at once, each in a sibling `git worktree` with its own Claude
Code conversation, and merge one at a time (ADR-0005; `multi-session`, "Running sessions in
parallel"). The `Worktree setup` line in `CLAUDE.md` says what a new worktree needs.

**Autopilot.** Approve S0's plan and say "run autopilot" (or "continue autopilot" when
resuming), and the remaining sessions run without you, each in a fresh built-in agent. It
ends with one report and one question: merge. Nothing is pushed or merged without your yes
(ADR-0007; `multi-session`, "Autopilot").

**Subagents.** A `multi-session` S0 hands its reading to built-in agents, one per area, so
the main context keeps room for the plan. The review hands its design read to one agent
(`simple-session`, "Review").

## Docs

Four kinds, each maintained differently: reference (corrected in place), guides (corrected
in place), decisions (never edited, only superseded) and records (written once). When they
disagree: code > decisions > reference > records. Each subject has one owning doc, named in
the "Owns" table in `docs/README.md`. The linter fails on broken links, docs nothing links to,
bad front-matter and a stale records index.

For a repo with existing link debt, run `node scripts/docs/lint-docs.mjs --update-baseline`
once. After that the linter fails on new problems, and on fixed ones still listed.

## Evals

`plugin/evals/` holds the cases below. Each runs against a small Node project built fresh by
`evals/_fixture/setup.sh` with the harness installed (case 11 builds its own):

| Case | Skills | Checks that Claude… |
|---|---|---|
| 01-branches-first | `simple-session` | tries to branch before editing, and edits nothing on `main` |
| 02-small-change | `simple-session` | changes code, test and the owning doc, runs `scripts/check`, `/simplify` and `/code-review`, hands the design read to an agent, proposes a commit and asks |
| 03-too-big | `simple-session`, `multi-session` | refuses to start a four-part feature and offers a multi-session plan |
| 04-docs-only | `simple-session`, `write-doc` | fixes a guide, runs the docs check, plans no version bump |
| 05-work-record | `simple-session`, `write-doc` | writes a valid record and regenerates the index |
| 06-question | `simple-session`, `multi-session` | answers a question without starting a session (should not fire) |
| 07-multi-session-start | `multi-session` | writes a `.scratchpad/` plan for a multi-session effort, edits no code, gives the resume line |
| 08-multi-session-resume | `multi-session` | resumes at the first session not done and asks its open decision before editing |
| 09-release-check-no-section | `release-check` | refuses to deploy when CLAUDE.md has no Deploying section, and guesses no command |
| 10-new-migration | `new-migration` | names the migration with the next sequence number and warns about the remote command |
| 11-setup-fill-in | `setup` | fills in `scripts/check` and CLAUDE.md after an install, runs the check, asks before committing |
| 12-spec-first | `spec` | writes a `spec-*.md` file with numbered acceptance criteria, edits no code, asks for approval |
| 13-reuse | `simple-session` | reuses the shared `titleCase` helper instead of copying its logic, reports "Reused:", runs the review |
| 14-boundary | `simple-session` | told "no need to ask", still stops before breaking the fixture's "src/ is pure" boundary, and asks |
| 15-follow-up-review | `simple-session` | after a reported change, asked for one more, runs `/simplify` and `/code-review` exactly once more |
| 16-multi-session-reuse | `multi-session` | plans a multi-session feature whose `plan.md` Design section reuses the shared `titleCase` helper, edits no code, asks to agree the design |
| 17-upgrade-offer | `simple-session`, `multi-session` | in a repo set up before 0.11.0, names the missing Style line and asks whether to apply it before editing anything |
| 18-multi-session-docs-ledger | `multi-session`, `simple-session` | resumes an effort at S2, changes code, test and the owning doc, adds an S2 row to the docs ledger, asks before committing |
| 19-claude-md-only | `simple-session` | with no `Docs-only` line, changes only `CLAUDE.md` and treats it as code by the default rule, runs `scripts/check`, `/simplify` and `/code-review`, asks before committing |
| 20-trivial-change | `simple-session` | fixes a typo in a code comment, runs `scripts/check` but neither `/simplify` nor `/code-review`, says the change is trivial and why, asks before committing |
| 21-debugging | `simple-session`, `debugging` | for a crash that shows in one helper but starts in another, writes a failing test first, fixes the helper that makes the bad value rather than guarding where it throws, names the root cause, asks before committing |
| 22-multi-session-autopilot-offer | `multi-session` | ends S0 by offering autopilot next to the resume line, and starts no session until it is chosen, though the user would rather not babysit |

**Skills** lists every skill whose text a case exercises. On a branch that changes the
plugin, `scripts/check` uses it to name the cases worth running: those that list a changed
skill, or a skill that reads a changed `plugin/reference/` file, and every case when the
hooks, installer, template or fixture change. It also names changed plugin files that no case
covers. It is a note, not a check, because the cases cost money.

Every case installs the harness with `evals/_fixture/install-harness.sh`; case 11 calls it
directly because it builds its own repository. A grader several cases share has its source
copy in `evals/_graders/`; `scripts/check` fails when a case's copy differs, and
`node scripts/consistency.mjs sync-graders` copies it into every case that uses it.

Run them (needs `bubblewrap` and `socat` on Linux for the sandbox; costs money on your
account, about $7 for the full suite with the baseline arm):

```bash
cd plugin
claude plugin eval . --scaffold --allow-tools Bash Write Edit --ablation with-without
```

Each run is saved as `plugin/evals/results/<timestamp>/aggregate-result.json` (git-ignored),
with every run's pass, cost, turns and seconds, and the Claude Code and plugin versions. To
see what the cases cost, run `node scripts/eval-costs.mjs` from the repository root. It
prints one row per case: runs, pass rate, and mean cost, turns and seconds. Name one results
folder to cover only that run. The results hold no token counts.

The headline number is Δ: the score with the plugin minus the score without it. The eval
sandbox does not let Claude write inside `.git`, so cases that need work done start on a
pre-made branch (as an assigned branch would in a cloud session). It also keeps `.claude/`
read-only, so `install.sh` cannot run inside a case; case 11's scaffold runs it instead.
Until a Claude Code bug is fixed, the sandbox also denies the agent `git` itself, so graders
that need `scripts/check` or the review fail for that reason (backlog, "Eval sandbox denies
`git`").
Cases 09–12 start with a slash command, since those skills are not model-invoked.
Case 15 resumes a recorded first turn (`history.jsonl`, a run of case 13) and its prompt is
the next message. The history holds the `simple-session` text, the system prompt and the
Claude Code version from when it was recorded. So after changing that skill or upgrading
Claude Code, re-record it with `bash evals/15-follow-up-review/record.sh` (from `plugin/`; it
costs one run and strips the user's email from the transcript).

## Open work

[docs/backlog.md](./docs/backlog.md) lists it, each item with the trigger that should make
someone pick it up.

## Developing Yotamake

This repository uses its own harness: `./plugin/install.sh .` installed it, and
[CLAUDE.md](./CLAUDE.md) holds its facts. `scripts/check` checks syntax, that versions,
section names, Architecture labels and the eval table agree, the docs, the hooks (fake tool
calls, `scripts/test-hooks.sh`), the installer (scratch installs, `scripts/test-install.sh`)
and `claude plugin validate`. After changing a harness-owned template file
(`scripts/docs/*.mjs`, `.githooks/pre-commit`), re-run `./plugin/install.sh .` so this
repository's own copies match; the check fails until they do. Releases re-run it too (CLAUDE.md,
Version bump). The docs baseline
(`scripts/docs/docs-lint-baseline.txt`) holds one entry on purpose: the template `CLAUDE.md`
links `./README.md`, which exists only once the template is installed.

**The website.** `site/` is the landing site: plain HTML and CSS, no build step.
`.github/workflows/pages.yml` publishes it to GitHub Pages each time CI passes on main, and
fills in the version from `plugin.json`. The pages sum up the harness and link here and to
each `SKILL.md` for the rules. So a change to what a page says, such as the install command or
a skill's purpose, updates that page on the same branch. `scripts/check` checks the site's
links, and that `site/skills.html` has a card for every skill. To view it locally, open
`site/index.html` in a browser; the version shows as `__VERSION__` until it is published.

## Requirements

`bash`, `git` and Node 18+ (the hooks and installer use it to read JSON; the docs scripts
need it too). Nothing has npm dependencies.
