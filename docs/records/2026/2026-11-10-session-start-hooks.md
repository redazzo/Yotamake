---
kind: record
date: 2026-11-10
status: historical
---

# SessionStart hooks: hooks path, session context, upgrades

**Date:** 2026-11-10 · **Status:** live in 0.18.0

**Why.** `core.hooksPath` is local to a clone, so a fresh clone skipped the pre-commit hook
until someone ran the installer. This repository was found in that state. Separately,
`simple-session` sometimes did not fire for a small edit, and its upgrade check and the
resuming of a multi-session effort both started from file reads.

**Decided.** [ADR-0004](../../decisions/0004-project-session-start-hook-sets-hooks-path.md)
was first drafted as a plugin hook. It was rewritten as a project hook in the template's
`.claude/settings.json`, because a plugin hook does not run when the plugin is not loaded,
the very case that started this. A repository opts out by listing the script in
`.claude/yotamake/skip`. Before accepting it, a test in a scratch repository showed that a
`systemMessage` reaches the person and plain stdout reaches Claude, and that a project
`SessionStart` hook runs on startup, on resume and after `/clear`. The ADR was accepted with
an amendment that adds session context and an upgrade notice.

**Built.**

- 0.16.0: `.claude/yotamake/set-hooks-path.sh`, the one copy of the hooks-path detection,
  shared by the `SessionStart` hook and `install.sh`. The settings merge gained a `hooks`
  branch: it adds an entry once, knows it by the script it names, and leaves it out when the
  script is skipped and absent.
- 0.17.0: `.claude/yotamake/session-context.sh` prints the branch and whether it is the main
  branch, active efforts and their next session, and the session rule. It has its own
  `SessionStart` entry, not a second command in the first as the amendment worded it, so
  either script can be skipped on its own.
- 0.18.0: the plugin hook `plugin/hooks/session-upgrades.sh` prints one line when the
  repository's harness version is older than the plugin's, or when it cannot compare them,
  so silence means up to date. `simple-session`, "Harness upgrades", starts from that line,
  and `multi-session`, "Resuming", offers to resume an effort the context names.

**Eval.** Case `19-claude-md-only` (`--runs 3`): `skill-fired` passed 3 of 3, so the backlog
entry about the skill missing a `CLAUDE.md`-only edit was closed. Two runs failed
`asks-before-commit` because the eval sandbox denied `git`.

**Left.** In [the backlog](../../backlog.md): "Eval sandbox can deny `git`",
"`session-upgrades.sh` is silent when `git` fails", "Harness-owned scripts listed one by
one" and "Template `CLAUDE.md` has no plugin-not-loaded fallback".
