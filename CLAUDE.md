# CLAUDE.md

This repository is the Yotamake harness: a Claude Code plugin and its marketplace, not a
project that uses it. It also uses its own harness: `./plugin/install.sh .` installed it, and
this file holds the facts its skills read.

## How to work here

Every change to code, tests or docs runs as a session, however small: use the
`yotamake:simple-session` skill. If the change is too big for one session (`simple-session`,
"Check the size"), use `yotamake:multi-session` instead. This holds when the user names the
branch, spells out the exact edit, or says it is quick and not to ask: the skill covers working
on a named branch, and its design check, checks, review, doc update and stop before commit
still apply.
Questions and explanations need no session.

**If the plugin is not loaded** (no `yotamake:` skills are offered, as in a cloud session
without it), read `plugin/skills/simple-session/SKILL.md` (or `multi-session`'s) and follow it
as written. Its hooks are off too, so check you are not on the main branch before an edit, and
leave the files in `.claude/yotamake/protected-paths.conf` alone. The project's `SessionStart`
hook still sets `core.hooksPath`; if `git config core.hooksPath` prints nothing anyway, run
`git config core.hooksPath .githooks` so the pre-commit hook runs.

## Project overview

`plugin/` is the plugin: Markdown skills hold the method, bash hooks enforce parts of it, and
`plugin/install.sh` copies `plugin/template/` into a target repository.
`.claude-plugin/marketplace.json` at the root lists it. `README.md` explains what it is and
how it is split.

- `plugin/template/` is what the installer copies: harness-owned files (listed in
  `install.sh` as `managed`) are refreshed on every run, project-owned ones copied once.
- Before you change a project-owned template file, rename a `CLAUDE.md` section, or point at
  another skill's step, read
  [docs/guides/changing-the-harness.md](./docs/guides/changing-the-harness.md).

**Docs:** [docs/README.md](./docs/README.md) (index — start here; explains the four kinds of
doc and which doc owns what) · [README.md](./README.md) (the overview of the harness; each
skill's `SKILL.md` owns its own rules) · [docs/decisions/](./docs/decisions/README.md) (ADRs — never edited,
only superseded or amended) · [docs/records/](./docs/records/README.md) (history) ·
[docs/backlog.md](./docs/backlog.md) (open work) · [CHANGELOG.md](./CHANGELOG.md) (what each
release changed)

## Commands

```bash
scripts/check                       # the gate; see Checks
./plugin/install.sh <repo> [--lite] # install or refresh the harness in a repository
./plugin/install.sh .               # refresh this repository's own harness copies
claude --plugin-dir ./plugin        # start a session on this branch's plugin, not the released one
cd plugin && claude plugin eval . --case <name> --runs 3 --ablation none \
  --scaffold --trust-plugin --allow-tools Bash Write Edit --no-publish   # costs money; ask first
```

## Checks

**`scripts/check` is the one gate.** Claude's skills, the pre-commit hook and CI all run it.
Add a check by editing that script, not by listing it here.

- `scripts/check` — full checks for what changed since the main branch, plus uncommitted
  work. Claude runs this before proposing a commit.
- `scripts/check --staged` — fast checks only, for what is staged. The pre-commit hook runs
  this. Slow checks sit behind `full` in the script and are left out.
- `scripts/check --all` — every check. CI runs this.

It prints one `PASS`/`FAIL` line per check. A person can skip the git hook once with
`git commit --no-verify`. Claude never does unless the user asks.

**Test-first:** `no`. With `yes`, `simple-session` writes a failing test before a change in
behaviour.

For a hook change, add its case to `scripts/test-hooks.sh`. For an installer change, add one
to `scripts/test-install.sh`.

The eval cases are not in the gate: they cost money. On a branch that changes the plugin,
`scripts/check` ends with a note naming the cases that cover the change (`README.md`, Evals,
says how). Put them in the report and ask before running them (see Commands).

## Branching and releases

- **Main branch:** `main`. Feature work happens on branches cut from it, never on it directly.
  A hook blocks edits while this branch is checked out. Hooks read the name from
  `main-branch` in `.claude/yotamake/project.conf`; change both together.
- **Branch prefixes:** `feat/`, `fix/`, `refactor/`, `perf/`, `docs/`, `test/`, `chore/`. A
  cloud session that is assigned a branch works on that branch as named, with no prefix.
- **Commits:** Conventional Commits, `type(scope): summary`.
- **Integration:** local `git merge --no-ff` into main. In a cloud session with an assigned
  branch, push to that branch instead.
- **Docs-only:** a branch that changes only files under `docs/` and Markdown files at the
  repository root other than `CLAUDE.md`. `CLAUDE.md` and Markdown under `plugin/` are
  code.
- **Session size:** about 400 changed lines or 15 files in one diff, not counting lockfiles
  and generated files. `simple-session` sizes a change against it.
- **Version bump:** a change under `plugin/` that reaches users (anything but `plugin/evals/`)
  bumps `version` in both `plugin/.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json`: patch for a fix, minor for a feature. It is its own
  commit, `chore(release): bump version to X.Y.Z`, which also runs `./plugin/install.sh .`
  and includes what it changes, so this repository's own harness moves with the release. It
  also gives the version its `CHANGELOG.md` entry: rename `## Unreleased` to
  `## X.Y.Z — YYYY-MM-DD`, or add that heading, with one line per change users see.
  Docs-only, evals-only and `scripts/`-only branches do not bump. `scripts/check` fails when
  the two files or `.claude/yotamake/version` disagree, or the version has no changelog entry.
- **Worktree setup:** none. `scripts/check` needs only bash, git and Node, and the working
  folder is reached by its absolute path.
- **Release:** merging to main is the release. After the merge, tag the merge commit
  `vX.Y.Z` (`git tag vX.Y.Z`). `CHANGELOG.md` says which releases have tags and how users
  update.

## Conventions

**Trivial side-fix policy.** When you notice a bug, typo or inconsistency that is *not* part
of the current task, and the fix is trivial and side-effect-free (a doc or comment fix, an
obvious typo, a stale constant with no behavioural reach), fix it without asking, and note it
in the change summary or commit message. Anything non-trivial or with side effects
(behaviour, API, schema or migration changes, refactors, anything that could break callers)
must be raised and confirmed first.

**One owner per subject.** Every subject has one doc that owns it (the "Owns" table in
`docs/README.md`). A change in behaviour updates that doc in the same branch. Other docs link
to it rather than restate it. `README.md` owns the overview of the harness. Each skill's
`SKILL.md` owns its own rules, and the README links to it rather than restating them.

**Rules and enforcers.** [docs/reference/rules-and-enforcers.md](./docs/reference/rules-and-enforcers.md)
pairs each rule here with what enforces it; a new or changed rule updates its row.

**Site pages.** `site/` owns nothing, but it sums up the harness: a skill's purpose, the
session flow, the hooks, the install steps. A branch that changes one of these updates the
page that sums it up. When `scripts/check` names site pages, read each one, and say in the
report which you updated.

**Plain English.** Skills and docs use plain English and short sentences (see
`plugin/output-styles/plain-english.md`).

**Stop points are enforced.** `.claude/settings.json` puts `git commit`, `merge`, `push`,
`rebase`, `reset --hard` and `tag` under `ask`, so Claude Code asks before each one. Do not
work around this with other commands that have the same effect.

## Architecture

The design every change follows. Before writing code, look in **Shared code** for something
to reuse or extend. A change that would cross a **Boundary**, break a **Constraint**, go
against an accepted ADR, or bring in a way of doing things that **Style** or **Patterns** does
not list stops before any edit and is raised with the user, whoever asked for it.

- **Style:** a Claude Code plugin: declarative Markdown skills (the method), small shell
  hooks (enforcement, safe one-time setup, and context at session start), and a copy-in
  template installed by `install.sh`, whose files are either harness-owned (refreshed) or
  project-owned (copied once). Besides the plugin's hooks, the template's
  `.claude/settings.json` has project `SessionStart` hooks, one per harness-owned script in
  `.claude/yotamake/` (ADR-0004), so they work without the plugin. The hooks that gate a
  step ask one dependency-free Node evaluator, `plugin/hooks/steps.mjs`, which reads the
  step order from `plugin/hooks/steps.json` (ADR-0010). Beside the plugin, a
  static landing site (hand-written HTML and CSS, no build step) that a GitHub Pages workflow
  publishes after CI passes.
- **Modules:** `plugin/skills/` the method, one folder per skill; `plugin/hooks/` edit- and
  read-time enforcement; `plugin/install.sh` and `plugin/template/` the per-repository files;
  `plugin/reference/` material skills read on demand (style catalogue, upgrades);
  `plugin/evals/` the eval suite and its fixture; `scripts/` this repository's own checks;
  `site/` the landing site (static HTML, published to GitHub Pages; it sums up and links
  out, and owns no rules).
- **Boundaries:** the plugin stays generic: anything specific to one stack or project goes in
  the target's `CLAUDE.md` or `scripts/check` as a `FILL IN` placeholder, never in a skill or
  hook. Skills read project facts only from named `CLAUDE.md` sections. The installer never
  overwrites a project-owned file, and merges `.claude/settings.json` without removing
  anything. Hooks let the edit through (exit 0) when they cannot decide.
- **Shared code:** `plugin/hooks/lib.sh` for the bash hooks (reading the tool call, and
  `read_fact` for `project.conf`); `plugin/hooks/steps.mjs` for step events and decisions,
  the docs classifier (`isDoc`) and its own `readFact` (ADR-0010);
  `plugin/reference/` for text several skills need;
  `plugin/skills/multi-session/templates/` for working-folder files (`spec` uses `spec.md`);
  `generate-records-index.mjs` exports the front-matter reader `lint-docs.mjs` uses;
  `plugin/evals/_fixture/` builds and installs eval repositories, and
  `plugin/evals/_graders/` holds the source copy of graders several cases share.
- **Patterns:** bash hooks get the edited path with `tool_file_path` from `lib.sh`, and block
  with exit 2 and a message on stderr. Session steps are events in `yotamake-events` in the
  git dir, recorded and judged by `steps.mjs`; a new step rule goes in `steps.json`. Per-repository hook settings live in `.claude/yotamake/*.conf`;
  the project facts hooks read are in `project.conf`, a copy of `CLAUDE.md` lines (ADR-0008).
  Skills name the `CLAUDE.md` sections they read in bold and say what to do when one is
  missing or unfilled. A change to a project-owned template file gets an `upgrades.md` entry.
- **Constraints:** needs only `bash`, `git` and Node 18+; no npm dependencies. Runs on Linux
  and macOS (BSD `sed`: use `sed -i.bak`, not `sed -i`). `claude plugin validate --strict`
  passes for the plugin and the marketplace.
- **Domain language:** [docs/reference/glossary.md](./docs/reference/glossary.md).
- **Decisions:** accepted ADRs in [docs/decisions/](./docs/decisions/README.md) are part of
  the design. A change that needs a different one gets a new ADR first.
