# Decisions

Questions for the user. Ask each at the start of the session that needs it, record the answer
here with the date, and do not ask again.

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D1 | S0 | On a boundary or ADR conflict: always stop, or only without an ADR? Recommendation: always stop. | Always stop (2026-10-29) |
| D2 | S0 | Fold the method into existing skills, or a new `design` skill? Recommendation: fold in. | Fold in (2026-10-29) |
| D3 | S0 | Add boundary and duplicate-code placeholders to `scripts/check`? | Yes (2026-10-29) |
| D4 | S0 | All in this effort, or skills first and evals later? | All of it (2026-10-29) |
| D5 | S1 | Names of the Architecture lines: `Modules`, `Boundaries`, `Shared code`, `Patterns`. Recommendation: these four. | These four (2026-10-29) |
| D6 | S2 | Use the built-in `/simplify` in the review for reuse? It applies fixes itself. Recommendation: yes, keep only fixes inside the branch's concern, and fall back to a manual check if it is missing. | Yes (2026-10-29) |
| D7 | S3 | Run the new eval cases (13, 14) and re-run 02 and 03, since `simple-session` changed, at 3 runs each? Costs money; my rough guess is a few dollars. Recommendation: yes. | Yes, all four (2026-10-29) |
| D8 | S4 | Version: 0.8.0 → 0.9.0 (new behaviour, not breaking). Recommendation: 0.9.0. | — |
