# Plan

2 sessions. Clear context between them (marked ✂). Each session is one set of commits on the
assigned branch `ccr-41e6ce46-6hq1pm`, pushed at the end. Order: prove the design first (S1
can stop the effort), then build it all in one session, docs last within it so they describe
the final state. (Planned as five sessions; the user chose two on 2026-11-15.)

Status values: `todo`, `in progress`, `done`, `skipped`.

## Design

- **Style:** a harness-owned script in `.claude/yotamake/`, run by a project hook in the
  template's `.claude/settings.json`, as ADR-0004 does for `SessionStart`; works without the
  plugin. New: the first project `PreToolUse` hook, and the first hook that asks when it
  cannot decide (ADR-0006 item 2).
- **Modules touched:** `plugin/template/.claude/yotamake/commit-gate.sh` (new),
  `plugin/template/.claude/settings.json`, `plugin/install.sh` (managed list, skip rule),
  `plugin/skills/multi-session/SKILL.md` (opt-in marker), `plugin/reference/upgrades.md`,
  `scripts/test-hooks.sh`, `scripts/test-install.sh`, this repo's `.claude/` copies, docs
  (ADR-0006 amendment and status, ADR-0005/0007 amendments, CLAUDE.md, template CLAUDE.md,
  README, site, backlog, a record).
- **Reused:** the quote-aware parser in `plugin/hooks/pre-bash-git.sh` (copied and inverted,
  F7); `hook_field`, `hook_root`, `gate_file` and the main-branch read from `lib.sh` (copied:
  template scripts cannot source plugin files, F8–F9); the test setups in `test-hooks.sh`
  (`bash_call`, the worktree block, `session_start_basics`) and `test-install.sh`
  (`session_start_count`).
- **New:** `commit-gate.sh` (nothing project-side decides permissions today); a
  `permissionDecision` helper in `test-hooks.sh` (`expect` reads exit codes only, F10).
- **Boundaries and constraints at risk:**
  - Boundaries, "Hooks let the edit through (exit 0) when they cannot decide": this hook
    asks instead. ADR-0006 names it as the one exception; `CLAUDE.md` Boundaries says so in S2.
  - ADR-0003 (stop points by `ask` rules): ADR-0006 amends it for `git commit` only; nothing
    else leaves `ask`.
  - ADR-0004's fail-open wrapper must not be copied (F11).
  - Installer "never removes" stays true: the `ask` rule leaves old installs by hand (F13).
  - Constraints: bash, git, Node 18+; BSD `sed -i.bak`.

---

## S1 — Acceptance tests (F1–F6, F16) — `in progress`

Branch: the assigned branch.
Needs: none

Ask D1, D2 first.

1. Check the Claude Code version, and that `onFailure` exists (D4).
2. In throwaway repos (scratchpad), with a stub hook that prints a fixed decision, test each
   item under ADR-0006 "Before acceptance" that `claude -p` can show: hook "ask" under
   `Bash(git:*)` in project and user settings; hook "allow" vs `deny` and vs `ask`; the
   wrapper cases (missing, exit 1, empty, timeout with and without `onFailure`); hooks off
   (`disableAllHooks`); untrusted folder; Bash write into `.git/` (F16).
3. Write the script for the interactive cases the user runs locally (D1), and record their
   results when they come.
4. Write the results into ADR-0006 as an amendment (dated, Claude Code version). Decide with
   the user, by D2: go on (status stays Proposed until S2) or stop (mark Rejected, close the
   backlog item, skip S2).
5. Add this session's rows to `docs.md`; `scripts/check`; report; commit and push on yes.

User involvement: answer D1/D2; run the local script; the go/stop call.

✂ **Clear context.**

## S2 — Build, wire in, opt-in, docs and release (F2, F7–F17; A1–A8) — `todo`

Branch: the assigned branch.
Needs: S1 (go)

Ask D3–D6 first. One context; if it runs short, stop after a step, commit, and log where.

1. **Script.** Verify F7–F10 still hold. Write
   `plugin/template/.claude/yotamake/commit-gate.sh` (mode 100755): reads hook input;
   pre-filters on `commit` (none → no output); parses each simple command; prints "allow"
   only when every git call is a plain `git [-C x] commit` whose directory is a linked
   worktree, not on the main branch, with the marker set (D6, read only); prints "ask" for
   everything else that mentions `commit`, including any command naming the marker.
2. **Hook tests.** A `test-hooks.sh` section with a decision helper: one case per form in
   A1–A3, in the existing worktree setup, marker set and not set; wrapper basics (A4) from
   the template's command.
3. **Wiring.** Template `settings.json`: a `PreToolUse` `Bash` hook whose command prints an
   "ask" decision itself when the script is missing, exits non-zero, or prints nothing for
   input that mentions `commit`; `onFailure` per D4; remove `Bash(git commit:*)` from `ask`.
   `install.sh`: the script in `managed` and the header; the skip rule per D5.
   `test-install.sh`: hook present once with matcher `Bash`, executable, old `ask` rule kept
   on re-install, skip behaviour.
4. **Upgrade.** `upgrades.md` entry (Check: a `PreToolUse` hook names `commit-gate.sh` and
   `ask` has no `Bash(git commit:*)`; Apply: re-run the installer, then remove the rule by
   hand after confirming with the user). Also covers the template `CLAUDE.md` edit.
5. **Opt-in.** `multi-session` SKILL.md, "Running sessions in parallel": write the marker in
   the worktree's git dir by a command that prompts (per S1); drop "Claude Code still
   prompts for each commit"; the marker goes with `git worktree remove`; "Rules for every
   session" and "Autopilot" to match.
6. **This repo.** `./plugin/install.sh .`, then remove `Bash(git commit:*)` from this repo's
   `.claude/settings.json` by hand (ask first: it changes this conversation's own stop).
7. **Docs.** ADR-0006 to Accepted; amendments to ADR-0005 (rule 6) and ADR-0007 (:58);
   `docs/decisions/README.md`; `CLAUDE.md` (stop points, Style, Boundaries exception) and
   `plugin/template/CLAUDE.md`; `simple-session` :261; README and site per F17; backlog item
   closed.
8. **Close-out.** From `docs.md`: record in `docs/records/` and its index; backlog follow-ups.
9. `scripts/check`, review; report with the eval cases `scripts/check` names (ask before
   running them). On yes: commit, delete this folder (`git rm -r`), then
   `chore(release): bump version to 0.34.0` with `./plugin/install.sh .`; push.

User involvement: answer D3–D6; approve the stop-rule edit in step 6 and the release.
