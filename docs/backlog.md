---
kind: reference
status: current
updated: 2026-11-18
owns: [open-work-register]
---

# Backlog

**The** register of open engineering work: everything outstanding that is not already an ADR
or an in-flight branch.

**Format.** One `##` entry per item, each carrying **Added** and a **Trigger to act**: the
observable condition that should make someone pick it up. An item with no trigger is a wish,
not a backlog entry. Items with substantial written analysis keep a detail document in
`backlog/` and link to it from here. Each entry carries a **Priority**: High, Medium or
Low. **The entries are ranked:** High first, then Medium, then Low, and inside each group the
one to do first sits on top. A new entry goes in at its rank, not at the end.

Each entry also carries these three fields:

- **Category**, one of these:
  - **Evals**: the eval suite, its graders and its runs.
  - **Skills**: what the skills say and do.
  - **Hooks**: the hooks, and what gets past them.
  - **Tooling**: `scripts/check`, the installer, CI and releases.
  - **Reach**: bringing the harness to new users and other agents.
- **Status**, one of these:
  - **Ready**: the trigger has fired, and the work can start now.
  - **Waiting**: the trigger has not fired.
  - **Blocked**: the work cannot start until another entry closes or a fix lands outside
    this repository. The entry says which.
- **Next review date**: the day to check the trigger and the status again. A review sets the
  next date. A new entry that is Waiting gets a date three months after it was added.

**Done means gone.** Delete the entry when the work lands, and write a
[record](./records/README.md) if it was worth explaining.

---

## Eval sandbox denies `git`

