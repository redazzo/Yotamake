---
kind: reference
status: current
updated: 2026-11-15
owns: [open-work-register]
---

# Backlog

**The** register of open engineering work: everything outstanding that is not already an ADR
or an in-flight branch.

**Format.** One `##` entry per item, each carrying **Added** and a **Trigger to act**: the
observable condition that should make someone pick it up. An item with no trigger is a wish,
not a backlog entry. Items with substantial written analysis keep a detail document in
`backlog/` and link to it from here. An entry may carry **Priority: High** or
**Priority: Medium**; High entries sit at the top, then Medium, then the rest.

**Done means gone.** Delete the entry when the work lands, and write a
[record](./records/README.md) if it was worth explaining.

---

## Eval sandbox denies `git`

**Priority: High** · **Added:** 2026-11-10 · **Trigger to act:** a new Claude Code release,
or a fix posted on [claude-code#108887](https://github.com/anthropics/claude-code/issues/108887).

The cause is a Claude Code bug (confirmed 2026-11-11, Claude Code 2.1.322, git 2.56.0,
Linux). An eval run puts git's credential helpers on the sandbox's deny list
(`sandbox.credentials.files`, `mode: deny`) after resolving symlinks. Here
`git-credential-store`, `git-credential-cache` and `git-credential-cache--daemon` in
`/usr/lib/git-core/` are links to `/usr/bin/git`, so the deny list holds git itself. The
agent's Bash then gets `/usr/bin/git: Permission denied`. Scaffold scripts run outside the
sandbox and are not affected. The issue is tagged macOS only; it affects Linux too.

So in every run where the agent calls git, `scripts/check` cannot pass, and the `Stop` hook
holds Claude at the stop. Claude then asks for git access instead of finishing the report.
Graders that need the check, the review skills, the proposed commit message, the commit
question or the report fail for that reason, not because of the harness. Saved results show
git denied in most runs from 2026-10-29 (2.1.312) on, including the runs that "Re-check
two fixes on the next full eval run" cites. Graders that need no git (cases 06, 07, 08) are
still valid.

To recheck on a new release: run `claude plugin eval . --case 06-question --runs 1
--ablation none --scaffold --trust-plugin --allow-tools Bash Write Edit --no-publish
--keep-temp` (about $0.10), then look for `/usr/bin/git` in the kept run's
`config/settings.json`. When it is gone, re-run the cases that need git and delete this
entry. Do not change the fixture or `scripts/check` to get around the sandbox.

## Show that the harness helps: Δ and cost against the baseline

**Priority: Medium** · **Added:** 2026-11-14 · **Trigger to act:** "Eval sandbox denies
`git`" is closed.

From a review of Yotamake against other harnesses (2026-11-14). No Δ (score with the plugin
minus score without) has been published, though `README.md`, Evals, calls it the headline
number. The pass rates on record are small samples ("3 of 3", "10 of 10") on one model and
one Claude Code version, and most code-change graders have failed since 2026-10-29 because of
the sandbox, not the harness. Run the full suite with `--ablation with-without`, at least 5
runs per case and on two models, and write a record with Δ and mean cost per case for both
arms. This is the first run for "Keep eval results over time" and "Re-check two fixes on the
next full eval run".

## Session overhead on small changes

**Priority: Medium** · **Added:** 2026-11-14 · **Trigger to act:** the Δ run above gives
cost per case, or a user reports that small fixes cost too much time or money.

From the same review. Any change that is not docs-only or trivial runs `scripts/check`,
`/simplify`, `/code-review` and a design-read agent, and stops to ask. Nobody has measured
what that costs over the baseline. First compare cost, turns and seconds for cases 02, 13 and
20 in both arms. If the overhead is large, consider a tier between trivial and full, for
example a small diff inside one module that skips `/simplify` and the design read. That
changes `simple-session`, "Review", and cases 02, 13, 15 and 20 cover it.

## Let a hook approve commits in opted-in worktrees

**Priority: Low** · **Added:** 2026-11-11 · **Trigger to act:** the commit prompt in
parallel worktree sessions is reported as too costly, even with the opt-in that skips the
stop-and-report exchange (ADR-0005, rule 6).

[ADR-0006](./decisions/0006-commit-stop-by-project-hook.md) (Proposed) has the design: drop
`Bash(git commit:*)` from the `ask` list and add a project `PreToolUse` hook that fails
closed, asking for every commit except on an opted-in worktree branch. When the trigger
fires, run the tests it lists under "Before acceptance" first, then build it.

## Spawn worktree sessions from the main conversation

**Priority: Low** · **Added:** 2026-11-11 · **Trigger to act:** users find opening one
Claude Code conversation per worktree too slow, or a subagent can stop and ask the user
before a commit.

[ADR-0005](./decisions/0005-parallel-sessions-in-worktrees.md) has the user open a
conversation in each worktree, so every session keeps its own stop before commit
(ADR-0003). [ADR-0007](./decisions/0007-autopilot-runs-sessions-in-subagents.md) now lets
the main conversation run sessions as subagents under autopilot, but one at a time on one
branch. What is left: the main conversation starts one `isolation: "worktree"` subagent per
parallel session. That would need a new ADR, or an amendment of ADR-0007, which rules out
parallel sessions under autopilot.

## Autopilot context growth

**Priority: Low** · **Added:** 2026-11-12 · **Trigger to act:** an autopilot run whose main
conversation compacts before the end.

Under autopilot the main conversation runs the review of every session, so each review's
findings and fixes land in its context (ADR-0007). A long effort may fill it. One option:
hand the review's fixes to a fix agent, and keep only its summary.

## Test the `Stop` gate after a subagent's edit

**Priority: Low** · **Added:** 2026-11-12 · **Trigger to act:** the next session where the
plugin's hooks run and a subagent edits code (an autopilot run, for example).

`stop-check-ran.sh` matches on `session_id`. The Claude Code docs suggest a subagent's hook
calls carry the parent's id, so its edits should mark the parent session. ADR-0007's test
could not check this: the plugin's hooks did not run in that cloud session. If the id
differs, the gate misses a check after a subagent's edit; it never blocks wrongly. Record
the result in ADR-0007's "Tested" section with a dated amendment.

## Plugin agent definitions

**Priority: Low** · **Added:** 2026-11-11 · **Trigger to act:** the agent briefs in skills
grow long, or the same brief is repeated in two or more skills.

Skills hand work to Claude Code's built-in agents, with the brief in the skill text
(`multi-session` S0). Shipping definitions in `plugin/agents/` would let skills share a
brief, but it changes the Architecture Style line.

## Shell commands get past the edit hooks

**Priority: Low** · **Added:** 2026-11-14 · **Trigger to act:** a session changes a
protected file, edits on the main branch, or edits code without the `Stop` gate noticing, by
running a shell command instead of Edit or Write.

From the same review. `README.md`, "What the hooks do not cover", lists the gap: `sed -i`,
`echo > .env`, `tee` or any code change made from Bash gets past the main-branch,
protected-paths and edit-marking hooks. `pre-bash-git.sh` already parses commands with a
quote-aware reader; a sibling hook could refuse redirections and in-place edits aimed at
protected paths or made on the main branch. It must still let a command through when it
cannot read it (Architecture, Boundaries). See also "Two gaps left in the `Stop` gate".

## Keep skills short

**Priority: Low** · **Added:** 2026-11-14 · **Trigger to act:** a fix for a step Claude
skipped adds more wording to a skill, or a `SKILL.md` passes 350 lines.

From the same review. `simple-session` and `multi-session` are each about 300 lines, and this
repository's `CLAUDE.md` is about 10 KB, all in context. Past misses (the review skipped, the
skill not firing on a named branch) were fixed by adding text, which makes the next miss more
likely. Options: move edge cases into `plugin/reference/` files that skills read on demand,
and have `scripts/check` warn when a skill passes a line limit.

