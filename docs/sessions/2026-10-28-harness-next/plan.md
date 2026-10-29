# Plan

9 sessions after S0. Clear context between them (marked ✂). Each session fits one context.
Order: enforcement first (video-vault relies on it), then CI so later sessions are checked,
then the installer fixes video-vault needs, then video-vault, then skill and small changes,
then evals last so they measure the final skills, then the docs design.

Yotamake sessions are commits on `ccr-d55bc34c-zz3j4j` (D0). Every session that changes the
plugin bumps `version` in `plugin/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

Status values: `todo`, `in progress`, `done`, `skipped`.

---

## S0 — Analysis and planning — `done`

---

## S1 — Enforcement: main-branch hook, permission precedence (F1, F2) — `done`

Ask D1 first.

1. Verify F1 and F2 still hold (read `plugin/hooks/hooks.json`, the template settings).
2. Test precedence: in a scratch repo, settings with `allow: Bash(git commit:*)` and
   `ask: Bash(git commit:*)`; run `claude -p` asking for a commit. Record the result in
   `log.md`. Act on it per D1.
3. Add a PreToolUse hook that blocks Edit/Write/MultiEdit/NotebookEdit when the repo is on its
   main branch. Read the main branch name from CLAUDE.md if possible, else `main`/`master`.
   Allow files outside the repo (scratchpad, `/tmp`). Allow an override for repos that work
   on main (a line in `.claude/yotamake/`).
4. Test with fake tool calls, then pilot `01-branches-first` once (asks about cost first).
5. Validate, install test, bump version, propose commit.

User involvement: approve the commit.

✂ **Clear context.**

## S2 — CI for this repository (F3) — `done`

1. Add `.github/workflows/ci.yml`: both `claude plugin validate --strict` commands (installs
   the Claude Code CLI), the scratch-repo install test, and `bash -n` on every script.
2. Check the CLI can run in CI without a login for `validate`. If not, drop that step and say so.
3. Propose commit.

User involvement: approve the commit; watch the first CI run.

✂ **Clear context.**

## S3 — Installer: opt-out, hook tools, fast/full checks (F5, F7, F8) — `done`

Ask D2 first.

1. Opt-out for managed files per D2.
2. Detect `.pre-commit-config.yaml` (and lefthook config) before setting `core.hooksPath`; if
   found, do not set it, and print how to call `.githooks/pre-commit` from that tool.
3. `scripts/check`: split checks into fast (pre-commit) and full (`--all`, CI, before a
   proposed commit). Update the pre-commit hook, the CLAUDE.md template and `simple-session`
   step 4.
4. Install test for each case: plain repo, repo with an opt-out, repo with
   `.pre-commit-config.yaml`.
5. Bump version, propose commit.

✂ **Clear context.**

## S4 — Video-vault, part 1: install and facts (F8, F9, F12, F13) — `done`

Ask D3, D4, D5 first. Needs push access to video-vault (F13).

1. Branch `chore/yotamake-harness` in video-vault from up-to-date `main`.
2. Add the opt-out from S3 for the two docs scripts. Run the installer.
3. Fill `scripts/check` from F12. Run `scripts/check --all`; record timing.
4. Rename the CLAUDE.md headings per D3; fix links to the old anchors (grep for them).
5. Run video-vault's own `pnpm run lint:docs`. Propose commit; ask before pushing.

User involvement: approve commit and push; settings changes are theirs to accept.

✂ **Clear context.**

## S5 — Video-vault, part 2: remove the old copies (F10, F11) — `done`

Ask D6 first.

1. Move the facts from `create-migration` and `deploy-check` into the Migrations and
   Deploying sections, and the deploy command into `permissions.ask`.
2. Delete the local skills and `.claude/hooks/`; remove the hook entries from
   `.claude/settings.json`.
3. Check the plugin's skills resolve the renamed sections (read each skill against the file).
4. Record in video-vault's `docs/records/` (use `yotamake:write-doc`).
5. Checks, propose commit; ask before pushing.

✂ **Clear context.**

## S6 — Skills: pull-request mode, cloud-friendly multi-session, review step (F14, F15, F16) — `done`

Ask D10 first.

1. `simple-session` step 6: a full PR path (push, open PR, report link), chosen from CLAUDE.md.
2. `multi-session`: support a committed folder and an assigned branch, as this effort did.
3. Review step before "stop and report", per D10.
4. Bump version, propose commit.

✂ **Clear context.**

## S7 — Small fixes and lite mode (F4, F6, F17) — `done`

Ask D7 first.

1. Replace `python3` with `node` in the hooks, installer and fixture (F6). Re-run the hook
   tests and the install tests.
1a. Installer: no `allow` rules for opted-out scripts (F21); no "Next steps" line for a
   skipped file (F22).
2. Lite mode per D7.
3. Icon: ask the user for a PNG, or skip.
4. Bump version, propose commit.

✂ **Clear context.**

## S8 — Evals (F18, F19) — `done`

Ask D8 first.

1. Fix the trigger gap (F18). Measure with `02-small-change`, 3 runs.
2. New cases: multi-session start, multi-session resume, `release-check` refuses without a
   Deploying section, `new-migration` naming, `setup` on a bare repo.
3. Pilot each once, calibrate, then the full suite with the baseline arm. Record scores in
   `log.md`.
4. Propose commit.

✂ **Clear context.**

## S9 — Stale-docs check: design, then close-out (F20) — `done`

Ask D9 first.

1. Write the design (how `owns:` maps to code paths, what the check reports, false-positive
   rate on video-vault's docs).
2. Close-out: move anything worth keeping into `README.md` and the plugin; mark sessions done;
   write the close-out log entry; ask before deleting this folder.
