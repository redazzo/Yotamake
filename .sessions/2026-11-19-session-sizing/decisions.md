# Decisions

Questions for the user. Ask each at the start of the session that needs it, record the answer
here with the date, and do not ask again.

Under autopilot, a question with no answer is not asked; its answer is marked `assumed`
(see `multi-session`, "Autopilot").

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D0 | S0 | Include a lighter middle tier (one branch, step list, commit per step, no folder)? Recommendation: leave it out; backlog entry. | Leave it out; backlog entry (user, 2026-11-19). |
| D1 | S1 | Write a new ADR for the new session definition? Recommendation: yes, ADR-0011, since the definition sits in about ten files and gates a skill (F14). No amendment to ADR-0007: it still holds. | — |
| D2 | S2 | Where does the limit live? Recommendation: a bold line `**Session size:**` with a filled default in **Branching and releases**, like `**Test-first:**` (F9, F10); not a new `##` section, not in `project.conf` (no hook reads it). | — |
| D3 | S3 | Should a hook warn when the diff passes the limit? Recommendation: no, skill text only for now; a backlog entry for a non-blocking PostToolUse warning (F12, ADR-0010 would need a new kind of rule). | — |
| D4 | S2 | Default limit. Recommendation: one diff of at most about 400 changed lines or 15 files, not counting lockfiles and generated files. This is a judgment call: review guidance commonly cites a few hundred lines; I have not measured it for model reviewers. | — |
| D5 | S3 | Keep the heading "Check the size"? Recommendation: yes, so pointers by name stay valid (F11). | — |
