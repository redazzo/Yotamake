# CLAUDE.md

<!--
  Yotamake harness template. Replace every "FILL IN" comment, then delete this comment.
  The yotamake plugin's skills read the sections below BY NAME:
    Checks, Branching and releases, Migrations, Deploying, Conventions, Architecture.
  Keep those headings. Delete Migrations or Deploying if the project has none;
  the skills then stop and ask instead of guessing.
-->

## How to work here

Every change to code, tests or docs runs as a session, however small: use the
`yotamake:simple-session` skill. If the change is too big for one session (`simple-session`,
"Check the size"), use `yotamake:multi-session` instead. This holds when the user names the
branch, spells out the exact edit, or says it is quick and not to ask: the skill covers working
on a named branch, and its design check, checks, review, doc update and stop before commit
still apply.
Questions and explanations need no session.

**If the plugin is not loaded** (no `yotamake:` skills are offered), its skills and hooks are
off. Follow these steps by hand:

1. Before an edit, cut a branch as **Branching and releases** says.
2. Follow **Architecture**, and update the doc that owns what you change.
3. Leave the files in `.claude/yotamake/protected-paths.conf` alone, if it exists.
4. Run `scripts/check` and fix what fails.
5. Stop and ask before commit, merge or push.

If `git config core.hooksPath` prints nothing, run `git config core.hooksPath .githooks`, so
the pre-commit hook runs. To get the skills: `claude plugin marketplace add redazzo/Yotamake`,
then `claude plugin install yotamake@yotamake`.

## Project overview

<!-- FILL IN: one paragraph. What the project is, the stack, the repo layout. -->

<!-- yotamake:docs begin -->
**Docs:** [docs/README.md](./docs/README.md) (index — start here; explains the four kinds of
doc and which doc owns what) · [README.md](./README.md) (setup) ·
[docs/decisions/](./docs/decisions/README.md) (ADRs — never edited, only superseded or amended) ·
[docs/records/](./docs/records/README.md) (history) · [docs/backlog.md](./docs/backlog.md)
(open work)
<!-- yotamake:docs end -->

## Commands

