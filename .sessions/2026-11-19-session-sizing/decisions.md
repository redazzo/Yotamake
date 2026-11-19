# Decisions

Questions for the user. Ask each at the start of the session that needs it, record the answer
here with the date, and do not ask again.

Under autopilot, a question with no answer is not asked; its answer is marked `assumed`
(see `multi-session`, "Autopilot").

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D0 | S0 | Include a lighter middle tier (one branch, step list, commit per step, no folder)? Recommendation: leave it out; backlog entry. | Leave it out; backlog entry (user, 2026-11-19). |
| D6 | S0 | Run the remaining sessions under autopilot? | Yes: user approved S0 without turning it off (2026-11-19). Spec and plan approved the same day. |
| D1 | S1 | Write a new ADR for the new session definition? Recommendation: yes, ADR-0011, since the definition sits in about ten files and gates a skill (F14). No amendment to ADR-0007: it still holds. | assumed (2026-11-19): yes, ADR-0011, written as Proposed for the user to accept at the end. |
| D2 | S2 | Where does the limit live? Recommendation: a bold line `**Session size:**` with a filled default in **Branching and releases**, like `**Test-first:**` (F9, F10); not a new `##` section, not in `project.conf` (no hook reads it). | assumed (2026-11-19): a bold `**Session size:**` line with a filled default in **Branching and releases**. |
| D3 | S3 | Should a hook warn when the diff passes the limit? Recommendation: no, skill text only for now; a backlog entry for a non-blocking PostToolUse warning (F12, ADR-0010 would need a new kind of rule). | assumed (2026-11-19): no hook; skill text only, plus a backlog entry. |
| D4 | S2 | Default limit. Recommendation: one diff of at most about 400 changed lines or 15 files, not counting lockfiles and generated files. This is a judgment call: review guidance commonly cites a few hundred lines; I have not measured it for model reviewers. | assumed (2026-11-19): about 400 changed lines or 15 files, not counting lockfiles and generated files. |
| D5 | S3 | Keep the heading "Check the size"? Recommendation: yes, so pointers by name stay valid (F11). | assumed (2026-11-19): keep "Check the size". |
| D7 | S2 | The three `CLAUDE.md` copies: restate the new definition, or point to the skill? Recommendation: point to `simple-session`, "Check the size" (S2's review: one owner per subject; no upgrade step for each later rewording). This reads A1 as "no copy states a different definition". | assumed (2026-11-19): point to the skill. |
