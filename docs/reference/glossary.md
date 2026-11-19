---
kind: reference
status: current
updated: 2026-11-19
owns: [domain-language]
---

# Glossary

Yotamake is a harness for Claude Code: a working method for a repository, held in skills,
enforced by hooks, and installed into each repository. These are its own words. The words
for module design (module, seam, deep, deletion test) are in
[module-design.md](../../plugin/reference/module-design.md); the rules for this glossary are
in [domain-language.md](../../plugin/reference/domain-language.md). A path appears only
where the thing is that file or folder.

## Parts of the harness

- **Harness:** the whole method a repository gets: the plugin's skills and hooks, and the
  files the installer copies in. _Avoid:_ framework, toolkit.
- **Plugin:** the Claude Code plugin in `plugin/`, which users install once per machine.
  It holds the skills, hooks and template. _Avoid:_ extension.
- **Skill:** one part of the method, written as Markdown that Claude follows, such as
  `simple-session` or `spec`. _Avoid:_ command, prompt.
- **Hook:** a small shell script Claude Code or git runs at a set moment, which enforces part
  of the method or adds context.
- **Template:** the files in `plugin/template/` that the installer copies into a
  repository.
- **Harness-owned file:** a template file the installer refreshes on every run. The
  repository does not edit it. _Avoid:_ managed file (the installer's word for its list).
- **Project-owned file:** a template file the installer copies only when it is missing. The
  repository owns and edits it, so a later change to it reaches older installs only through
  an upgrade entry.
- **Upgrade entry:** a section of `plugin/reference/upgrades.md` that says how to check
  whether a change to a project-owned file is in place, and how to apply it.
- **Lite install:** an install without the docs system: no `docs/` folder and no docs
  checks. _Avoid:_ minimal install.
- **Project fact:** something a skill needs to know about one repository, such as its check
  command or main branch. Skills read project facts only from named sections of its
  `CLAUDE.md`. Hooks and `scripts/check` read a copy of two of them, the main branch and the
  doc paths, from `.claude/yotamake/project.conf`.

## Working

- **Session:** one change on one branch with one merge, small enough to review as one diff
  and revert on its own. Every change to code, tests or docs runs as one.
  `simple-session`, "Check the size", owns the rule. _Avoid:_ task, job.
- **Multi-session effort:** work too big for one session, run as numbered sessions that share
  a working folder. _Avoid:_ project, epic.
- **S0, S1, …:** the numbered sessions of a multi-session effort. S0 analyses the work and
  writes the plan, and changes no code. It is numbered zero because it comes before the work
  the plan lists, which starts at S1.
- **Working folder:** the folder a multi-session effort keeps its plan, findings and log in,
  so the work survives a `/clear`.
- **Spec:** a short agreement, made before any code, on what a change must do, as numbered
  acceptance criteria. _Avoid:_ design, plan.
- **Gate:** `scripts/check`, the one check command that Claude, the pre-commit hook and CI
  all run. _Avoid:_ linter, test suite.
- **Stop point:** a step Claude takes only after the user says yes, such as a commit or a
  merge.
- **Commit gate:** the plugin hook that refuses `git commit` until the session's steps are
  done: `scripts/check` passed since the last edit, and both review skills ran in the review
  window. Not the gate itself, which it only asks about. _Avoid:_ commit check.
- **Review window:** the stretch of a session a review must cover, from the later of the
  last commit and the last user prompt before the last code edit.
- **Docs-only branch:** a branch where every changed file is a doc, as the `Docs-only` line
  of `CLAUDE.md` names them. `simple-session` says what it may skip.
- **Trivial branch:** a branch that changes code, but where every changed line is a comment
  or a prose typo fix. `simple-session` says what it may skip.
- **Side-fix:** a trivial, harmless fix outside the current task, made without asking and
  named in the report.

## Design review

- **Candidate:** a change `improve-architecture` reports for the user to take on: a
  deepening, a drift or a naming drift.
- **Drift:** a place where the code and the Architecture section of `CLAUDE.md` disagree.
- **Naming drift:** a place where the code names a domain idea against the glossary.

## Docs

- **Doc kind:** one of the four kinds of doc, each kept up in its own way: reference,
  guide, decision and record.
- **Owner:** the one doc that owns a subject. Other docs link to it rather than restate it.
- **ADR:** a decision doc, in `docs/decisions/`. It is never edited, only superseded or
  amended. _Avoid:_ design doc.
- **Record:** a dated account of work done and why, written once.
- **Backlog entry:** an item of open work in `docs/backlog.md`, with the trigger that should
  make someone pick it up. _Avoid:_ ticket, todo.

## Evals

- **Eval case:** a scripted Claude Code run that checks a skill behaves as written. It costs money, so it is not part of the gate.
- **Fixture:** the small repository each eval case starts from.
