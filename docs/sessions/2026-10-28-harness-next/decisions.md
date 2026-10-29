# Decisions

Questions for the user. Ask each at the start of the session that needs it, record the answer
here with the date, and do not ask again.

| ID | Session | Question (with recommendation) | Answer |
|---|---|---|---|
| D0 | S0 | Where does the working folder live, and how are branches used? Recommendation: commit it under `docs/sessions/`; Yotamake sessions as separate commits on the assigned branch. | 2026-10-28: as recommended. |
| D1 | S1 | If the test shows a broad `allow` beats `ask`, what should the installer do? Recommendation: warn and list the overriding `allow` rules; do not remove them. | 2026-10-28: as recommended. Moot: the S1 test showed `ask` wins, so no warning is needed. |
| D2 | S3 | How should the installer treat a repo that has its own docs scripts? Recommendation: an opt-out file, `.claude/yotamake/skip`, listing managed paths the installer must not install; that repo's `scripts/check` calls its own linter. | 2026-10-28: as recommended. |
| D3 | S4 | Video-vault's CLAUDE.md headings differ from what the skills read. Recommendation: rename its headings (Checks added; Branching and releases; Migrations; Deploying; Conventions), keep the content, and fix the links that point at the old anchors. The alternative is teaching every skill aliases. | 2026-10-28: as recommended. |
| D4 | S4 | Branch name in video-vault, and push access for this session. Recommendation: `chore/yotamake-harness`, with push access granted. | 2026-10-28: as recommended. |
| D5 | S4 | Should video-vault's pre-commit run the full gate? Recommendation: yes; its whole pre-flight is about 12 s. | 2026-10-28: as recommended. |
| D6 | S5 | Video-vault's local skill copies. Recommendation: delete all five; the plugin provides three, and the facts in `create-migration` and `deploy-check` move into CLAUDE.md. | 2026-10-29: as recommended. |
| D7 | S7 | Lite mode shape. Recommendation: an `install.sh --lite` flag that installs `CLAUDE.md`, `scripts/check`, the hook config and settings, but no docs skeleton. | 2026-10-29: as recommended. Icon (F4): skip for now. |
| D8 | S8 | Eval budget. Recommendation: approve about $8 (new cases piloted once, then the full suite with the baseline arm). | 2026-10-29: as recommended. |
| D9 | S9 | Stale-docs check: build it, or design only? Recommendation: design only in S9; build later if the design holds up. | — |
| D10 | S6 | When does the review step run? Recommendation: code changes only, using the built-in `/code-review` at low effort; docs-only branches skip it. | 2026-10-29: as recommended. |
