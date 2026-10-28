# yotamake

A development harness for Claude Code: small sessions on branches, one check command,
stop-and-ask before commit and deploy, and a docs system that stays true.

Install:

```
/plugin install yotamake --marketplace redazzo/Yotamake
```

Then run `/yotamake:setup` inside each repository to install its per-repo files
(`CLAUDE.md` sections, `scripts/check`, the pre-commit hook, the docs skeleton and settings).

Skills: `simple-session`, `multi-session`, `write-doc`, `release-check`, `new-migration`,
`setup`, `drawio`. Hooks: protect secret files from edits; block edits on the main branch; run
a per-file check after each edit. Output style: `plain-english`.

Full documentation: [the repository README](https://github.com/redazzo/Yotamake#readme).
