---
name: simple-session
description: Run one self-contained change (a fix, a small feature, a doc update) as a single session — branch from the main branch, do the work, update the doc that owns it, run the checks, then stop and ask before commit, version bump and merge. Use whenever the user asks for a concrete change that fits in one context, says "simple session", "do this in a session", "on a branch", or asks for a fix or feature without mentioning a plan. Use multi-session instead when the work needs several branches or several context clears.
---

# Simple session

A session is one branch and one merge that fits in one context. This skill is the
`multi-session` rules without the working folder: no plan, findings or log, because nothing
has to survive a `/clear`.

Project specifics live in `CLAUDE.md`, not here. This skill reads these sections:

- **Checks** — the commands to run before proposing a commit.
- **Branching and releases** — the main branch, branch prefixes, how to integrate, and
  whether code changes get a version bump.

If a section is missing or still holds `<!-- FILL IN -->` placeholders, say so once in the
report and use the defaults given below.

## 1. Check the size

Before touching anything, judge whether the change fits in one context and one branch. Signs
it does not: it needs a schema migration *and* several services *and* a doc rewrite, or you
would want to `/clear` halfway. If so, say so in one or two sentences and offer the
`multi-session` skill instead. Otherwise carry on without comment.

If the request is ambiguous in a way that changes what you build, ask now. Do not ask about
things the code or CLAUDE.md already answer.

## 2. Branch

```bash
git checkout <main-branch> && git pull --ff-only
git checkout -b <prefix>/<short-slug>
```

Default main branch: `main`. Default prefixes: `feat/`, `fix/`, `refactor/`, `perf/`,
`docs/`, `test/`, `chore/`. Never work directly on the main branch or on a release branch.

If the working tree is dirty, stop and ask what to do with the changes. Do not stash or
discard them yourself. If the environment has already put you on an assigned branch, use
that branch instead of cutting a new one.

## 3. Do the work

Follow CLAUDE.md. Keep to the one concern the branch is named for. The trivial side-fix
policy (CLAUDE.md, Conventions) applies: fix a typo or stale comment you pass, and note it in
the report. Anything with behavioural reach that is outside the task goes in the report as a
suggestion, not in the diff.

If the change alters how something works, update the reference doc that owns it in the same
branch. The "Owns" table in `docs/README.md` names it. Also fix CLAUDE.md if it describes the
thing you changed, and bump `updated:` on each doc you edit. A follow-up you are not doing goes
in `docs/backlog.md` with a trigger to act. An architecturally significant decision needs an
ADR in `docs/decisions/`; ask before writing one. The `write-doc` skill covers the formats.

## 4. Run the checks

Run every command in CLAUDE.md's **Checks → Always** list, plus each **Checks → When the diff
touches** entry that matches your diff. For a docs-only branch, the docs check alone is
enough (default: `node scripts/docs/lint-docs.mjs`).

Write long output to a log file in the scratchpad (or `/tmp` if there is none) and report only
the summary lines.

If a check fails, fix it when the failure is yours. If it was already failing on the main
branch, say so and show the line, rather than fixing it in this branch.

## 5. Stop and report

Do not commit yet. Tell the user:

- what changed, by file, in a few lines;
- which docs you updated, or why none needed it;
- the check results (one line each);
- any side-fixes and any suggestions you left out;
- the commit message you propose (Conventional Commits, `type(scope): summary`, ending with
  any attribution lines the environment asks for).

Then ask whether to commit and merge.

## 6. On yes: commit, bump, integrate

Only after the user says yes. Stage the files you changed by name, not `git add -A`.

```bash
git add <files>
git commit -m "<message>"
```

If CLAUDE.md defines a version bump, code changes get one as its own commit on the branch,
using the command and file it names. Docs-only branches do not.

Then integrate the way CLAUDE.md says. The default is a local merge commit:

```bash
git checkout <main-branch>
git merge --no-ff <branch> -m "Merge <branch> into <main-branch>"
```

If CLAUDE.md says the project works through pull requests, push the branch instead and offer
to open one.

Do not push, delete the branch or deploy unless the user asks. Deploying is always their
call. Finish with one line: the merge commit hash (or the pushed branch) and the new version,
if any.
