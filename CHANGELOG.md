# Changelog

What changed in each release of the Yotamake plugin, newest first. Get the latest with
`claude plugin update yotamake@yotamake`. Releases from 0.35.0 on are tagged `vX.Y.Z`.

Each change adds its line under `## Unreleased`; CLAUDE.md, "Branching and releases", says
how a release closes it.

## Unreleased

- A changelog, release tags and a check that each version has an entry. `simple-session`
  does the project's after-merge release steps, such as a tag. CI also runs weekly on the
  latest Claude Code.
- `scripts/check` writes no pass stamp when no check ran, and its note names
  `/yotamake:setup`; `simple-session` reports an empty gate. Older installs get it from
  `upgrades.md`.

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
