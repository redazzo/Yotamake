# CLAUDE.md

This repository is the Yotamake harness: a Claude Code plugin and its marketplace, not a
project that uses it. `README.md` explains what it is.

- `plugin/` is the plugin. `.claude-plugin/marketplace.json` at the root lists it.
- `plugin/template/` is what `plugin/install.sh` copies into a target repo. Project-owned
  files there are copied only when missing; harness-owned ones (listed in `install.sh` as
  `managed`) are refreshed on every run.
- Keep the plugin generic. Anything specific to one stack or project belongs in the target's
  `CLAUDE.md` or `scripts/check`, as a `FILL IN` placeholder in the template, not in a skill.
- A skill that needs a project fact names the `CLAUDE.md` section it reads. If you rename a
  section in `plugin/template/CLAUDE.md`, update every skill that names it, the eval fixture's
  `CLAUDE.md`, and `README.md`.
- When you change a project-owned template file (anything in `plugin/template/` not listed as
  `managed`), add an entry to `plugin/reference/upgrades.md`: how to check it is applied, and
  how to apply it. Older installs get it from there.
- When you change the plugin, bump `version` in both `plugin/.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json`.

## Before committing

```bash
claude plugin validate plugin --strict
claude plugin validate . --strict
./plugin/install.sh <scratch-repo> && (cd <scratch-repo> && scripts/check --all)
```

For hook changes, pipe a fake tool call into the hook, e.g.
`echo '{"tool_input":{"file_path":"/x/.env"}}' | bash plugin/hooks/pre-edit-protect.sh`.

For skill changes, run the affected eval cases (they cost money; ask first):

```bash
cd plugin && claude plugin eval . --case <name> --runs 3 --ablation none \
  --scaffold --trust-plugin --allow-tools Bash Write Edit --no-publish
```

Style for skills and docs: plain English, short sentences (see
`plugin/output-styles/plain-english.md`).
