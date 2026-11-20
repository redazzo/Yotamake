# Changelog

What changed in each release of the Yotamake plugin, newest first. Get the latest with
`claude plugin update yotamake@yotamake`. Releases from 0.35.0 on are tagged `vX.Y.Z`.

Each change adds its line under `## Unreleased`; CLAUDE.md, "Branching and releases", says
how a release closes it.

## Unreleased

- `multi-session` autopilot makes one commit per effort, not one per session, and reviews
  the whole effort once at the end. A committed setup still reviews and commits each
  session (ADR-0012, which supersedes ADR-0007 and ADR-0009).

## 0.39.1 — 2026-11-20

- The commit gate no longer counts a subagent's hand-back message as a user prompt, so a
  fix made after a background reviewer reports no longer asks for the review again.

## 0.39.0 — 2026-11-20

- `spec`: each acceptance criterion names a check that fails until it is met. An optional
  ordered **Tasks** list follows, which `simple-session` works down and `multi-session` moves
  into `plan.md`.

## 0.38.0 — 2026-11-19

- `CLAUDE.md` gains a `**Session size:**` line in **Branching and releases**: the largest diff
  one session takes (default about 400 changed lines or 15 files). "How to work here" now
  points to `simple-session`, "Check the size", instead of "one branch and one context".
  Older installs get both from the upgrade entry.
- `simple-session`, "Check the size", sizes a session by review, revert and settled
  decisions, against the `Session size` limit and a few signals. Schema plus code, several
  interfaces, several packages or an ADR are no longer too big by themselves (an ADR is written
  first). A step that cannot be undone counts only beside work that could ship separately.
  Docs-only changes get the estimate and the limit too; only trivial changes skip them. A
  session stops partway when it outgrows the limit, and its report gives the estimate beside
  the real size.
- `multi-session` sizes the sessions it plans by the same check, not by what fits in one
  context. A session that stops partway can be split in `plan.md` once you agree, and
  autopilot pauses on the same signals.

## 0.37.1 — 2026-11-18

- `multi-session`: S0, the planning session, is now defined, and `plan.md` lists it. It
  starts `in progress` and becomes `done` when you approve the plan, so a resume never skips
  an unapproved S0.

## 0.37.0 — 2026-11-18

- A commit gate: the plugin's Bash hook refuses `git commit` until `scripts/check` has
  passed since the last edit and both `/simplify` and `/code-review` have run on the change.
  A docs-only branch, or a commit message with a `Review-skipped: <reason>` trailer line
  (used for a trivial branch and for the release bump), needs the check but no review
  (ADR-0010). `simple-session` now proposes that line for a trivial branch.
- A new hook, `record-event.sh`, logs review skill calls (called or typed) and user prompts
  for the gate.
- The `Stop` hook no longer blocks the main conversation over edits a subagent made; the
  commit gate still counts them.

## 0.36.1 — 2026-11-18

- `simple-session` is shorter: what to do when a project has no `scripts/check`, an empty
  gate or an unfilled Architecture section, or a review tool is missing, moved to
  `plugin/reference/missing-setup.md`, read only when needed.

## 0.36.0 — 2026-11-17

- `multi-session`: autopilot is the default. Approving S0's spec and plan starts it, unless
  you say "approve, step through". S0's last message lists the open decisions with the
  recommendation autopilot will take for each (ADR-0009).

## 0.35.0 — 2026-11-17

- A changelog, release tags and a check that each version has an entry. `simple-session`
  does the project's after-merge release steps, such as a tag. CI also runs weekly on the
  latest Claude Code.
- `scripts/check` writes no pass stamp when no check ran, and its note names
  `/yotamake:setup`; `simple-session` reports an empty gate. Older installs get it from
  `upgrades.md`.
- `multi-session` is shorter: its autopilot and parallel-session rules moved to
  `plugin/reference/`, which it reads only when they apply.
