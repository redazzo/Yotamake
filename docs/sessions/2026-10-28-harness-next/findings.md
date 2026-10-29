# Findings

Source of truth for why each task exists. Verify a cited line before editing it; code moves.
Paths starting `vv:` are in an application project (at `7e7c1e3`); the rest are in Yotamake (at
`931b499`).

## Enforcement

**F1 — Nothing stops edits on the main branch (high).** The "never edit on main" rule exists
only in `plugin/skills/simple-session/SKILL.md` (step 2). The plugin's hooks
(`plugin/hooks/hooks.json:5`, `:16`) protect secret files and lint, nothing else. The evals
show the skill does not always fire: in `02-small-change` it was skipped in 1 of 3 runs. When
it is skipped, nothing enforces the rule.

**F2 — Unknown whether `ask` beats a broad `allow` (high, unverified).** The template puts
`git commit` and friends under `permissions.ask`
(`plugin/template/.claude/settings.json`). Video-vault's local settings allow
`Bash(git:*)` and `Bash(git commit:*)` explicitly (`vv:.claude/settings.local.json:4`, `:7`).
If `allow` wins, the stop points are silently off in exactly that repo. My belief is that
`ask` wins, but I have not tested it.

## This repository

**F3 — No CI for Yotamake (medium).** There is no `.github/`. Manifest validation and the
install test run only when someone remembers (`CLAUDE.md`, "Before committing").

**F4 — Plugin has no icon (low).** `claude plugin validate plugin` warns `ICON_MISSING`.
Cosmetic; needs a 512–2048 px square PNG.

## Installer and template

**F5 — Installer can silently disable another hook tool (medium).** `plugin/install.sh:94-97`
sets `core.hooksPath` to `.githooks` whenever it is unset. The pre-commit framework installs
into `.git/hooks/pre-commit`, which git stops reading once `core.hooksPath` is set, so its
hooks would stop running without any message. (Husky sets `core.hooksPath` itself, so it hits
the "already set" branch at `:98-99` and is fine.) Lefthook not checked.

**F6 — `python3` dependency (low).** Used only to read JSON:
`plugin/hooks/pre-edit-protect.sh:12`, `plugin/hooks/post-edit-check.sh:10`,
`plugin/install.sh:57`, `plugin/evals/_fixture/setup.sh:17`, `:29`. `node` is already
required for the docs scripts.

**F7 — Pre-commit runs every "Always" check (medium).** `plugin/template/.githooks/pre-commit:4`
runs `scripts/check --staged`, but `--staged` (`plugin/template/scripts/check:23`) only
narrows the "when the diff touches" checks. The full test suite runs on every commit. Fine for
video-vault (its whole pre-flight is about 12 s, per its CLAUDE.md §2) but slow for large
suites. Needs a fast/full split.

**F8 — Harness-owned docs scripts collide with a repo's own (high for video-vault).**
`install.sh` always installs `scripts/docs/lint-docs.mjs` and
`scripts/docs/generate-records-index.mjs` (`managed`, `install.sh:32`). Video-vault already
has `scripts/lint-docs.js` and `scripts/generate-records-index.js` (`vv:package.json:19`,
`:28`), and its generated index names the old script in its header
(`vv:docs/records/README.md:1`). The harness's `--check` compares the whole rendered file, so
it would report the index as stale, and the repo would have two linters. The installer has no
way to skip a managed file.

## Moving video-vault onto the plugin

**F9 — Video-vault's CLAUDE.md headings are not the ones the skills read (high).** The skills
look up sections by name: Checks, Branching and releases, Migrations, Deploying, Conventions.
Video-vault has "Database Migrations" (`vv:CLAUDE.md:76`), "Branching Model" (`:145`),
"Deploying to Production" (`:158`) and "6. Codebase & Conventions" (`:439`), and no Checks
section. The skills would report the sections as missing.

**F10 — Video-vault's own hooks probably never fired (medium).** Both read the file path from
a `CLAUDE_TOOL_INPUT` environment variable (`vv:.claude/hooks/post-edit-lint.sh:2`,
`vv:.claude/hooks/pre-edit-block-env.sh:2`). As far as I know, hook input arrives as JSON on
stdin, so `fp` is always empty and both exit 0. The plugin's hooks replace them.

**F11 — Duplicate skills after the move (medium).** Video-vault keeps local copies of
`simple-session`, `multi-session`, `drawio`, `create-migration` and `deploy-check` in
`vv:.claude/skills/`. With the plugin installed, both `simple-session` and
`yotamake:simple-session` would be offered, which risks the wrong one firing. The project
facts in `create-migration` and `deploy-check` belong in CLAUDE.md's Migrations and Deploying
sections.

**F12 — Video-vault's gate already exists, in the deploy pre-flight (info).**
`vv:deploy/config/production.json:7-13` runs type-check, lint, unused (`knip`), tests and
`lint:db`. Its CLAUDE.md adds `cd proxy && npm test` when `proxy/` changes and
`pnpm run lint:docs` for docs. That is the content of its `scripts/check`.

**F13 — No push access to video-vault yet (info).** This session attached
the application's repository read-only. Pushing a branch there needs push access.

## Skills

**F14 — Pull-request mode is one sentence (medium).** `simple-session` defaults to a local
`git merge --no-ff` (`plugin/skills/simple-session/SKILL.md:114`); PR mode is a single line
(`:117`). Teams and cloud sessions mostly work through PRs.

**F15 — `multi-session` assumes a local machine (medium).** It keeps its folder in git-ignored
`.scratchpad/` and wants one branch per session. In an ephemeral cloud container with an
assigned branch neither works. This effort had to adapt both (see `README.md`).

**F16 — No review step (low).** Nothing reviews the diff before "stop and report". The
built-in `/code-review` could.

**F17 — No lite mode (low).** Small repos get the full docs system (ADRs, records, backlog)
whether they want it or not.

## Evals

**F18 — Trigger gap when the user names a branch (medium).** In `02-small-change`, Claude
skipped `simple-session` in 1 of 3 runs and did a lighter version of the steps itself.

**F19 — Eval coverage gaps (medium).** No cases for `multi-session` (start or resume),
`release-check`, `new-migration` or `setup`. The full suite with the baseline arm was last run
before the trigger, size-check and fixture fixes. All runs used one model.

## Docs

**F20 — Stale reference docs go unnoticed (low; idea).** The linter checks links, not truth.
`owns:` front-matter (`plugin/template/docs/backlog.md:5`) holds subject names, not code
paths, so nothing can tell when the code a doc describes has changed since its `updated:`
date.

## Found in S4

**F21 — The installer allows scripts it did not install (low).** With both `scripts/docs/*.mjs`
in `.claude/yotamake/skip`, `install.sh` still merges `Bash(node scripts/docs/lint-docs.mjs:*)`
and `Bash(node scripts/docs/generate-records-index.mjs:*)` into `permissions.allow`
(the merge loop in `plugin/install.sh` ignores the skip list). Harmless, but a re-run adds them
back if removed. Fix in S7: skip an allow rule whose script path is opted out.

**F22 — "Next steps" names a skipped file (low).** The installer's closing text always says to
edit `.github/workflows/check.yml`, even when the skip file lists it. Fix in S7.
