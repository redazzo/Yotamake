# CLAUDE.md

<!--
  Yotamake harness template. Replace every "FILL IN" comment, then delete this comment.
  The yotamake plugin's skills read the sections below BY NAME:
    Checks, Branching and releases, Migrations, Deploying, Conventions.
  Keep those headings. Delete Migrations or Deploying if the project has none;
  the skills then stop and ask instead of guessing.
-->

## How to work here

Every change to code, tests or docs runs as a session, however small: use the
`yotamake:simple-session` skill. If the change will not fit one branch and one context, use
`yotamake:multi-session` instead. Questions and explanations need no session.

## Project overview

<!-- FILL IN: one paragraph. What the project is, the stack, the repo layout. -->

**Docs:** [docs/README.md](./docs/README.md) (index — start here; explains the four kinds of
doc and which doc owns what) · [README.md](./README.md) (setup) ·
[docs/decisions/](./docs/decisions/README.md) (ADRs — never edited, only superseded) ·
[docs/records/](./docs/records/README.md) (history) · [docs/backlog.md](./docs/backlog.md)
(open work)

## Commands

```bash
# FILL IN: install, dev server, build, test
```

## Checks

**`scripts/check` is the one gate.** Claude's skills, the pre-commit hook and CI all run it.
Add a check by editing that script, not by listing it here.

- `scripts/check` — checks for what changed since the main branch, plus uncommitted work.
- `scripts/check --staged` — what the pre-commit hook runs.
- `scripts/check --all` — what CI runs.

It prints one `PASS`/`FAIL` line per check. A person can skip the git hook once with
`git commit --no-verify`. Claude never does unless the user asks.

## Branching and releases

- **Main branch:** `main`. Feature work happens on branches cut from it, never on it directly.
- **Branch prefixes:** `feat/`, `fix/`, `refactor/`, `perf/`, `docs/`, `test/`, `chore/`.
- **Commits:** Conventional Commits, `type(scope): summary`.
- **Integration:** <!-- FILL IN: "local `git merge --no-ff` into main" (default) or "push and open a pull request" -->
- **Version bump:** <!-- FILL IN or delete: the command (e.g. `pnpm run version:patch`), the
  file it changes, and the rule (e.g. "code changes get a patch bump as its own commit,
  `chore(release): bump version to X.Y.Z`; docs-only branches do not"). -->
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

**One owner per subject.** Every subject has one doc that owns it (the "Owns" table in
`docs/README.md`). A change in behaviour updates that doc in the same branch. Other docs link
to it rather than restate it.

**One-off operations are scripts, not endpoints.** A backfill, data migration or reindex with
no recurring caller is a script run locally, not a permanent endpoint. The test is "who calls
this next month?" An endpoint for a single use is permanent attack surface.

**Work that spans several contexts** runs as numbered sessions with a git-ignored working
folder under `.scratchpad/`, so it survives `/clear`. See the `yotamake:multi-session` skill.

**Stop points are enforced.** `.claude/settings.json` puts `git commit`, `merge`, `push`,
`rebase`, `reset --hard` and `tag` under `ask`, so Claude Code asks before each one. Do not
work around this with other commands that have the same effect.

<!-- FILL IN: project conventions — boundaries that must not be crossed, naming, error handling. -->

## Architecture

<!-- FILL IN: the parts an agent must know to work safely. Link to docs/reference/ for detail
rather than repeating it here. -->