**Priority: High** · **Category:** Evals · **Status:** Blocked ·
**Next review date:** 2026-12-01 · **Added:** 2026-11-10 · **Trigger to act:** a new Claude Code release, or
a fix posted on [claude-code#108887](https://github.com/anthropics/claude-code/issues/108887).

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

Rechecked 2026-11-16 on Claude Code 2.1.325: `/usr/bin/git` is still on the deny list.

**A second cause, found the same day.** With the three helpers replaced by copies of git
(`cp --remove-destination /usr/bin/git` over each; `sudo pacman -S git` restores the
links), git is no longer denied, but the sandbox mounts the eval repository's `.git`
read-only: `git switch -c` fails with `Unable to create '.git/index.lock': Read-only file
system`. The settings file does not list it, so Claude Code adds it at run time. Saved runs
from 2026-10-29 on show these errors beside the git denials, and none shows a branch
created. `claude plugin eval` has no option to make the repository writable, and an Ubuntu
machine would not help. So this entry closes only when a release fixes both causes; check
that a git case (`01-branches-first`, about $0.20) creates its branch.

## Show that the harness helps: Δ and cost against the baseline

**Priority: High** · **Category:** Evals · **Status:** Blocked ·
**Next review date:** 2026-12-18 · **Added:** 2026-11-14 · **Trigger to act:** "Eval sandbox denies `git`" is
closed.

From a review of Yotamake against other harnesses (2026-11-14). No Δ (score with the plugin
minus score without) has been published, though `README.md`, Evals, calls it the headline
number. The pass rates on record are small samples ("3 of 3", "10 of 10") on one model and
one Claude Code version, and most code-change graders have failed since 2026-10-29 because of
the sandbox, not the harness. Run the full suite with `--ablation with-without`, at least 5
runs per case and on two models, and write a record with Δ and mean cost per case for both
arms. This is the first run for "Keep eval results over time" and "Re-check two fixes on the
next full eval run".

Comparison of 2026-11-18 (Yotamake against Superpowers, Spec Kit, BMAD and others): of
those, only Yotamake has an eval suite comparing runs with and without it, so Δ is the
claim the others cannot make. Until it is published, that strength is still a plan.

## LLM judges fail case 23 on text that meets them

**Priority: Medium** · **Category:** Evals · **Status:** Blocked ·
**Next review date:** 2026-12-18 · **Added:** 2026-11-15 · **Trigger to act:** case 23 scores below 1.00 on
a run whose final messages a person reads as passing, or another case shows the same split
votes.

In six runs of `23-improve-architecture` (2026-11-15, 0.31.0), every final message did what
the case asks, yet the judges split or failed. `rating` voted FAIL three times on a message
with "**Rating:** Strong", and `drift` did the same on one saying `src/name.js` "is
not in Architecture → Modules". Splitting each grader into one short claim fixed
`shallow-module` (3 of 3) but not the rest.

2026-11-17: `rating` is now a regex on the final message, so no judge reads it and the skill
text Claude read cannot match it. A paid run (`--runs 3`, $0.90) passed it 3 of 3, but the
judges still split on `drift` and `asks-which` although every message met them. Both are now
regexes too, checked against the six saved final messages (all match) and against messages
that should fail. Starting work is still caught by `no-file-changes`. Why the judges failed
is not known: they may be given the wrong text, which would touch every `llm` grader. Next
step: one run of case 23 with `--keep-temp`, to see what the judges of `no-file-changes` and
`shallow-module` are given; delete this entry if it scores 1.00 and the judge input is right.

Review of 2026-11-16: more cases could use graders that need no judge. The eval runner has
no grader type that runs a command on the final repository; it has `regex` on the trace, the
final message or one file, and `file_exists`. `04-docs-only/guide-fixed` is now a regex on the
guide. `20-trivial-change/comment-fixed` and `owning-doc-updated` in cases 02 and 18 also say
no other file changed, which a regex on one file cannot check, so they stay `llm` until such a
type exists.

2026-11-17: case 22 (0.36.0, `--runs 3`, $0.68) split the same way. It scored 0.88: the judges
failed `gives-resume-line` in two runs and `offers-autopilot` in one, though all three final
messages gave the resume line, said approval starts autopilot and said how to turn it off.

## Session overhead on small changes

**Priority: Medium** · **Category:** Skills · **Status:** Blocked ·
**Next review date:** 2026-12-18 · **Added:** 2026-11-14 · **Trigger to act:** the Δ run above gives cost
per case, or a user reports that small fixes cost too much time or money.

From the same review. Any change that is not docs-only or trivial runs `scripts/check`,
`/simplify`, `/code-review` and a design-read agent, and stops to ask. Nobody has measured
what that costs over the baseline. First compare cost, turns and seconds for cases 02, 13 and
20 in both arms. If the overhead is large, consider a tier between trivial and full, for
example a small diff inside one module that skips `/simplify` and the design read. That
changes `simple-session`, "Review", and cases 02, 13, 15 and 20 cover it.

Review of 2026-11-16: a one-line code fix runs the check, `/simplify`, `/code-review`, a
design-read agent and two or three permission prompts. A middle tier to try first: a small
diff inside one module runs the check and `/code-review` only. Take the threshold from the
cost numbers, not from a guess.

Comparison of 2026-11-18: lighter harnesses such as Superpowers load a skill only when the
task needs it, so a small fix costs little. Here every code change pays for the full
session. This is the main cost of the harness's strength (enforcement), so measure it before
cutting anything.

## Enforce the session steps in order with hooks

**Priority: Low** · **Category:** Hooks · **Status:** Ready ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-16 · **Trigger to act:** a session skips or reorders a
step that a hook could have caught, or a change must add wording to a `SKILL.md` at the
250-line limit.

Work started on 2026-11-18, on branch `feat/commit-gate`. The design is
[ADR-0010](./decisions/0010-commit-gate-by-step-table.md) (Proposed): a plugin hook refuses
`git commit` until the check has passed since the last code edit and both review skills ran
in the review window, read from one step table by one evaluator over a per-worktree events
log. It stays inside the Boundary and does not need
[ADR-0006](./decisions/0006-commit-stop-by-project-hook.md). Delete this entry when the
gate lands.

## Gaps left in the git and protected-paths guards

**Priority: Low** · **Category:** Hooks · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-17 · **Trigger to act:** a session deletes or moves a
branch, commits on the main branch, skips the pre-commit hook or reads a secret through one of
these forms.

From the review of the 0.34.1 hook fixes. `ask` rules match from the start of a command, so
`git branch foo -D` still runs without a prompt. `pre-bash-git.sh` could refuse those flags
anywhere, since it already reads flag clusters. The wrapper list in `pre-bash-git.sh` is best
effort: `sudo`, `xargs`, `eval` and `$(…)` still hide git. And the protected-paths hook runs
on Read but not Grep, so a Grep on a folder can still show a secret.

## Tag releases from CI

**Priority: Low** · **Category:** Tooling · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-17 · **Trigger to act:** a release goes untagged.

From the review of the changelog work (0.35.0). The `vX.Y.Z` tag is a manual step after the
merge (`CLAUDE.md`, "Branching and releases"), so it can be forgotten. A workflow on push to
`main` could tag the merge when the version in `plugin/.claude-plugin/plugin.json` has no
tag yet.

## Copies of the main-branch reader

**Priority: Low** · **Category:** Tooling · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-17 · **Trigger to act:** one copy changes without the
others.

From the review of `project.conf` (0.35.0). The `awk` that reads `main-branch` from
`.claude/yotamake/project.conf`, and its `sed` fallback on the `CLAUDE.md` line, are copied
into `plugin/hooks/lib.sh`, `session-context.sh` (template and this repository) and both
`scripts/check` copies. This is on purpose: those scripts run without the plugin
([ADR-0008](./decisions/0008-facts-hooks-read-in-project-conf.md)). A rule in
`scripts/consistency.mjs` could check the `awk` copies stay identical (the `sed` in
`session-context.sh` already has a different form).

## Shell commands get past the edit hooks

**Priority: Low** · **Category:** Hooks · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-14 · **Trigger to act:** a session changes a protected
file, edits on the main branch, or edits code without the `Stop` gate noticing, by running a
shell command instead of Edit or Write.

From the same review. `README.md`, "What the hooks do not cover", lists the gap: `sed -i`,
`echo > .env`, `tee` or any code change made from Bash gets past the main-branch,
protected-paths and edit-marking hooks. `pre-bash-git.sh` already parses commands with a
quote-aware reader; a sibling hook could refuse redirections and in-place edits aimed at
protected paths or made on the main branch. It must still let a command through when it
cannot read it (Architecture, Boundaries). See also "Two gaps left in the `Stop` gate".

Comparison of 2026-11-18: blocking hooks are what set this harness apart from the
prompt-only ones, so this gap weakens its main claim. It may deserve a higher priority once
the eval work above is done.

## Two gaps left in the `Stop` gate

**Priority: Low** · **Category:** Hooks · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-12 · **Trigger to act:** a session edits code in a
separate repository by absolute path and ends its turn unchecked, or two sessions edit the same
tree and one of them stops without its check.

The review of the worktree fix (0.22.1) found two gaps it does not close. `stop-check-ran.sh`
finds trees through `git worktree list`, so an edit by absolute path into a separate
repository, not a worktree of this one, still gets past the gate. Closing it would need a
per-session list of edited roots kept outside any one repository. And `yotamake-edited` holds
one session id: when two sessions edit the same tree, the last writer wins and the other
session's turn ends unchecked. Both gaps were there before the fix.

## Test the `Stop` gate after a subagent's edit

**Priority: Low** · **Category:** Hooks · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-12 · **Trigger to act:** the next session where the
plugin's hooks run and a subagent edits code (an autopilot run, for example).

`stop-check-ran.sh` matches on `session_id`. The Claude Code docs suggest a subagent's hook
calls carry the parent's id, so its edits should mark the parent session. ADR-0007's test
could not check this: the plugin's hooks did not run in that cloud session. If the id
differs, the gate misses a check after a subagent's edit; it never blocks wrongly. Record
the result in ADR-0007's "Tested" section with a dated amendment.

## Two clashes `scripts/check` misses after a merge

**Priority: Low** · **Category:** Tooling · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-12 · **Trigger to act:** the next branch that merges
main and hits either clash, or any change to `scripts/consistency.mjs`.

Merging main into the autopilot branch showed both; each was fixed by hand.

- **Version not above main's.** `checkVersion` in `scripts/consistency.mjs` checks only that
  the three version files agree. It could also fail when `plugin/` (evals aside) changed
  since the merge-base but the version is not higher than the one on the main branch.
- **Two eval cases with one number.** Cases are matched by full folder name, so
  `20-trivial-change` and `20-multi-session-autopilot-offer` both passed. A check that the
  `NN-` prefixes in `plugin/evals/` are unique would catch it.

## Re-check two fixes on the next full eval run

**Priority: Low** · **Category:** Evals · **Status:** Blocked ·
**Next review date:** 2026-12-18 · **Added:** 2026-10-29 · **Trigger to act:** the next full suite run
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

## Keep eval results over time

**Priority: Low** · **Category:** Evals · **Status:** Blocked ·
**Next review date:** 2026-12-18 · **Added:** 2026-11-10 · **Trigger to act:** the next full eval run.

Store each full run's per-case scores, costs, plugin version and Claude Code version as a
record, so a drop shows up as a regression. Running each case several times would also show
flaky skill firing more clearly. `node scripts/eval-costs.mjs <results folder>` prints those
numbers for one run, ready to paste into a record.

## Untested paths

**Priority: Low** · **Category:** Evals · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-10-29 · **Trigger to act:** the next change to one of these
paths.

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
- Autopilot after S0's approval (ADR-0009): case 22 checks only that S0 states the default
  and starts nothing. No case answers the approval and checks that autopilot starts, or that
  "approve, step through" records `Autopilot: off`. A recorded history, as in case 15, could
  test both, once the eval sandbox allows `git` (see "Eval sandbox denies `git`").

## Copied graders and a shared word

**Priority: Low** · **Category:** Evals · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-12 · **Trigger to act:** the next change to an eval
grader, or to the side-fix policy in `CLAUDE.md`, **Conventions**.

- `skill-fired.md` and `asks-before-commit.md` sit in many case folders with the same
  text (10 and 6 identical copies). Move them into `plugin/evals/_graders/` like the
  shared graders already there.
- The `multi-session` `skill-fired.md` (cases 07, 16, 18, 22) and `no-code-edits.md`
  (07, 16, 22) need new names before they can move, since other cases use those names for
  other content.
- The "trivial side-fix policy" in `CLAUDE.md` and the trivial review tier in
  `simple-session` use the same word for different things. Rename one.

## Harness-owned scripts listed one by one

**Priority: Low** · **Category:** Tooling · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-10 · **Trigger to act:** a third script in
`.claude/yotamake/`.

`install.sh`'s `managed` list and `scripts/consistency.mjs` name each harness-owned script in
`.claude/yotamake/`. Matching `.claude/yotamake/*.sh` by pattern would save an edit in both
for each new script.

## The size check can misjudge a change

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-14 · **Trigger to act:** a user or an eval run reports a
change wrongly called too big for one session, or one that should have been.

From the same review. `simple-session`, "Check the size", uses fixed tests (more than one new
interface, a schema change plus other code, and so on). They are easy to apply but blunt.
Collect the misjudged cases before changing the tests; case 03 covers the too-big path.

## Autopilot context growth

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-12 · **Trigger to act:** an autopilot run whose main
conversation compacts before the end.

Under autopilot the main conversation runs the review of every session, so each review's
findings and fixes land in its context (ADR-0007). A long effort may fill it. One option:
hand the review's fixes to a fix agent, and keep only its summary.

## Let a hook approve commits in opted-in worktrees

**Priority: Low** · **Category:** Hooks · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-11 · **Trigger to act:** the commit prompt in parallel
worktree sessions is reported as too costly, even with the opt-in that skips the
stop-and-report exchange (ADR-0005, rule 6).

[ADR-0006](./decisions/0006-commit-stop-by-project-hook.md) (Proposed) has the design: drop
`Bash(git commit:*)` from the `ask` list and add a project `PreToolUse` hook that fails
closed, asking for every commit except on an opted-in worktree branch. When the trigger
fires, run the tests it lists under "Before acceptance" first, then build it.

## Spawn worktree sessions from the main conversation

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-11 · **Trigger to act:** users find opening one Claude
Code conversation per worktree too slow, or a subagent can stop and ask the user before a
commit.

[ADR-0005](./decisions/0005-parallel-sessions-in-worktrees.md) has the user open a
conversation in each worktree, so every session keeps its own stop before commit
(ADR-0003). [ADR-0007](./decisions/0007-autopilot-runs-sessions-in-subagents.md) now lets
the main conversation run sessions as subagents under autopilot, but one at a time on one
branch. What is left: the main conversation starts one `isolation: "worktree"` subagent per
parallel session. That would need a new ADR, or an amendment of ADR-0007, which rules out
parallel sessions under autopilot.

## Plugin agent definitions

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-11 · **Trigger to act:** the agent briefs in skills grow
long, or the same brief is repeated in two or more skills.

Skills hand work to Claude Code's built-in agents, with the brief in the skill text
(`multi-session` S0). Shipping definitions in `plugin/agents/` would let skills share a
brief, but it changes the Architecture Style line.

## A tasks step in `spec`

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-18 · **Trigger to act:** a session built from a spec
misses one of the spec's acceptance criteria, or a user asks for a task list before code.

From the comparison of 2026-11-18. GitHub Spec Kit goes spec → plan → tasks: an ordered list
of small tasks, each one checkable. Yotamake's `spec` writes scope and numbered acceptance
criteria, then hands over straight to a session. An optional last step could list the
ordered tasks, each naming the criterion (A1, A2, …) it meets, so the session works down the
list and the report ticks them off. Keep it out of `multi-session`, whose `plan.md` already
splits work into sessions, and keep it short (`scripts/check` caps a `SKILL.md` at 250 lines). `spec` and case 12 cover
it.

## A quickstart guide

**Priority: Low** · **Category:** Reach · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-10 · **Trigger to act:** a new user asks how to start,
or the plugin is listed somewhere public.

`README.md` is accurate but dense. A five-minute guide in `docs/guides/`: install, run
`/yotamake:setup`, make a first change, see the stop before commit.

## `scripts/check` recipes per stack

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-10 · **Trigger to act:** `setup` fills in
`scripts/check` badly or slowly for a common stack.

A reference file under `plugin/reference/`, like `architecture-styles.md`, with lint, type,
test and boundary-check lines for Node, Python, Go and Rust. `setup` would read it on demand.
It stays generic: the plugin offers examples, and the project's `scripts/check` holds the
choice.

## No size cap on `CLAUDE.md`

**Priority: Low** · **Category:** Tooling · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-18 · **Trigger to act:** this
repository's `CLAUDE.md` passes 12 KB again, or a session misses a rule because `CLAUDE.md`
is too long to follow.

`scripts/consistency.mjs` caps a `SKILL.md` at 250 lines (`MAX_SKILL_LINES`), but nothing caps
`CLAUDE.md`, which is read whole at every start. A trim on 2026-11-18 took it from 11.9 KB to
11.0 KB by moving three rules `scripts/check` enforces into
[guides/changing-the-harness.md](./guides/changing-the-harness.md). The rest is needed on most
branches, so more cuts mean either a cap that forces moves, or tighter wording in
Architecture (3.4 KB, the largest section). Found by the review of that trim.

## Stale-docs check: designed, not built

**Priority: Low** · **Category:** Tooling · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-10-29 · **Trigger to act:** a reference doc is found wrong
in use, and this check would have flagged it.

A report of reference docs whose code changed after their `updated:` date. Design,
measurements and build plan: [backlog/stale-docs-check.md](./backlog/stale-docs-check.md).

## An `AGENTS.md` for other agents

**Priority: Low** · **Category:** Reach · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-10 · **Trigger to act:** a project using the harness
also uses Codex, Cursor, Gemini CLI or Copilot.

Those tools read `AGENTS.md`, not `CLAUDE.md`. The installer could offer an `AGENTS.md` that
points at `CLAUDE.md`, so other agents and people follow the same facts. Skills keep reading
`CLAUDE.md` sections. The skills, hooks and `ask` rules work only in Claude Code, so other
agents would get the facts and `scripts/check` but none of the enforcement (review of
2026-11-14).

Comparison of 2026-11-18: Spec Kit and BMAD run on several agents; Yotamake runs only on
Claude Code. That is its main limit on reach, and the reason a team with mixed tools would
pick something else.

## A dedicated architecture design skill

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-15 · **Trigger to act:** users ask for quality-attribute
scenarios, a deeper comparison of options, or C4 or draw.io diagrams as deliverables. Or the
design text in `setup` and `multi-session` grows past a short paragraph each.

Design is spread across `setup`, `simple-session`, `multi-session` S0, `write-doc` and
`plugin/reference/architecture-styles.md`. Until design is its own activity, a separate skill
would only repeat these.

Reviewing the design of code that already exists is now its own skill, `improve-architecture`
(0.31.0), with its vocabulary in `plugin/reference/module-design.md`. What is left is
designing new architecture: quality-attribute scenarios, comparing options, and diagrams as
deliverables. Two ideas from the same source wait here too: asking several design questions
per round in `spec`, and having several agents each design a different interface for a
chosen candidate before picking one. pstack's `architect` ("design it twice": two
structurally different designs before choosing, compared on how much each hides behind a
small interface) is a second source for the same idea.

