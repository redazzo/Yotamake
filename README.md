# Yotamake

A generic development harness for Claude Code. It gives any repository the same working
method: small sessions on branches, checks before every commit, nothing committed or deployed
without a "yes", and a docs system that stays true.

It started as the `.claude/` setup and docs rules of a single application project. Those
were tied to one stack (pnpm, Supabase, Cloudflare). Here the method lives in the skills, and
everything project-specific lives in named sections of the target project's `CLAUDE.md`.

## Install

```bash
./install.sh /path/to/your/repo          # keeps any file that already exists
./install.sh /path/to/your/repo --force  # overwrites
```

Then, in the target repo:

1. Fill in each `FILL IN` comment in `CLAUDE.md`. Delete the **Migrations** or **Deploying**
   section if the project has none.
2. Uncomment the lines in `.claude/hooks/post-edit-checks.conf` that fit the stack.
3. Check `.claude/hooks/protected-paths.conf` covers your secret files.
4. Run `node scripts/docs/lint-docs.mjs`.

If the repo already has docs with broken links, run
`node scripts/docs/lint-docs.mjs --update-baseline` once to record them as known debt. After
that the linter fails on new problems and on fixed ones that are still listed.

## What you get

```
CLAUDE.md                         project facts the skills read, by section name
.claude/
  settings.json                   hooks, output style, a few read-only permissions
  hooks/
    pre-edit-protect.sh           blocks edits to files in protected-paths.conf
    protected-paths.conf          .env files, keys, certificates by default
    post-edit-check.sh            runs a per-file check after each edit
    post-edit-checks.conf         glob → command map (all commented out)
  output-styles/plain-english.md  short sentences, plain words
  skills/
    simple-session/               one change: branch, work, docs, checks, stop and ask
    multi-session/                work across several contexts, with a working folder
    write-doc/                    pick the doc kind, write it, link it, lint it
    release-check/                guided deploy with pre-flight and gotchas (manual only)
    new-migration/                scaffold a timestamped migration file (manual only)
    drawio/                       draw.io diagrams, unchanged from the source
docs/
  README.md                       the docs rulebook and index
  backlog.md                      the one register of open work
  decisions/README.md             ADR register and template
  records/README.md               generated index of dated work records
  reference/ guides/ backlog/     empty, ready to fill
scripts/docs/
  lint-docs.mjs                   broken links, orphans, front-matter, stale index
  generate-records-index.mjs      rebuilds docs/records/README.md
```

`release-check` and `new-migration` set `disable-model-invocation`, so they run only when you
type `/release-check` or `/new-migration`.

## How the pieces fit

**Skills hold the method. `CLAUDE.md` holds the facts.** Each skill names the `CLAUDE.md`
section it reads:

| Skill | Reads |
|---|---|
| `simple-session`, `multi-session` | **Checks**, **Branching and releases**, **Conventions** |
| `release-check` | **Deploying**, plus **Checks**, **Migrations**, **Branching and releases** |
| `new-migration` | **Migrations** |
| `write-doc` | `docs/README.md` |

If a section is missing or unfilled, the skill says so and either uses a stated default or
stops and asks. It does not guess a deploy or migration command.

**The session model.** A session is one branch and one merge that fits in one context.
`simple-session` runs one. If the work is bigger, it says so and offers `multi-session`,
which keeps `plan.md`, `findings.md`, `decisions.md` and `log.md` in a git-ignored
`.scratchpad/<date>-<slug>/` folder. You `/clear` between sessions and resume with:
"Read .scratchpad/<folder>/README.md and start the next session." At the end, anything
worth keeping moves into the docs and the folder is deleted.

**The stop points.** Skills stop and ask before commit, version bump, merge and deploy.
Deploying is always the user's call.

**The docs model.** Four kinds, each maintained differently: reference (corrected in
place), guides (corrected in place), decisions (never edited, only superseded) and records
(written once). When they disagree: code > decisions > reference > records. Each subject has
one owning doc, named in the "Owns" table in `docs/README.md`. The linter keeps links
working and every doc reachable from the index.

**The hooks.** Both read the tool call as JSON on stdin. Exit code 2 blocks an edit
(pre-edit) or shows a failed check to Claude so it can fix it (post-edit).

## Requirements

`bash`, `python3` (hooks parse JSON with it), `git`, and Node 18+ for the docs scripts. The
docs scripts have no npm dependencies.

## Changes from the source

- Project details (pnpm commands, Supabase, Cloudflare deploy order, version-bump file) moved
  out of the skills into `CLAUDE.md` sections.
- `deploy-check` became `release-check`; `create-migration` became `new-migration`.
- `write-doc` is new. It condenses the source's `docs/README.md` rules into a skill with
  templates.
- The source hooks read the file path from a `CLAUDE_TOOL_INPUT` environment variable. As far
  as I know, Claude Code sends hook input as JSON on stdin, so those hooks may never have
  fired. These read stdin. The lint hook now exits 2 on failure so Claude sees the output.
- The `.env.local` block became a configurable list of protected paths.
- The `simple-session` evals were left out. Their cases and graders refer to that project's
  files and features.
