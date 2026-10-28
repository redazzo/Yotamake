# CLAUDE.md

This repository is the Yotamake harness, not a project that uses it. `README.md` explains
what it is.

- `template/` is what `install.sh` copies into a target repo. Edit the harness there.
- Keep `template/` generic. Anything specific to one stack or project belongs in the target's
  `CLAUDE.md`, as a `FILL IN` placeholder in `template/CLAUDE.md`, not in a skill.
- A skill that needs a project fact names the `CLAUDE.md` section it reads. If you rename a
  section in `template/CLAUDE.md`, update every skill that names it, and the table in
  `README.md`.
- Before committing, test with a scratch repo:

  ```bash
  ./install.sh <scratch-repo>
  cd <scratch-repo> && node scripts/docs/lint-docs.mjs
  ```

  For hook changes, pipe a fake tool call into the hook, e.g.
  `echo '{"tool_input":{"file_path":"/x/.env"}}' | bash .claude/hooks/pre-edit-protect.sh`.
- Style for skills and docs: plain English, short sentences (see
  `template/.claude/output-styles/plain-english.md`).
