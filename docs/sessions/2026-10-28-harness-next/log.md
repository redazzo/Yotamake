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
- Next: S2 (CI). S2's install test needs a README in the scratch repo (see above).
