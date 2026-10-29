# Log

## 2026-10-28 — S0: analysis and planning

- Analysed Yotamake at `931b499` and video-vault at `7e7c1e3` against the improvement list
  from the review. Findings F1–F20 are in `findings.md`.
- Surprises that changed the plan:
  - Video-vault already has its own docs scripts, and its records index names them in its
    header, so installing the harness's copies would fail the docs check (F8). The installer
    needs an opt-out before video-vault can move (now S3, before S4).
  - Video-vault's CLAUDE.md has none of the section names the skills read (F9).
  - Video-vault explicitly allows `git commit` in its local settings, so the `ask` vs
    `allow` question (F2) decides whether its stop points work at all.
- Wrote `plan.md` (S1–S9) and `decisions.md` (D1–D10; D0 answered).
- Adapted the skill for a cloud session (folder committed, sessions as commits on the
  assigned branch). That gap is itself F15, fixed in S6.
- Next: S1.

## 2026-10-28 — S1: main-branch hook, permission precedence

- D1 answered (warn and list). Eval pilot approved.
- F1 and F2 still held at the start (`hooks.json` had only the protect and lint hooks).
- **Precedence test (F2), `claude -p`, Claude Code 2.1.312, scratch repo:**
  - control, `allow: Bash(git commit:*), Bash(git:*)` only → commit ran;
  - same `allow` plus `ask: Bash(git commit:*)` in the same file → blocked;
  - `ask` in `.claude/settings.json`, `allow` from `--settings` (a higher-priority source)
    → blocked.
  So `ask` wins, and D1's warning is not needed. Not tested directly: an `allow` in a
  *trusted* `settings.local.json`. A project that has not been trusted ignores its `allow`
  entries entirely, so I used `--settings` as the higher-priority source instead.
- Added `plugin/hooks/pre-edit-main-branch.sh` (PreToolUse, Edit/Write/MultiEdit/NotebookEdit).
  Main branch from CLAUDE.md's `**Main branch:**` line, else `main`/`master`. Allows: files
  outside a git repo, a repo with no commits, detached HEAD, and repos with
  `.claude/yotamake/allow-edits-on-main`. That file is now in both protected-paths lists, so
  Claude cannot create it with Edit/Write (it still could with Bash; hooks do not cover that).
  Uses `python3` like the other hooks; S7 swaps them all to `node`.
- 12 fake tool calls passed (main, master, CLAUDE.md name, new file in a new dir, notebook,
  outside repo, unborn, feature branch, detached, opt-out, bad JSON).
- `setup` skill now cuts `chore/yotamake-harness` first on a repo with commits, since the hook
  would block it filling in facts on main. Template CLAUDE.md notes the hook reads its line.
- README and plugin README updated. Version 0.2.0 → 0.3.0.
- Checks: both `validate --strict` pass (icon warning only, F4). The install test fails `docs`
  on a bare scratch repo because the template CLAUDE.md links `./README.md`; that happens
  before this change too. With a README added it passes. Worth fixing in S3 (installer) or
  noting in the install-test instructions.
- Eval `01-branches-first`, 1 run: score 1.00, $0.07 (all three graders pass).
- Commit: `ce9695b`, pushed.
- Next: S2 (CI). S2's install test needs a README in the scratch repo (see above).

## 2026-10-28 — S2: CI for this repository

- Wrote the workflow (now parked as `ci.yml` in this folder): `bash -n` on the 13 shell scripts, `node --check` on the
  two `.mjs` scripts, both `validate --strict` commands, and the scratch-repo install test
  (with a README, per the S1 note).
- `claude plugin validate` needs no login: it passed with an empty `HOME` and no auth
  variables. So the step stays.
- The CLI is pinned to `@anthropic-ai/claude-code@2.1.312` (the version S1 tested) so a new
  release cannot turn CI red by itself.
- **Push blocked:** the GitHub App lacks the `workflows` permission, so it cannot push anything
  under `.github/workflows/`. The file waits here for the user to add as
  `.github/workflows/ci.yml` by hand. When it lands, add to CLAUDE.md "Before committing":
  "CI (`.github/workflows/ci.yml`) runs these three, plus `bash -n` and `node --check` on every
  script. It pins the Claude Code CLI version; bump it on purpose." Then delete `ci.yml` here.
- All steps run locally: pass (`s2-checks.log`). The first real CI run is still to watch.
- No plugin change, so no version bump.
- Next: S3 (installer). Ask D2 first.

## 2026-10-28 — S3: installer opt-out, hook tools, fast/full checks

- D2 answered: skip file, as recommended.
- **Opt-out (F8).** `install.sh` reads `.claude/yotamake/skip`: one template path per line,
  `#` comments, leading `./` and spaces trimmed. A listed path is never written, managed or
  not, and the run lists it under "did not install". `setup` skill says when to use it.
