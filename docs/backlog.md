---
kind: reference
status: current
updated: 2026-11-11
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

Independent sessions of one effort could run in parallel git worktrees; the main-branch hook
already allows that. Superpowers and claude-flow both work this way. (S0 analysis already runs
in subagents; for the review, see the next entry.)

## Delegate the review's design read

**Priority: Medium** · **Added:** 2026-11-11 · **Trigger to act:** the design read in
`simple-session`, "Review", fills the main context in a real session, or
`claude plugin eval` documents that `tool_used` graders count a subagent's calls.

The review stays in the main context (`simple-session`, "Review", says why). Also, the
review graders in eval cases 02, 13, 15 and 19 probably miss calls made inside a subagent. The
design read against Architecture could still move to a subagent that returns conflicts only.
If the graders do see subagent calls, the whole review could move.

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

## The `Stop` hook ignores a project's own `Docs-only` line

**Added:** 2026-11-10 · **Trigger to act:** a project whose `Docs-only` line names other doc
paths reports that editing those docs blocks the end of a turn.

`post-edit-mark.sh` counts an edit as docs with the default rule only (files under `docs/`, and
Markdown at the root other than `CLAUDE.md`), because the `Docs-only` line is prose. Other doc
paths count as code, so Claude runs `scripts/check` once more than it needs to. A fix could be
a `.claude/yotamake/docs-paths.conf` of globs that the installer seeds and `setup` fills in
from that line.

## Eval sandbox can deny `git`

**Added:** 2026-11-10 · **Trigger to act:** an eval run where a grader fails because a
transcript says `git` was denied.

In case `19-claude-md-only` (2026-11-10, `--runs 3`), the sandbox denied `/usr/bin/git` in
two runs. `scripts/check` could not pass, the `Stop` hook blocked the stop, and Claude waited
for git access instead of asking to commit, so `asks-before-commit` failed. `skill-fired`
passed 3 of 3. Find out why git was denied (`--allow-tools Bash` was given) before reading
those graders as a harness failure.

## Harness-owned scripts listed one by one

**Added:** 2026-11-10 · **Trigger to act:** a third script in `.claude/yotamake/`.

`install.sh`'s `managed` list and `scripts/consistency.mjs` name each harness-owned script in
`.claude/yotamake/`. Matching `.claude/yotamake/*.sh` by pattern would save an edit in both
for each new script.

## Small harness ideas

**Added:** 2026-11-10 · **Trigger to act:** a change to the area each one touches.

- A status line showing the branch and the current session of an effort.
- A `PreCompact` hook that writes the multi-session `log.md` entry before the context is
  compacted.
- `simple-session` suggests `/security-review` when a diff touches auth or secrets.