## Ideas from the pstack review

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-16 · **Trigger to act:** each item names its own. Do not take them
together: the 250-line cap on a `SKILL.md` and "Session overhead on small changes" say new
text has a cost.

From a review of [pstack](https://github.com/cursor/plugins/tree/main/pstack) (Cursor's
agent plugin: playbooks and principles, with no hooks or check command). It is strong at
evidence and weak at enforcement, the opposite of this harness. The review read about a
dozen of its skills; none of its text was run here. pstack is MIT-licensed. Rewrite what we
take in our own plain words.

- **A rule table with its enforcer.** Keep a table in `CLAUDE.md` pairing each rule with
  what enforces it (hook, check, type, or nothing). A rule with no enforcer is a repeat
  waiting to happen. Trigger: a Claude mistake is corrected twice, or "Enforce the session
  steps in order with hooks" is picked up. From pstack's `correct`.
- **A `/yotamake:correct` skill for target repos.** Find the mistakes agents keep making
  there, fix each at the highest level that works (design, then types, then a lint whose
  error names the fix, then a test, then docs), and prove each new check fails on a real
  past mistake. Trigger: the rule table above proves useful, or a user asks. Needs its own
  `multi-session` effort.
- **Label claims in the report.** Mark each claim in a session report as measured, inferred
  or guess, and never hand the user a check Claude could run itself. Proof by running a
  command for each review finding is too costly for every session; offer it as an opt-in
  step. Trigger: the Δ run gives cost per case. From `interrogate` and `blast-radius`.
