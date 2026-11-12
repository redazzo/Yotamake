# Findings

Source of truth for why each task exists. Verify a cited line before editing it; code moves.

## The method today

**F1 — Every session waits for the user (medium).** `multi-session` ends each session with a
`/clear` and a resume line (`plugin/skills/multi-session/SKILL.md:135-138`), and each session
stops to report before the commit (`plugin/skills/simple-session/SKILL.md:209-229`). Nothing
lets an approved plan run on its own. This is the gap the effort fills.

**F2 — A conversation driving session subagents was rejected (high).** ADR-0005 turned down
"one conversation driving worktree subagents", because the sessions would run without their
own stop before commit (`docs/decisions/0005-parallel-sessions-in-worktrees.md:80-82`). The
backlog entry "Spawn worktree sessions from the main conversation" says that option needs a
new ADR (`docs/backlog.md:103-112`). Autopilot drops the per-session stop on purpose, so it
needs ADR-0007 first.

**F3 — Commits and merges always prompt (high, kept).** ADR-0003 puts `git commit`, `merge`,
`push`, `rebase`, `reset --hard` and `tag` under `ask`. Per the Claude Code docs (read
2026-11-12 through an agent, untested here), no permission mode skips an `ask` rule, and a
foreground subagent passes the prompt to the user. So an autopilot run still needs one
keypress per commit. D1 keeps this; removing it waits for ADR-0006.

**F4 — The review stays in the main context (medium).** `simple-session`, "Review", says to
call `/simplify` and `/code-review` from the main context, not from a subagent
(`plugin/skills/simple-session/SKILL.md:179-183`). Under autopilot each session is a
subagent. The docs say subagents may call skills and start agents up to three levels deep,
but do not say whether built-in skills such as `/simplify` and `/code-review` are reachable
from a subagent. S1 tests this (D4).

**F5 — The committed setup already uses one branch (low, reuse).** On an assigned branch,
every session is commits on that branch (`plugin/skills/multi-session/SKILL.md:29-35`). The
mother branch reuses this shape: autopilot is the same, with a branch cut for the effort in
the local setup.

**F6 — Close-out deletes the folder before the final question (medium).** Close-out asks
before deleting the folder (`plugin/skills/multi-session/SKILL.md:205-208`). Under autopilot
the report and the merge question come after close-out, so the folder must live until the
user answers. D8.

**F7 — Version bump per branch (low).** `simple-session`, "On yes: commit, bump, integrate",
bumps on each branch (`plugin/skills/simple-session/SKILL.md:244-245`). On a mother branch,
one bump at the end is enough (A8).

## Hooks under autopilot

**F8 — The `Stop` gate probably still works (low, to verify).** `stop-check-ran.sh` blocks the
end of a turn when this session edited code after the last passing check
(`plugin/hooks/stop-check-ran.sh:27-38`). It matches on `session_id`. The docs say hooks fire
inside subagents and their sample payload carries the parent's `session_id`, so a subagent's
edits should mark the parent's session. This is an inference from an example; S1 checks it
in a real run.

## Docs and evals

**F9 — Docs that describe multi-session.** `README.md:217-246` (Sessions, Parallel sessions,
Subagents) and the evals table (`README.md:265-284`). The `docs/README.md` "Owns" table is
empty; `multi-session/SKILL.md` owns its rules.

**F10 — No eval covers autopilot.** Cases 07, 08, 16 and 18 cover `multi-session`
(`plugin/evals/`). A new case should check that S0 offers autopilot and runs nothing on it
until chosen (A1). A full autopilot run would be too slow and costly for an eval.

**F11 — No template changes under `plugin/template/` (low).** The multi-session templates
live in `plugin/skills/multi-session/templates/`, which ship with the plugin, so no
`upgrades.md` entry is needed. `session-context.sh` needs no change: it lists the effort
and its next session either way.