## Re-check two fixes on the next full eval run

**Added:** 2026-10-29 · **Trigger to act:** the next full suite run
(`claude plugin eval . --scaffold --allow-tools Bash Write Edit --ablation with-without`).

- **`simple-session` could miss when the user names a branch.** After a first fix it fired in
  5 of 6 runs of `02-small-change`. Version 0.7.3 moved the trigger to the front of the skill
  description and said the same in the template `CLAUDE.md`. It then fired in 10 of 10 runs
  (2026-10-29, Claude Code 2.1.312, one model).
- **The review was often skipped.** Before 0.9.0, Claude skipped `/simplify` and
  `/code-review` in about 5 of 6 code-change runs; after it, in 1 of 6, by reading the diff by
  hand. Versions 0.9.1 to 0.9.3 say that reading the diff does not replace the two skills,
  that the review runs once per session, and that a follow-up change gets one more full
  review. Latest runs (2026-10-29): 13-reuse, 02-small-change and 15-follow-up-review passed
  3 of 3 each, with each skill called exactly once per run.

Both look fixed. Delete this entry if the full run agrees.

## Untested paths

**Added:** 2026-10-29 · **Trigger to act:** the next change to one of these paths.

- `spec`: case 12 passed 3 of 3 runs, but nothing tests the question-at-a-time path or the
  hand-over to a session. A recorded history, as in case 15, could test both.