- **Prove it on the running app.** Claude Code lists a built-in `run` skill that launches
  and drives an app. Check what it covers first. If it does not cover a repo's real use, a
  skill that generates a project-local verify skill (pstack's `create-verification-skill`)
  could. Trigger: a user reports a change that passed `scripts/check` but did not work.
- **Learn from a finished effort.** At `multi-session` close-out, sort what was learned with
  pstack's `reflect` questions: will it still be true in six months, would it change what a
  future agent does, and could a check enforce it instead of text. Skip its four-agent
  transcript review. Trigger: close-out entries keep repeating the same lessons.
- **State "done" as a test that can fail.** In `spec` and the first session of a
  `multi-session` effort, write the done condition so a command can fail it, and capture the
  value before the change, so the check reads old against new. From `figure-it-out`.
  Trigger: a spec's criteria turn out untestable.
- **Eval fixture leaks.** What is still open: the sandbox path `/tmp/claude-eval-*` that the
  agent can see (outside our control); the author and branch literals repeated in each
  `scaffold.sh` (one shared `_fixture/env.sh` would hold them); and case 15's
  `history.jsonl`, hand-edited for the rename, which `record.sh` should regenerate. It also
  still holds an older `simple-session` text (findings "in the report as suggestions", no
  trivial tier), so case 15 does not test the skill as shipped. Trigger: the Δ run, or the
  next re-record of case 15.
- **Watch the backlog rule's cost.** 0.34.0 writes each finding a branch does not fix into
  `docs/backlog.md` (`simple-session`, "Findings not acted on"). Two risks: parallel
  branches that each add an entry conflict in that file at merge (this rule's own branch
  did), and undone `/simplify` cleanups fill the backlog with small items whose line numbers
  go stale. Trigger: a merge conflict in `docs/backlog.md` between two session branches, or
  more than a few cleanup entries from one branch.

## Small harness ideas

**Priority: Low** · **Category:** Skills · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-11-10 · **Trigger to act:** a change to the area each one
touches.

- A status line showing the branch and the current session of an effort.
- A `PreCompact` hook that writes the multi-session `log.md` entry before the context is
  compacted.
- `simple-session` suggests `/security-review` when a diff touches auth or secrets.

## No plugin icon

**Priority: Low** · **Category:** Reach · **Status:** Waiting ·
**Next review date:** 2027-02-18 · **Added:** 2026-10-29 · **Trigger to act:** `claude plugin validate
--strict` turns `ICON_MISSING` from a warning into an error, or the plugin is listed somewhere
public.
