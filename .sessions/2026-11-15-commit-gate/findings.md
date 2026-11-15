# Findings

Source of truth for why each task exists. Verify a cited line before editing it; code moves.
Read on 2026-11-15 at 0.33.0 by three read-only agents; Claude Code facts from its docs
(hooks, permissions, permission-modes pages), read the same day, untested here.

## Claude Code behaviour (docs, untested)

**F1 — A hook "allow" cannot pass an `ask` or `deny` rule (high).** Hooks page: "Deny and ask
rules are still evaluated regardless of what the hook returns." So the `Bash(git commit:*)`
rule must go for the gate to have any effect, as the ADR says.

**F2 — A failed hook lets the call through by default (high).** Exit codes other than 0 and 2
are non-blocking; a missing script, invalid JSON and a timeout (default 600 s for `command`)
all let the call go on through the normal permission flow. Exit 2, or `onFailure: "block"` on
the hook, are the documented ways to fail closed. The ADR's wrapper (print "ask" itself)
covers a missing or crashing script, but not a timeout: that needs `onFailure: "block"`.

**F3 — What a hook "ask" does is not documented for every mode (high).** Documented: `auto`
sends it to the prompt. Not documented: a broad `allow` rule plus a hook "ask"; `-p`;
`acceptEdits`; `bypassPermissions`; `dontAsk` (likely denies). These are the ADR's "Before
acceptance" tests.

**F4 — Project hooks run before trust; `disableAllHooks` turns them off (medium).** Project
settings hooks run in an untrusted folder and under `-p`; project `allow` rules do not. A
`disableAllHooks: true` in user settings is overridden by `false` in project settings; at
managed level it wins. `allowManagedHooksOnly` blocks project hooks. With hooks off, the gate
does nothing and, with the `ask` rule gone, nothing asks.

**F5 — `.git/` and `.claude/` are protected paths (medium).** Writes there are prompted in
`default` and `acceptEdits`, denied in `dontAsk`, allowed in `bypassPermissions`; allow rules
do not pre-approve them. Not documented: whether this covers a Bash `touch` into `.git/`.

**F6 — `CLAUDE_PROJECT_DIR` stays at the main checkout after `EnterWorktree`; the hook's
`cwd` follows the worktree (low).** The hook command should still run the script by
`$CLAUDE_PROJECT_DIR`, and the script should judge each `git` call's own directory.

## Hooks and the parser

**F7 — `plugin/hooks/pre-bash-git.sh` has the parser to start from, but it fails open
(high).** Quote-aware Node parser (:25-50) splits on `; & | ( )` and newlines, skips `VAR=`,
`command`, `exec` (:57-58), follows `cd` (:59), reads `git -C`/`-c` (:62-65). An unclosed
quote exits with no output (:49), letting the command through. It misses `eval`, `bash -c`,
`sh -c`, `xargs`, `$(...)`, backticks, `env`, `sudo`, `time`, git aliases, `commit-tree`,
and scripts that commit. The gate must invert it: "allow" only when every git call is a plain
`git [-C x] commit` in an opted-in worktree; anything else that mentions `commit` asks.

**F8 — Template scripts are self-contained, bash + git + sed only (medium).**
`session-context.sh` and `set-hooks-path.sh` do not source `lib.sh`; `test-hooks.sh:204`
fails any that names `CLAUDE_PLUGIN_ROOT`. A Node parser is new for a template script (Node
18+ is an allowed Constraint). A missing `node` must end in "ask".

**F9 — Helpers to copy, not source, from `plugin/hooks/lib.sh` (low).** `hook_field` (:6-15),
`hook_root` (:42-47, the ADR-0005 cwd order), `gate_file` (:53-58, a file in the worktree's
own git dir), and the main-branch read (:69-86; a third copy after `session-context.sh:17-23`).
`guarded_main_branch`'s `allow-edits-on-main` opt-out (:71) must not let commits through.
No hook yet compares `--absolute-git-dir` with `--git-common-dir`; resolve both with `pwd -P`.

**F10 — `scripts/test-hooks.sh` checks exit codes only (medium).** `expect` (:13-23) ignores
stdout, so a new helper must read `permissionDecision`. `bash_call` (:74) builds Bash input;
the worktree block (:284-335) has a main repo `$m` and worktree `$w`; `session_start_basics`
(:195-205) runs the template's hook command, the model for fail-closed wrapper cases. The
unreadable-input loop (:338-341) expects exit 0 and must not include the gate.

## Settings and installer

**F11 — The existing project hook commands fail open by design (high).**
`plugin/template/.claude/settings.json:48,56`: `[ -f "$f" ] && bash "$f" ...; exit 0`
(ADR-0004). The gate's command must not copy that ending. Entry shape to copy:
`{ "matcher": "Bash", "hooks": [...] }`; keep the name matching `\.claude/yotamake/[\w.-]+\.sh`
for the installer's de-duplication.

**F12 — Skipping the script would leave no commit stop (high).** `install.sh:136,157` drops a
skipped script's hook entry. On a fresh install with no `ask` rule, skipping
`commit-gate.sh` leaves nothing that asks.

**F13 — The installer only adds settings (high).** `install.sh:146-153` never removes an `ask`
rule, so existing installs keep `Bash(git commit:*)` (safe, no benefit) until removed by hand.
The repository's own `.claude/settings.json:30` needs the same hand edit.

**F14 — Managed list and executable bit (low).** Add the script to `managed` (`install.sh:52-53`)
and its header comment (:11-12); the chmod glob (:175-176) already covers it; commit it 100755.
`consistency.mjs:335-343` needs the repo's copy to match the template (`./plugin/install.sh .`).
`consistency.mjs:350` does not force an `upgrades.md` entry for managed files or
`settings.json`: write it anyway.

## Opt-in

**F15 — Today the opt-in is only a row in `decisions.md` (medium).** `multi-session`
SKILL.md:181-184 and :135-136; ADR-0005 rule 6 (:66-69). Nothing records it where a hook can
read it.

**F16 — Claude could write the marker with Bash (high).** `pre-edit-protect.sh` watches only
Edit and Write (:31-34); README.md:219-221 already admits Bash gets past it. F5 may cover
`.git/` for file tools. The gate itself must ask on any Bash command naming the marker.

## Docs that say every commit prompts

**F17 — Text to update when the gate ships (medium).** `CLAUDE.md:135-136` (stop points),
`:146-151` (Style: project hooks are SessionStart only), `:164` (Boundaries);
`plugin/template/CLAUDE.md:138-139` (needs an `upgrades.md` entry);
`multi-session` SKILL.md:181-184, :203; `simple-session` SKILL.md:261;
README.md:44-52, :82, :127-133, :181-184, :200-205, :218-223;
`site/index.html:33,74,110`; `site/how-it-works.html:55,118-137`; `docs/backlog.md:77-86`;
ADR-0005 and ADR-0007:58 ("Every `git commit` … still prompts") need amendments pointing at
ADR-0006. Historical `upgrades.md:138` stays.
