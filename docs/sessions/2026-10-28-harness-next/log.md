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