- `simple-session` is shorter: "Harness upgrades", "Findings not acted on" and the commit
  and merge or pull-request step read their detail from `plugin/reference/` when they apply.
  `scripts/check` fails when a `SKILL.md` passes 250 lines.
- Hooks and `scripts/check` read the main branch and doc paths from a new project-owned
  `.claude/yotamake/project.conf` (ADR-0008), falling back to `CLAUDE.md`; the edit-marking
  hook follows a project's own doc paths. `setup` fills the file and `doctor` checks it
  against `CLAUDE.md`. Older installs get it from `upgrades.md`.

## 0.34.1 — 2026-11-17

- Hooks: close permission holes and catch wrapped git commands.

## 0.34.0 — 2026-11-16

- `simple-session` records review findings it does not act on, in a section every branch
  reads.
- `debugging` tests the shared premise after two failed fixes.

## 0.33.0 — 2026-11-16

- Specs prompt for states, and skills flag hidden state machines.

## 0.32.0 — 2026-11-15

- A domain glossary, and checks for naming drift.

## 0.31.0 — 2026-11-15

- New skill `improve-architecture`: a read-only review of the code's design.

## 0.30.0 — 2026-11-15

- `setup` chooses a style in a repository with no code; "Changing the style" added.

## 0.29.0 — 2026-11-15

- `write-doc`: an ADR template; ADRs may be amended.

## 0.28.0 — 2026-11-15

- `write-doc`: a template for each kind of doc.

## 0.27.0 — 2026-11-13

- `multi-session` autopilot: runs an approved effort's sessions one after another.

## 0.26.0 — 2026-11-12

- `simple-session` hands the review's design read to an agent.

## 0.25.0 — 2026-11-12

- New skill `debugging`, for bug fixes inside a session.

## 0.24.0 — 2026-11-12

- `simple-session`: Test-first as a project choice.

## 0.23.0 — 2026-11-12

- `simple-session`: a trivial review tier for comment-only changes.

## 0.22.1 — 2026-11-12

- Hooks: the Stop gate checks edits in other worktrees.

## 0.22.0 — 2026-11-11

- `multi-session`: rules for running independent sessions in parallel worktrees.

## 0.21.1 — 2026-11-11

- Hooks find the project root from the edited file or the hook's folder, so they work in
  worktrees.

## 0.21.0 — 2026-11-11

- Skills hand S0 analysis to subagents and keep the review inline.

## 0.20.1 — 2026-11-11

- Template: `CLAUDE.md` says what to do when the plugin is not loaded.

## 0.20.0 — 2026-11-10

- New skill `/yotamake:doctor`: a read-only health check of the harness.

## 0.19.0 — 2026-11-10

- Hooks block `--no-verify` and commits on the main branch from Bash.

## 0.18.0 — 2026-11-10

- A `SessionStart` hook flags an outdated harness.

## 0.17.0 — 2026-11-10

- A `SessionStart` hook tells Claude the branch and the active efforts.

## 0.16.0 — 2026-11-10

- A project `SessionStart` hook sets `core.hooksPath`.

## 0.15.0 — 2026-11-10

- Hooks block the end of a turn when code changed since the last passing check.

## 0.14.0 — 2026-11-10

- Skills switch branches with `git switch`, so sessions do not prompt.

## 0.13.0 — 2026-11-10

- Template: branch, stage and fast-forward pull without a prompt.

## 0.12.0 — 2026-11-09

- `simple-session` counts only `docs/` and root Markdown other than `CLAUDE.md` as
  docs-only; a Docs-only line in `CLAUDE.md`.

## 0.11.5 — 2026-11-09

- Skills point at another skill's step by its heading, not its number. Hooks share one
  tool-call reader and one protected-paths list.

## 0.11.4 — 2026-11-09

- This repository installs its own harness.

## 0.11.3 — 2026-11-08

- One docs front-matter reader; the stale records index regenerated; protected paths match
  project-relative paths.

## Before 0.11.3

- Earlier versions had no release commits. See `git log`.