- `simple-session`'s pull-request path has no eval case.
- `doctor` has no eval case. A fixture with `core.hooksPath` unset and `FILL IN` left in
  `CLAUDE.md` could check that it names both and edits nothing.
- `setup`'s install step has no eval case (the eval sandbox keeps `.claude/` read-only).
  `scripts/test-install.sh` covers `install.sh` itself.
- A Skill call made inside a subagent. A probe (2026-11-12) showed that `tool_used` graders
  count a subagent's Bash call, but not whether a subagent can call `/simplify` or
  `/code-review`. Test it before moving those two out of the main context.

## No plugin icon

**Added:** 2026-10-29 · **Trigger to act:** `claude plugin validate --strict` turns
`ICON_MISSING` from a warning into an error, or the plugin is listed somewhere public.

## Stale-docs check: designed, not built

**Added:** 2026-10-29 · **Trigger to act:** a reference doc is found wrong in use, and this
check would have flagged it.

A report of reference docs whose code changed after their `updated:` date. Design,
measurements and build plan: [backlog/stale-docs-check.md](./backlog/stale-docs-check.md).

## An `AGENTS.md` for other agents

**Added:** 2026-11-10 · **Trigger to act:** a project using the harness also uses Codex,
Cursor, Gemini CLI or Copilot.

Those tools read `AGENTS.md`, not `CLAUDE.md`. The installer could offer an `AGENTS.md` that
points at `CLAUDE.md`, so other agents and people follow the same facts. Skills keep reading
`CLAUDE.md` sections. The skills, hooks and `ask` rules work only in Claude Code, so other
agents would get the facts and `scripts/check` but none of the enforcement (review of
2026-11-14).

## A dedicated architecture design skill

**Added:** 2026-11-15 · **Trigger to act:** users ask for quality-attribute scenarios, a
deeper comparison of options, or C4 or draw.io diagrams as deliverables. Or the design text
in `setup` and `multi-session` grows past a short paragraph each.

Design is spread across `setup`, `simple-session`, `multi-session` S0, `write-doc` and
`plugin/reference/architecture-styles.md`. Until design is its own activity, a separate skill
would only repeat these.

## `scripts/check` recipes per stack

**Added:** 2026-11-10 · **Trigger to act:** `setup` fills in `scripts/check` badly or slowly for
a common stack.

A reference file under `plugin/reference/`, like `architecture-styles.md`, with lint, type,
test and boundary-check lines for Node, Python, Go and Rust. `setup` would read it on demand.
It stays generic: the plugin offers examples, and the project's `scripts/check` holds the
choice.

## A quickstart guide

**Added:** 2026-11-10 · **Trigger to act:** a new user asks how to start, or the plugin is
listed somewhere public.

`README.md` is accurate but dense. A five-minute guide in `docs/guides/`: install, run
`/yotamake:setup`, make a first change, see the stop before commit.

## Keep eval results over time