```bash
# FILL IN: install, dev server, build, test
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

## Branching and releases

- **Main branch:** `main`. Feature work happens on branches cut from it, never on it directly.
  A hook blocks edits while this branch is checked out. Hooks read the name from
  `main-branch` in `.claude/yotamake/project.conf`; change both together.
- **Branch prefixes:** `feat/`, `fix/`, `refactor/`, `perf/`, `docs/`, `test/`, `chore/`.
- **Commits:** Conventional Commits, `type(scope): summary`.
- **Integration:** <!-- FILL IN: "local `git merge --no-ff` into main" (default) or "push and open a pull request" -->
- **Docs-only:** a branch that changes only files under `docs/` and Markdown files at the
  repository root other than `CLAUDE.md`. <!-- Change the paths if the docs live elsewhere,
  or if some of these files are prompts or other Markdown that acts as code. Then change the
  `docs` lines in `.claude/yotamake/project.conf` to match: a hook reads them. -->
- **Session size:** about 400 changed lines or 15 files in one diff, not counting lockfiles
  and generated files. `simple-session` sizes a change against it. <!-- A judgment, not a
  measured number: raise or lower it to what the project's reviews can read with care. -->
- **Version bump:** <!-- FILL IN or delete: the command (e.g. `pnpm run version:patch`), the
  file it changes, and the rule (e.g. "code changes get a patch bump as its own commit,
  `chore(release): bump version to X.Y.Z`; docs-only branches do not"). -->
- **Worktree setup:** <!-- FILL IN or "none": what a new `git worktree add` tree needs before
  `scripts/check` passes (e.g. "copy `.env` from the main worktree, run `pnpm install`").
  Parallel sessions (`yotamake:multi-session`) run it. -->
- **Release branch / tags:** <!-- FILL IN or delete: e.g. "`production` records what is live; it is
  fast-forwarded from main after a deploy and never committed to". -->

## Migrations

<!-- FILL IN or delete this section. -->

- **Directory:** <!-- e.g. `db/migrations/` -->
- **Filename pattern:** `YYYYMMDD{NNNNNN}_{snake_case_description}.sql`
- **Apply locally:** <!-- e.g. `supabase migration up --local` -->
- **Apply remotely:** <!-- e.g. `supabase db push` --> — **reaches the remote database. Never use it
  for local testing.**

## Deploying

<!-- FILL IN or delete this section. Deploying is always the user's call.
  Also add the deploy command to "permissions.ask" in .claude/settings.json, e.g.
  "Bash(node scripts/deploy.js:*)", so Claude Code asks before every run. -->

- **Targets:** <!-- e.g. local, production -->
- **Releases come from:** <!-- branch, e.g. main -->
- **Command:** <!-- e.g. `node scripts/deploy.js production [--component]` -->
- **Dry run:** <!-- e.g. add `--dry-run` -->
- **Components and order:** <!-- what ships, in what order, and why the order matters -->
- **Not shipped by the command:** <!-- things deployed by hand -->
- **Verify after deploy:** <!-- e.g. a smoke script -->

**Gotchas:**

- <!-- FILL IN: one line each. Mistakes that have bitten before. -->

## Conventions

**Trivial side-fix policy.** When you notice a bug, typo or inconsistency that is *not* part
of the current task, and the fix is trivial and side-effect-free (a doc or comment fix, an
obvious typo, a stale constant with no behavioural reach), fix it without asking, and note it
in the change summary or commit message. Anything non-trivial or with side effects
(behaviour, API, schema or migration changes, refactors, anything that could break callers)
must be raised and confirmed first.

<!-- yotamake:docs begin -->
**One owner per subject.** Every subject has one doc that owns it (the "Owns" table in
`docs/README.md`). A change in behaviour updates that doc in the same branch. Other docs link
to it rather than restate it.
<!-- yotamake:docs end -->

**One-off operations are scripts, not endpoints.** A backfill, data migration or reindex with
no recurring caller is a script run locally, not a permanent endpoint. The test is "who calls
this next month?" An endpoint for a single use is permanent attack surface.

**Work that spans several contexts** runs as numbered sessions with a working folder that
survives `/clear`: git-ignored under `.scratchpad/`, or committed under `.sessions/` in an
ephemeral environment. See the `yotamake:multi-session` skill.

**Stop points are enforced.** `.claude/settings.json` puts `git commit`, `merge`, `push`,
`rebase`, `reset --hard` and `tag` under `ask`, so Claude Code asks before each one. Do not
work around this with other commands that have the same effect.

<!-- FILL IN: project conventions — naming, style, anything Architecture does not cover. -->

## Architecture

The design every change follows. Before writing code, look in **Shared code** for something
to reuse or extend. A change that would cross a **Boundary**, break a **Constraint**, go
against an accepted ADR, or bring in a way of doing things that **Style** or **Patterns** does
not list stops before any edit and is raised with the user, whoever asked for it.

<!-- FILL IN each line but Domain language. Keep the labels: the skills read them. Link
  to detailed docs rather than repeating them here. -->

- **Style:** <!-- FILL IN: the architecture style or styles, and where each applies, e.g.
  "modular monolith; hexagonal inside `core/`"; "layered: `api/` → `core/` → `db/`". -->
- **Modules:** <!-- FILL IN: the main parts and what each owns, e.g. "`api/` HTTP handlers;
  `core/` business rules; `db/` data access". -->
- **Boundaries:** <!-- FILL IN: rules a change must not break, e.g. "`core/` never imports
  `api/` or `db/`"; "only `db/` talks to the database". -->
- **Shared code:** <!-- FILL IN: where reusable code lives, e.g. "`lib/` helpers;
  `ui/components/` shared UI". -->
- **Patterns:** <!-- FILL IN: the one way the project does recurring things, e.g. errors,
  config, logging, validation, data access. -->
- **Constraints:** <!-- FILL IN: limits from outside the code that a change must stay within,
  e.g. "runs on Node 20 and later"; "the bundle stays under 200 KB"; "no GPL dependencies";
  "personal data stays in the EU". -->
- **Domain language:** none yet. <!-- Not a FILL IN: skills link the glossary here once a
  term is settled, or list terms here when there is no docs/ folder. -->
<!-- yotamake:docs begin -->
- **Decisions:** accepted ADRs in [docs/decisions/](./docs/decisions/README.md) are part of
  the design. A change that needs a different one gets a new ADR first.
<!-- yotamake:docs end -->
