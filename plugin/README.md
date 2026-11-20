# yotamake

A development harness for Claude Code: small sessions on branches, one check command,
stop-and-ask before commit and deploy, and a docs system that stays true.

Install:

```
/plugin install yotamake --marketplace redazzo/Yotamake
```

Then run `/yotamake:setup` inside each repository to install its per-repo files
(`CLAUDE.md` sections, `scripts/check`, the pre-commit hook, the docs skeleton and settings).
Lite mode (`install.sh --lite`) leaves out the docs skeleton.

Skills:

<!-- inventory: plugin/skills/*/ names -->
- `simple-session`: one change: size check, branch, work, docs, scripts/check, stop and ask.
- `multi-session`: work too big for one session, with a working folder that survives /clear.
- `debugging`: a bug fix inside a session: reproduce, failing test, root cause, fix.
- `write-doc`: pick the doc kind, write it from its template, link it, lint it.
- `spec`: agree scope and acceptance criteria before code (manual: `/yotamake:spec`).
- `improve-architecture`: review the code's design, read-only (manual: `/yotamake:improve-architecture`).
- `release-check`: guided deploy with pre-flight and gotchas (manual: `/yotamake:release-check`).
- `new-migration`: scaffold a timestamped migration file (manual: `/yotamake:new-migration`).
- `setup`: install or refresh the per-repo files (manual: `/yotamake:setup`).
- `doctor`: check the harness works in this repo, read-only (manual: `/yotamake:doctor`).
- `drawio`: draw.io diagrams.
<!-- /inventory -->

Hooks:

<!-- inventory: plugin/hooks/*.sh -->
- `pre-edit-protect.sh`: blocks edits to protected files (.env, keys, certificates), and reads of them.
- `pre-edit-main-branch.sh`: blocks edits while the repository is on its main branch.
- `pre-bash-git.sh`: blocks --no-verify, git commit on the main branch, and a commit before the check and review.
- `post-edit-check.sh`: runs a fast per-file check after each edit.
- `post-edit-mark.sh`: logs each edit (code or doc) for the step evaluator.
- `record-event.sh`: logs review skill calls and user prompts for the step evaluator.
- `stop-check-ran.sh`: blocks the end of a turn once when scripts/check has not passed since.
- `session-upgrades.sh`: at session start, tells Claude when the repo's harness is older than the plugin.
- `lib.sh`: shared by the hooks: reads the hook input and project.conf, finds the gate files.
<!-- /inventory -->

Output style: `plain-english`.

Full documentation: [the repository README](https://github.com/redazzo/Yotamake#readme).