- **Hook tools (F5).** With `core.hooksPath` unset, the installer now leaves it alone when it
  finds `.pre-commit-config.yaml`, a lefthook config (`lefthook.*` or `.lefthook.*`, yml/yaml/
  json/toml), or an existing `.git/hooks/pre-commit` (found via `git rev-parse --git-path`, so
  worktrees work). It prints the snippet that calls `.githooks/pre-commit` from that tool.
  Husky still hits the "already set" branch.
- **Fast/full (F7).** `scripts/check` template gains `full()` (false only under `--staged`);
  slow checks go behind it, so the pre-commit hook skips them. Plain `scripts/check` and
  `--all` run everything. Updated the template CLAUDE.md Checks section, `simple-session`
  step 4, `setup` step 2, README. Existing installs keep their own `scripts/check` (project-
  owned), so nothing changes for them until they add `full &&`.
- Side fix from the S1 note: the installer warns when there is no `README.md` and CLAUDE.md
  links to it, since the docs check fails until one exists.
- Install tests (scratchpad): plain repo, re-run, skip file, pre-commit config, `lefthook.yml`,
  `.lefthook.yaml`, existing `.git/hooks/pre-commit`, husky-style `core.hooksPath`, no README;
  `--staged` runs fast only, plain and `--all` run full; a real commit runs the hook. All as
  expected. First lefthook attempt used `ls a b`, which fails when either glob misses; fixed.
- Checks: both `validate --strict` pass, `bash -n` and `node --check` clean, install test
  passes (`s3-checks.log`).
- Version 0.3.0 → 0.4.0. Commit: `0018b5a`, pushed.
- For S4: video-vault's skip file needs both `scripts/docs/*.mjs` paths; its `scripts/check`
  then calls `pnpm run lint:docs`. Per D5 its checks all go in the fast block.

## 2026-10-28 — S4: video-vault, part 1 (install and facts)

- D3, D4, D5 answered: all as recommended. F9 re-checked first: headings still as found.
- Branch `chore/yotamake-harness` in video-vault from `main` at `7e7c1e3`. Push access was
  already attached; the push worked.
- `.claude/yotamake/skip`: both `scripts/docs/*.mjs`, `.github/workflows/check.yml` (no CI;
  also the GitHub App cannot push workflows, see S2) and the three `.gitkeep`s (folders full).
- `scripts/check`: type-check, lint, unused, tests, `lint:docs` in the fast block (D5).
  Deviation from D5: `lint:db` sits under `touches '^services/supabase/'`, since it exits 2
  without a database and would fail every commit when the local stack is down. Proxy
  type-check and tests under `touches '^proxy/'`. `post-edit-checks.conf`: per-package eslint
  for `.ts` and `.tsx`, matching the old local hook.
- CLAUDE.md: Checks section added; Migrations, Branching and releases (with `Main branch`,
  `Integration`, `Version bump` lines), Deploying, `6. Conventions`. Kept the numbers, so the
  many `CLAUDE.md §2`/`§6` mentions still hold. No links used the old anchors; two prose
  mentions in a 2026-08 record left alone (history).
