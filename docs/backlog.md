---
kind: reference
status: current
updated: 2026-11-10
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

## CI is written but not active

**Priority: High** · **Added:** 2026-10-29 · **Trigger to act:** someone who can push under
`.github/workflows/` has a few minutes.

[`docs/ci.yml`](./ci.yml) runs `scripts/check --all`. The GitHub App cannot push under
`.github/workflows/` (re-tried 2026-11-09: GitHub refused the push for lack of the
`workflows` permission), so a person adds it by hand: copy `docs/ci.yml` to
`.github/workflows/ci.yml`, push it to main, and check that the first run passes. Then delete
`docs/ci.yml` and this entry. The workflow pins the Claude Code CLI version; bump that on
purpose.

## A `SessionStart` hook that tells Claude where it is

**Priority: High** · **Added:** 2026-11-10 · **Trigger to act:** ADR-0004 is accepted, or an
eval case fails `skill-fired` again.

Superpowers uses a `SessionStart` hook to make sure its skills fire. Ours would print a few
lines at the start of each session: the branch and whether it is the main branch, pending
harness upgrades, any active `.scratchpad/` or `.sessions/` effort and its next session, and
that every edit runs as a session. It would answer `simple-session` missing a `CLAUDE.md`-only
edit (below), replace `simple-session`'s "Harness upgrades" file reads, and make resuming a
multi-session effort automatic. Build it with the script
[ADR-0004](./decisions/0004-project-session-start-hook-sets-hooks-path.md) proposes, since both
need a project `SessionStart` hook. A hook that adds context, not just enforcement, widens
**Style**, so it may need that ADR amended or a new one.

## A `Stop` hook that checks the gate ran

**Priority: High** · **Added:** 2026-11-10 · **Trigger to act:** an eval run or a real session
reports a code change without running `scripts/check`, `/simplify` or `/code-review`.

Running the check and the review before the report is asked for in text only, and earlier eval
runs skipped them. A `Stop` hook could block the end of a turn while the branch has code edits
newer than the last passing `scripts/check`, for example by having the script write a stamp
file under `.git/`. That turns the weakest step into enforcement, as the `ask` rules did for
commits. The hook must let the turn end when it cannot decide (**Boundaries**), and must not
fire on questions or docs-only branches.

## Measure what a session costs

**Priority: Medium** · **Added:** 2026-11-10 · **Trigger to act:** the next full eval run, or a
user says sessions are slow or expensive.

`simple-session` is about 260 lines, and a one-line typo fix still runs `/simplify` and
`/code-review`. Nothing measures that. Record turns, tokens and wall time per case next to the
pass rate. If small changes cost too much, consider a trivial tier (comments, typos, one-line
config) that runs the check but skips the two review skills.

## Use subagents and worktrees

**Priority: Medium** · **Added:** 2026-11-10 · **Trigger to act:** a multi-session effort needs
a `/clear` mid-session, or two of its sessions could run at once.

Everything runs in the main context today. S0 analysis and the review could run in subagents,
so the main context stays small. Independent sessions of one effort could run in parallel git
worktrees; the main-branch hook already allows that. Superpowers and claude-flow both delegate
this way.

## A debugging skill

**Priority: Medium** · **Added:** 2026-11-10 · **Trigger to act:** a `fix/` session patches a
symptom and the bug comes back, or a user asks how to debug with the harness.

There is no method for "fix this bug": reproduce it, write a failing test, find the root cause,
then fix. Superpowers' systematic-debugging skill is the model. It would run inside
`simple-session`, not replace it.

## Test-first as a project choice

**Priority: Medium** · **Added:** 2026-11-10 · **Trigger to act:** a project using the harness
asks for test-first, or a spec's criteria ship without tests.

`spec` asks for a test per criterion only "where the project has tests". A line in the
template `CLAUDE.md` (for example under **Checks**: "Test-first: yes") could make
`simple-session` write the failing test before the code. It changes a project-owned template
file and a section skills read, so it needs an `upgrades.md` entry and the section-name
updates `CLAUDE.md` lists.

## A `/yotamake:doctor` command

**Priority: Medium** · **Added:** 2026-11-10 · **Trigger to act:** a user hits a setup problem
that one of these checks would have shown.

One screen: whether `core.hooksPath` is set, the harness version and pending upgrades,
`FILL IN` placeholders left in `CLAUDE.md` and `scripts/check`, whether CI exists, and whether
`scripts/check` runs any checks at all. Most adopter mistakes, including the unset hook below,
would show up here.

## Block `--no-verify` and commits on main from Bash

**Priority: Medium** · **Added:** 2026-11-10 · **Trigger to act:** Claude passes `--no-verify`
or commits on the main branch in a real session or an eval.

The hooks watch Edit and Write only. A Bash `PreToolUse` hook can reliably block `--no-verify`
and `git commit` on the main branch. The general bypass (`sed -i`, `echo >`) stays with Claude
Code's permission prompt, as `README.md` says.

## Each clone needs the pre-commit hook set up

**Added:** 2026-11-09 · **Trigger to act:** someone starts working in a new clone of this
repository.

The pre-commit hook runs `scripts/check --staged`, but git's `core.hooksPath` setting is local
to a clone and is not cloned. So each person, in each clone, runs `./plugin/install.sh .`
once (or `git config core.hooksPath .githooks`). Until then their commits skip the hook, and
only CI (once active) catches a failing check.

A lasting fix would set it for them: a `SessionStart` hook in the project's
`.claude/settings.json` that sets `core.hooksPath` when `.githooks/` exists and nothing else
is set. That reaches every repository using the harness, so it needs its own decision:
[ADR-0004](./decisions/0004-project-session-start-hook-sets-hooks-path.md) proposes it. If it is
built, delete this entry.

## `simple-session` can miss a `CLAUDE.md`-only edit

**Added:** 2026-11-09 · **Trigger to act:** case `19-claude-md-only` fails `skill-fired` again.

In its first 3 runs (2026-11-09, Claude Code 2.1.319, one model), case 19 passed twice. In
the third run, `simple-session` never fired: Claude edited `CLAUDE.md` directly, ran no check
or review, and asked about committing. When the skill did fire, it treated `CLAUDE.md` as code
and ran the full review, as the Docs-only rule says. So the gap is the skill firing, not the
rule. A guess, not checked: "Only change CLAUDE.md" makes the task look too small for a
session. Re-run with `--keep-temp` to keep the transcript and see why.

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
- `setup`'s install step has no eval case (the eval sandbox keeps `.claude/` read-only).
  `scripts/test-install.sh` covers `install.sh` itself.

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
`CLAUDE.md` sections.

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
flaky skill firing more clearly.

## Small harness ideas

**Added:** 2026-11-10 · **Trigger to act:** a change to the area each one touches.

- A status line showing the branch and the current session of an effort.
- A `PreCompact` hook that writes the multi-session `log.md` entry before the context is
  compacted.
- `simple-session` suggests `/security-review` when a diff touches auth or secrets.