**Added:** 2026-11-10 · **Trigger to act:** the next full eval run.

Store each full run's per-case scores, costs, plugin version and Claude Code version as a
record, so a drop shows up as a regression. Running each case several times would also show
flaky skill firing more clearly. `node scripts/eval-costs.mjs <results folder>` prints those
numbers for one run, ready to paste into a record.

## The `Stop` hook ignores a project's own `Docs-only` line

**Added:** 2026-11-10 · **Trigger to act:** a project whose `Docs-only` line names other doc
paths reports that editing those docs blocks the end of a turn.

`post-edit-mark.sh` counts an edit as docs with the default rule only (files under `docs/`, and
Markdown at the root other than `CLAUDE.md`), because the `Docs-only` line is prose. Other doc
paths count as code, so Claude runs `scripts/check` once more than it needs to. A fix could be
a `.claude/yotamake/docs-paths.conf` of globs that the installer seeds and `setup` fills in
from that line.

## Two clashes `scripts/check` misses after a merge

**Added:** 2026-11-12 · **Trigger to act:** the next branch that merges main and hits
either clash, or any change to `scripts/consistency.mjs`.

Merging main into the autopilot branch showed both; each was fixed by hand.

- **Version not above main's.** `checkVersion` in `scripts/consistency.mjs` checks only that
  the three version files agree. It could also fail when `plugin/` (evals aside) changed
  since the merge-base but the version is not higher than the one on the main branch.
- **Two eval cases with one number.** Cases are matched by full folder name, so
  `20-trivial-change` and `20-multi-session-autopilot-offer` both passed. A check that the
  `NN-` prefixes in `plugin/evals/` are unique would catch it.

## Two gaps left in the `Stop` gate

**Added:** 2026-11-12 · **Trigger to act:** a session edits code in a separate repository by
absolute path and ends its turn unchecked, or two sessions edit the same tree and one of them
stops without its check.

The review of the worktree fix (0.22.1) found two gaps it does not close. `stop-check-ran.sh`
finds trees through `git worktree list`, so an edit by absolute path into a separate
repository, not a worktree of this one, still gets past the gate. Closing it would need a
per-session list of edited roots kept outside any one repository. And `yotamake-edited` holds
one session id: when two sessions edit the same tree, the last writer wins and the other
session's turn ends unchecked. Both gaps were there before the fix.

## Harness-owned scripts listed one by one

**Added:** 2026-11-10 · **Trigger to act:** a third script in `.claude/yotamake/`.

`install.sh`'s `managed` list and `scripts/consistency.mjs` name each harness-owned script in
`.claude/yotamake/`. Matching `.claude/yotamake/*.sh` by pattern would save an edit in both
for each new script.

## Copied graders and a shared word

**Added:** 2026-11-12 · **Trigger to act:** the next change to an eval grader, or to the
side-fix policy in `CLAUDE.md`, **Conventions**.

- `skill-fired.md` and `asks-before-commit.md` sit in many case folders with the same
  text (10 and 6 identical copies). Move them into `plugin/evals/_graders/` like the
  shared graders already there.
- The `multi-session` `skill-fired.md` (cases 07, 16, 18, 22) and `no-code-edits.md`
  (07, 16, 22) need new names before they can move, since other cases use those names for
  other content.
- The "trivial side-fix policy" in `CLAUDE.md` and the trivial review tier in
  `simple-session` use the same word for different things. Rename one.

## Small harness ideas

**Added:** 2026-11-10 · **Trigger to act:** a change to the area each one touches.

- A status line showing the branch and the current session of an effort.
- A `PreCompact` hook that writes the multi-session `log.md` entry before the context is
  compacted.
- `simple-session` suggests `/security-review` when a diff touches auth or secrets.

## The size check can misjudge a change

**Added:** 2026-11-14 · **Trigger to act:** a user or an eval run reports a change wrongly
called too big for one session, or one that should have been.

From the same review. `simple-session`, "Check the size", uses fixed tests (more than one new
interface, a schema change plus other code, and so on). They are easy to apply but blunt.
Collect the misjudged cases before changing the tests; case 03 covers the too-big path.
