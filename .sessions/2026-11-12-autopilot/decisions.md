# Decisions

Questions for the user. Ask each at the start of the session that needs it, record the answer
here with the date, and do not ask again.

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D1 | S0 | Commit and merge prompts under autopilot: keep them (one keypress each) or remove them with a fail-closed hook (ADR-0006)? Recommendation: keep them now; remove later once ADR-0006's tests pass. | Keep them (2026-11-12). |
| D2 | S0 | A decision with no answer during an autopilot run: stop, or take the recommendation and flag it? Recommendation: take it and flag it. | Take the recommendation, flag it in the report (2026-11-12). |
| D3 | S0 | Keep the S0 approval of spec, plan and Design before autopilot starts? Recommendation: keep. | Keep (2026-11-12). |
| D4 | S1 | If `/simplify` and `/code-review` cannot run inside a session subagent: the main conversation runs the review on each session's diff after the subagent returns (as `simple-session`, "Review", says today), or the session subagent reviews by hand? Recommendation: the main conversation runs them. | The main conversation runs them (2026-11-12). S1's test: both run in a subagent, but `/simplify` only as a single inline pass. |
| D5 | S2 | Who commits each session: the main conversation, after the subagent returns, or the subagent? Recommendation: the main conversation, so the commit, the plan and log updates sit in one place and the subagent's report is checked first. | The main conversation (2026-11-12). |
| D6 | S2 | Mother branch name in the local setup: `<prefix>/<effort-slug>` with the project's usual prefix for the effort's main kind of change (e.g. `feat/autopilot`)? Recommendation: yes. | Yes (2026-11-12). |
| D7 | S3 | Run the new eval case `20-multi-session-autopilot-offer` (costs money, about the price of case 07 times three runs)? Recommendation: write it, run it once with `--runs 3` after the user says yes. | — |
| D8 | S2 | The folder must outlive close-out until the merge answer (F6). Ask "merge into main?" first and, on yes, delete the folder in its own commit, then bump, then merge? Recommendation: yes. | Yes (2026-11-12). |
