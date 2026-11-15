# Decisions

Questions for the user. Ask each at the start of the session that needs it, record the answer
here with the date, and do not ask again.

Under autopilot, a question with no answer is not asked; its answer is marked `assumed`
(see `multi-session`, "Autopilot").

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D1 | S1 | How to run the acceptance tests? A real prompt needs a person at a terminal; `claude -p` turns an "ask" into a refusal, which still tells "ask" from "allow". Recommendation: I run what `claude -p` can show in throwaway repos in this container (a small amount of API usage), and write a short script for the cases that need a real prompt (user-level `Bash(git:*)`, `bypassPermissions`, `acceptEdits`), which you run locally. | Both (2026-11-15). |
| D2 | S1 | What stops the effort? Recommendation: stop (ADR-0006 rejected, keep the `ask` rule) if a hook "ask" does not prompt under a broad `allow` rule, or a hook "allow" gets past `deny`/`ask`. Accept in writing the gap when hooks are turned off (`disableAllHooks`, `allowManagedHooksOnly`): that is a deliberate user or admin choice. Decide `bypassPermissions` from what it does to today's `ask` rule: if that rule also does not prompt there, it is no worse. | As recommended (2026-11-15). |
| D3 | S2 | Parser in Node (start from `pre-bash-git.sh`'s, inverted to fail closed) or bash only? Recommendation: Node; Node 18+ is already a Constraint, bash cannot parse quotes reliably, and a missing `node` ends in "ask" through the wrapper. | — |
| D4 | S2 | When a timeout happens: block (`onFailure: "block"`) or nothing? Recommendation: set `onFailure: "block"`; a blocked commit is safe and can be re-run. (Verify in S1 that the field exists in this Claude Code.) | — |
| D5 | S2 | If `commit-gate.sh` is listed in `.claude/yotamake/skip`: always add the hook anyway (it then asks, since the script is missing), or add `Bash(git commit:*)` back to `ask`? Recommendation: add the `ask` rule back; skipping should mean "today's behaviour". | — |
| D6 | S2 | Where the opt-in marker lives and how it is protected. Recommendation: a file in the worktree's own git dir (`git rev-parse --git-path yotamake-commit-opt-in`), gone when the worktree is removed; the gate asks on any Bash command that names it; `.git/` is a protected path for Edit/Write (S1 checks whether Bash writes there prompt). | — |