- Timing in this container: `--all` 60 s cold, `--staged` 36–40 s warm (CLAUDE.md says ~12 s
  on the user's machine). Tests fail at import without `.env.development.local`; with dummy
  `VITE_*` values all 101 files pass (log: `s4-checks.log`). The commit ran the real hook with
  those dummy values: all PASS.
- `npm install` in `proxy/` rewrote `proxy/package-lock.json`; reverted, not committed.
- New: F21 (installer allows skipped scripts), F22 ("Next steps" names a skipped file); added
  to S7.
- No version bump (user: tooling only). Commit `7b25d6b`, pushed; not merged.
- User to do: `git config core.hooksPath .githooks` in their own clone.
- Next: S5. Ask D6 first.

## 2026-10-29 — S5: video-vault, part 2 (remove the old copies)

- D6 answered: delete all five, as recommended. Same branch as S4 (`chore/yotamake-harness`;
  `main` had not moved).
- Moved the facts from `create-migration` and `deploy-check` into video-vault's CLAUDE.md, in
  the template's bullet shape: Migrations (directory, pattern, local/remote apply) and
  Deploying (targets, releases from, command, dry run, not shipped, verify, Gotchas list). The
  old skill's flag list lacked `--content-worker`; took the flags from `scripts/deploy/deploy.js`.
  Added `Bash(node scripts/deploy/deploy.js:*)` and `Bash(pnpm run deploy:*)` to `permissions.ask`.
- Deleted `.claude/skills/` (incl. the local `simple-session` evals, which the plugin's
  `02`–`04` cases cover) and `.claude/hooks/`, and the `hooks` block in `.claude/settings.json`.
  Checked the plugin's `pre-edit-protect.sh` blocks `.env.local` and
  `packages/client/.env.development.local` (fake tool calls, exit 2).
- Side fixes: CLAUDE.md §6 and a `.gitignore` comment pointed at `.claude/skills/multi-session`.
- Checked every section and line the plugin skills and hooks read (Checks, Migrations,
  Branching and releases with Main branch/Integration/Version bump, Deploying → Gotchas,
  Conventions' side-fix policy, the Owns table): all present.
- Video-vault commit `7168290`, pushed; not merged. The first commit attempt was stopped by the pre-commit hook (tests fail at import without the `VITE_*` values in a fresh shell); it passed with them set.
- Record: `docs/records/2026/2026-10-28-yotamake-harness.md` (covers S4 and S5), index
  regenerated. `write-doc` was followed by reading the plugin file: the plugin is not loaded
  in this cloud session.
- Checks (`s5-checks.log`): all PASS except `db-grants` (no database in the container; this
  branch touches no migrations). Dummy `VITE_*` values passed as environment variables, not an
  `.env` file: Vite's `loadEnv` reads `process.env`.
- Surprise worth knowing for S8: the plugin skills are not available as `yotamake:*` in these
  cloud sessions, so any eval or pilot has to load the plugin explicitly.

## 2026-10-29 — S6: skills (pull-request mode, committed folder, review step)

- D10 answered: as recommended (code changes only, `/code-review` at low effort).
- `simple-session`: new step 5 **Review** (skipped for docs-only branches; fix real defects,
  re-run checks, list the rest; say so if `/code-review` is missing). Old 5–6 are now 6–7.
  Step 7 now has two paths from the `Integration` line: local merge (default) or pull request
  (push, stop if a PR is already open, else open one with the environment's GitHub tools or
  `gh pr create`, follow a PR template, never merge it). The report lists review results.
- `multi-session`: new section on the two setups. Local (default): git-ignored
  `.scratchpad/`, one branch per session. Committed: `.sessions/<date>-<slug>/` (outside
  `docs/`, so the docs linter's orphan rule does not fire), sessions as commits on an assigned
  branch, pushed after each session. Resume looks in both places and pulls first. Templates
  updated (`README.md` setup line, `plan.md` branch line).
- Side fix: the README template pointed at `.claude/skills/multi-session/SKILL.md`, a path
  from before the plugin; it now names the skill.
- README and template CLAUDE.md (Conventions) describe both. No section renamed, so the eval
  fixture is unchanged.
- This effort's own folder stays at `docs/sessions/` (no docs linter in this repo).
- Review step skipped for this branch (Markdown and manifest versions only).
- Checks (`s6-checks.log`): both `validate --strict` pass, install test passes.
- Version 0.4.0 → 0.5.0. Commit `29e1371`, pushed.
- Not measured: no eval run for these skill changes. S8 covers multi-session cases; the PR
  path has no case yet (candidate for S8).
- Next: S7. Ask D7 first.

## 2026-10-29 — S7: small fixes and lite mode

- D7 answered: `--lite` flag, as recommended. Icon (F4): skipped for now.
- **`python3` → `node` (F6).** The three hooks read the tool call with `node -e`; the
  installer's settings merge and the eval fixture's two edits are now Node. No `python3` is
  left in `plugin/`. README's Requirements updated. 16 fake tool calls through the three hooks
  (protect, main branch, post-edit; bad JSON, empty, `null`, `tool_input: null`, spaces in the
  path) all as expected.
- **F21.** The merge skips an `allow` rule that names an opted-out path the repo does not have.
  If the repo has its own file at that path, the rule is still added.
- **F22.** "Next steps" leaves out files the skip file lists (CLAUDE.md, `scripts/check`,
  `check.yml`, `post-edit-checks.conf`) and numbers what is left.
- **Lite mode (F17).** `install.sh <repo> [--force] [--lite]`, flags in any order. `--lite`
  appends every template path under `docs/` and `scripts/docs/` to `.claude/yotamake/skip`
  (with a comment, only paths not already listed), so plain re-runs keep it lite. New
  `yotamake:docs begin/end` markers in the template CLAUDE.md (Docs line, "One owner per
  subject") and `scripts/check` (the docs check): `--lite` drops the block, a full install
  drops only the marker lines. A lite `scripts/check --all` has no checks until filled in, and
  prints nothing. `setup`, `simple-session`, `multi-session` and `write-doc` now say what to do
  when there is no `docs/README.md`.
- **Surprise: the eval fixture has been broken since S3.** Its `sed` looked for the old
  `# run tests` line, which S3 changed to `# full && run tests`, so `setup.sh` exited 1 before
  filling in `docs/README.md`. No eval has run since S1, so no recorded score is affected.
  Fixed; the fixture builds and passes `docs` and `tests`. Added it, and a lite install, to the
  parked `ci.yml` so this is caught next time.
- Side fix: the Architecture placeholder in the template CLAUDE.md no longer names
  `docs/reference/`.
- Install tests (scratchpad): plain, re-run, lite, lite re-run with and without the flag, skip
  file without a trailing newline plus `--lite`, `./`-prefixed entry with a comment, skipped
  script present vs absent, skipped CLAUDE.md/check/conf, flag order, bad flag, existing
  settings kept (`deny` still wins), no README, real commit through the hook. All as expected.
- Review step: `/code-review` at low effort, no findings.
- Checks (`s7-checks.log`): `bash -n`, `node --check`, both `validate --strict` (icon warning
  only), install test, lite install test, eval fixture — all pass.
- Version 0.5.0 → 0.6.0. Commit `ff09ade`, pushed.
- Not measured: no eval run. S8 runs the suite against these skills.
- Next: S8 (evals). Ask D8 first.

## 2026-10-29 — S8: evals

- D8 answered: about $8, as recommended. Spent about $7.97: 02-small-change ×3 ($0.43),
  pilots ($0.57), full suite with the baseline arm ($6.97, a little over its $6.50 cap
  because runs already in flight finish).
- **F18 (trigger gap).** The `simple-session` description now says the skill works on "a new
  branch cut from the main branch, or the one the user or environment names", and applies
  "also when the user already names the branch". Result: fired 3/3 alone, then 2/3 in the
  full suite, so 5/6 against 2/3 before. Too few runs to call it fixed. Still open.
- **Bug found while writing case 07: the main-branch hook blocked `.scratchpad/`.** The local
  multi-session setup makes its git-ignored folder while on main, and the S1 hook refused the
  write. The hook now allows git-ignored files (`git check-ignore`, which skips tracked
  files, so a tracked file matching an ignore pattern is still blocked). Fake tool calls:
  `.scratchpad/` on main allowed, `src/` on main blocked, `.env` on main blocked (both
  hooks), `src/` on a branch allowed. README updated.
- **New cases (F19):** 07-multi-session-start, 08-multi-session-resume,
  09-release-check-no-section, 10-new-migration, 11-setup-fill-in. Every scaffold builds
  locally.
- **Surprise: the eval sandbox keeps `.claude/` read-only,** so `install.sh` cannot run inside
  a case. The first pilot of a bare-repo setup case scored 0: the agent stopped and explained
  why, correctly. Reshaped to 11-setup-fill-in: the scaffold runs the installer and the case
  grades step 2 (filling in the facts). Setup's step 1 (the install itself) has no eval.
- Calibration: 11's `no-commit` needed `min: 0`. 08's `read-plan` (tool_used Read) failed in
  one run whose outcome graders all passed, so it was grading method, not outcome; removed.
  Traces were not kept, so that cause is a likely guess (it read the plan another way).
- Full suite, with the plugin vs without (3 runs each):

  | Case | With | Without | Δ |
  |---|---|---|---|
  | 01-branches-first | 1.00 | 0.00 | +1.00 |
  | 02-small-change | 0.95 | 0.86 | +0.10 |
  | 03-too-big | 1.00 | 0.11 | +0.89 |
  | 04-docs-only | 1.00 | 0.80 | +0.20 |
  | 05-work-record | 1.00 | 0.93 | +0.07 |
  | 06-question | 1.00 | 1.00 | 0.00 |
  | 07-multi-session-start | 1.00 | 0.33 | +0.67 |
  | 08-multi-session-resume | 0.92 | 0.75 | +0.17 |
  | 09-release-check-no-section | 1.00 | 0.67 | +0.33 |
  | 10-new-migration | 1.00 | 1.00 | 0.00 |
  | 11-setup-fill-in | 1.00 | — | — |

  Mean Δ +0.34. 11's baseline has no score: the cost cap skipped its paid graders. 10 shows no
  gain: without the plugin the model also followed the Migrations section, so that case
  measures little. The one 02 miss in the with arm was `proposes-commit-message`. One model
  only (the runner's default).
- Checks (`s8-checks.log`): `bash -n`, `node --check`, both `validate --strict`, install
  test, lite install test, eval fixture — all pass.
- Review step: the only code change is three lines in the hook; reviewed by hand (above), no
  findings. `/code-review` not run.
- Version 0.6.0 → 0.7.0.
- Not done: no PR-path case (noted in S6). F18 stays open.
- Next: S9. Ask D9 first.
