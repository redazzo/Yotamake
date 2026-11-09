# CLAUDE.md

This repository is the Yotamake harness: a Claude Code plugin and its marketplace, not a
project that uses it. It also uses its own harness: `./plugin/install.sh .` installed it, and
this file holds the facts its skills read.

## How to work here

Every change to code, tests or docs runs as a session, however small: use the
`yotamake:simple-session` skill. If the change will not fit one branch and one context, use
`yotamake:multi-session` instead. This holds when the user names the branch, spells out
the exact edit, or says it is quick and not to ask: the skill covers working on a named branch,
and its design check, checks, review, doc update and stop before commit still apply.
Questions and explanations need no session.

## Project overview

`plugin/` is the plugin: Markdown skills hold the method, bash hooks enforce parts of it, and
`plugin/install.sh` copies `plugin/template/` into a target repository.
`.claude-plugin/marketplace.json` at the root lists it. `README.md` explains what it is and
how it is split.

- `plugin/template/` is what the installer copies. Project-owned files there are copied only
  when missing; harness-owned ones (listed in `install.sh` as `managed`) are refreshed on
  every run.
- A skill that needs a project fact names the `CLAUDE.md` section it reads. If you rename a
  section in `plugin/template/CLAUDE.md`, update every skill that names it, the eval
  fixture's `CLAUDE.md`, and `README.md`.
- A skill, hook or reference doc that points at another skill's step names its heading
  without the number, as `simple-session`, "Design and reuse", so renumbering that skill
  cannot break the pointer. Steps inside one skill may use numbers. `scripts/check` checks
  both rules.
- When you change a project-owned template file (anything in `plugin/template/` not listed as
  `managed`), add an entry to `plugin/reference/upgrades.md`: how to check it is applied, and
  how to apply it. Older installs get it from there.

**Docs:** [docs/README.md](./docs/README.md) (index — start here; explains the four kinds of
doc and which doc owns what) · [README.md](./README.md) (what the harness is; it owns the
harness's behaviour) · [docs/decisions/](./docs/decisions/README.md) (ADRs — never edited,
only superseded) · [docs/records/](./docs/records/README.md) (history) ·
[docs/backlog.md](./docs/backlog.md) (open work)

## Commands

```bash
scripts/check                       # the gate; see Checks
./plugin/install.sh <repo> [--lite] # install or refresh the harness in a repository
./plugin/install.sh .               # refresh this repository's own harness copies
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

For a hook change, add its case to `scripts/test-hooks.sh`. For an installer change, add one
to `scripts/test-install.sh`.

The eval cases are not in the gate: they cost money. For a skill change, name the affected
cases in the report and ask before running them (see Commands).

## Branching and releases

- **Main branch:** `main`. Feature work happens on branches cut from it, never on it directly.
  A hook blocks edits while this branch is checked out; it reads the name from this line.
- **Branch prefixes:** `feat/`, `fix/`, `refactor/`, `perf/`, `docs/`, `test/`, `chore/`. A
  cloud session that is assigned a branch works on that branch as named, with no prefix.
- **Commits:** Conventional Commits, `type(scope): summary`.
- **Integration:** local `git merge --no-ff` into main. In a cloud session with an assigned
  branch, push to that branch instead.
- **Version bump:** a change under `plugin/` that reaches users (anything but `plugin/evals/`)
  bumps `version` in both `plugin/.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json`: patch for a fix, minor for a feature. It is its own
  commit, `chore(release): bump version to X.Y.Z`. Docs-only, evals-only and `scripts/`-only
  branches do not bump. `scripts/check` fails when the two files disagree.
- **Release:** merging to main is the release. Users get it with
  `claude plugin update yotamake@yotamake`.

## Conventions

**Trivial side-fix policy.** When you notice a bug, typo or inconsistency that is *not* part
of the current task, and the fix is trivial and side-effect-free (a doc or comment fix, an
obvious typo, a stale constant with no behavioural reach), fix it without asking, and note it
in the change summary or commit message. Anything non-trivial or with side effects
(behaviour, API, schema or migration changes, refactors, anything that could break callers)
must be raised and confirmed first.

**One owner per subject.** Every subject has one doc that owns it (the "Owns" table in
`docs/README.md`). A change in behaviour updates that doc in the same branch. Other docs link
to it rather than restate it. The harness's own behaviour is owned by `README.md`.

**Plain English.** Skills and docs use plain English and short sentences (see
`plugin/output-styles/plain-english.md`).

**Work that spans several contexts** runs as numbered sessions with a working folder that
survives `/clear`: git-ignored under `.scratchpad/`, or committed under `.sessions/` in an
ephemeral environment. See the `yotamake:multi-session` skill.

**Stop points are enforced.** `.claude/settings.json` puts `git commit`, `merge`, `push`,
`rebase`, `reset --hard` and `tag` under `ask`, so Claude Code asks before each one. Do not
work around this with other commands that have the same effect.

## Architecture

The design every change follows. Before writing code, look in **Shared code** for something
to reuse or extend. A change that would cross a **Boundary**, break a **Constraint**, go
against an accepted ADR, or bring in a way of doing things that **Style** or **Patterns** does
not list stops before any edit and is raised with the user, whoever asked for it.

- **Style:** a Claude Code plugin: declarative Markdown skills (the method), small shell
  hooks (enforcement), and a copy-in template installed by `install.sh`, whose files are
  either harness-owned (refreshed) or project-owned (copied once).
- **Modules:** `plugin/skills/` the method, one folder per skill; `plugin/hooks/` edit-time
  enforcement; `plugin/install.sh` and `plugin/template/` the per-repository files;
  `plugin/reference/` material skills read on demand (style catalogue, upgrades);
  `plugin/evals/` the eval suite and its fixture; `scripts/` this repository's own checks.
- **Boundaries:** the plugin stays generic: anything specific to one stack or project goes in
  the target's `CLAUDE.md` or `scripts/check` as a `FILL IN` placeholder, never in a skill or
  hook. Skills read project facts only from named `CLAUDE.md` sections. The installer never
  overwrites a project-owned file, and merges `.claude/settings.json` without removing
  anything. Hooks let the edit through (exit 0) when they cannot decide.
- **Shared code:** `plugin/hooks/lib.sh` for the hooks (reading the tool call);
  `plugin/reference/` for text several skills need;
  `plugin/skills/multi-session/templates/` for working-folder files (`spec` uses `spec.md`);
  `generate-records-index.mjs` exports the front-matter reader `lint-docs.mjs` uses;
  `plugin/evals/_fixture/` builds and installs eval repositories, and
  `plugin/evals/_graders/` holds the source copy of graders several cases share.
- **Patterns:** hooks get the edited path with `tool_file_path` from `lib.sh`, and block with
  exit 2 and a message on stderr. Per-repository hook settings live in `.claude/yotamake/*.conf`.
  Skills name the `CLAUDE.md` sections they read in bold and say what to do when one is
  missing or unfilled. A change to a project-owned template file gets an `upgrades.md` entry.
- **Constraints:** needs only `bash`, `git` and Node 18+; no npm dependencies. Runs on Linux
  and macOS (BSD `sed`: use `sed -i.bak`, not `sed -i`). `claude plugin validate --strict`
  passes for the plugin and the marketplace.
- **Decisions:** accepted ADRs in [docs/decisions/](./docs/decisions/README.md) are part of
  the design. A change that needs a different one gets a new ADR first.
