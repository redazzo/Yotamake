---
name: simple-session
description: Use before editing code, tests or docs in a repository set up with the harness (it has scripts/check) — for ANY change, even a one-line fix, a rename or a typo, and also when the user already names the branch, says exactly what to change, or the environment assigns a branch. Runs the change as one session: work on that branch (or cut one from the main branch), update the doc that owns the change, run scripts/check and a review, then stop and ask before commit, version bump and merge or pull request. Use multi-session instead when the work needs several branches or several context clears. Not for questions or explanations.
---

# Simple session

A session is one branch and one merge that fits in one context. This skill is the
`multi-session` rules without the working folder: no plan, findings or log, because nothing
has to survive a `/clear`.

Project specifics live in `CLAUDE.md`, not here. This skill reads these sections:

- **Checks** — how the project's one check command works (normally `scripts/check`).
- **Branching and releases** — the main branch, branch prefixes, how to integrate (a local
  merge or a pull request), and whether code changes get a version bump.

If a section is missing or still holds `<!-- FILL IN -->` placeholders, say so once in the
report and use the defaults given below.

## 1. Check the size — before branching

Do this before any branch, edit or install. The change is **too big for one session** if any
of these hold:

- it adds or changes a database schema or migration *and* other code;
- it adds more than one new interface (an HTTP API, a CLI, a UI screen, a background job);
- it touches more than one service or package;
- it needs an ADR;
- you would want to `/clear` before finishing.

If any hold, do not branch or edit. Say in one or two sentences that it is too big for one
session and which test it fails, then offer to plan it with the `multi-session` skill. Stop
there. Otherwise carry on without comment.

If the request is ambiguous in a way that changes what you build, ask now. Do not ask about
things the code or CLAUDE.md already answer.

## 2. Branch

If the user or the environment names a branch to work on, and you are on it, stay there and
skip to step 3.

Otherwise cut a new branch:

```bash
git checkout <main-branch> && git pull --ff-only
git checkout -b <prefix>/<short-slug>
```

Default main branch: `main`. Default prefixes: `feat/`, `fix/`, `refactor/`, `perf/`,
`docs/`, `test/`, `chore/`. Never edit files on the main branch or on a release branch. If
you cannot create a branch, stop and say why, without editing anything.

If the working tree is dirty, stop and ask what to do with the changes. Do not stash or
discard them yourself.

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
If the repository has no `docs/README.md` (a lite install), there is no docs system: fix
CLAUDE.md or `README.md` where they describe the change, and put follow-ups in the report.

## 4. Run the checks

Run `scripts/check`. It picks the checks that match what changed, and prints one `PASS` or
`FAIL` line per check. Run it even though a pre-commit hook exists: the hook runs only the
fast checks (`--staged`), and this runs the slow ones too. If the project has no `scripts/check`, run the commands CLAUDE.md's
**Checks** section lists instead, and say in the report that the project has no single gate.

Do not add, skip or weaken a check to get a pass. Report only the summary lines.

If a check fails, fix it when the failure is yours. If it was already failing on the main
branch, say so and show the line, rather than fixing it in this branch.

## 5. Review

Skip this step when the branch changes only docs (Markdown files and `docs/`).

Otherwise run the built-in `/code-review` skill at low effort on the branch's diff against
the main branch. Fix each finding that is a real defect in this branch's change, then run
`scripts/check` again. A finding you judge wrong, or one outside this branch's concern, goes
in the report with one line on why you left it.

If `/code-review` is not available, say so in the report and carry on.

## 6. Stop and report

Do not commit yet. Tell the user:

- what changed, by file, in a few lines;
- which docs you updated, or why none needed it;
- the check results (one line each);
- the review: what it found and fixed, what you left and why, or that it was skipped;
- any side-fixes and any suggestions you left out;
- the commit message you propose (Conventional Commits, `type(scope): summary`, ending with
  any attribution lines the environment asks for).

Then ask whether to commit and merge, or, if the project works through pull requests (below),
whether to commit, push and open a pull request.

## 7. On yes: commit, bump, integrate

Only after the user says yes. Claude Code will also ask before `git commit`, `git merge` and
`git push` when the project's settings put them under `ask`; that is expected. Stage the files
you changed by name, not `git add -A`. If the pre-commit hook fails, fix the cause; never pass
`--no-verify` unless the user asks.

```bash
git add <files>
git commit -m "<message>"
```

If CLAUDE.md defines a version bump, code changes get one as its own commit on the branch,
using the command and file it names. Docs-only branches do not.

Then integrate the way the `Integration` line in CLAUDE.md says.

**Local merge** (the default, when the line is missing or unfilled):

```bash
git checkout <main-branch>
git merge --no-ff <branch> -m "Merge <branch> into <main-branch>"
```

Do not push or delete the branch unless the user asks.

**Pull request** (when the line says the project works through pull requests, or the
environment says to push to an assigned branch):

1. Push the branch: `git push -u origin <branch>`.
2. If a pull request for this branch is already open, stop there: the push updated it.
3. Otherwise open one against the main branch. Use the GitHub tools the environment provides,
   or `gh pr create --base <main-branch>`. If the repository has a pull request template,
   follow its headings. Title: the commit summary. Body: what changed and why, the docs
   updated, the check and review results, and any attribution lines the environment asks for.
4. If you cannot open one (no tool, no access), say so and give the branch name instead.

Do not merge the pull request yourself; that is the reviewer's or the user's call. If the
environment says not to open pull requests unless asked, push only and offer to open one.

Never deploy; that is always the user's call. Finish with one line: the merge commit hash, or
the pull request link (or the pushed branch), and the new version, if any.
