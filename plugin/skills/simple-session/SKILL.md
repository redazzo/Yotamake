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
- **Architecture** — the design a change follows: its `Modules`, `Boundaries`,
  `Shared code` and `Patterns` lines, and the accepted ADRs (step 3).

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

Look for a spec from `/yotamake:spec`: a `spec-*.md` file in `.scratchpad/` or `.sessions/`.
If one matches this change, read it now; its acceptance criteria (A1, A2, …) are what done
means. If more than one might match, ask which. If the change is too big and you offer
`multi-session`, say that the spec moves into its folder.

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

## 3. Design and reuse — before any edit

Skip this step when the change touches only docs. Otherwise read the **Architecture** section
of CLAUDE.md and decide how the change fits before you write it.

1. **Reuse first.** Before you write a new function, type, component or module, search for
   code that already does the job: first in the places **Shared code** names, then in the
   module the change touches. Reuse it, or extend it when a small change makes it fit. Write
   new code only when nothing fits, and know why. New code that more than one place will use
   goes where **Shared code** says.
2. **Fit the design.** Put the change in the module that owns it (**Modules**). Do recurring
   things the way **Patterns** and the nearby code already do them.
3. **Stop on a design conflict.** Stop before any edit and ask the user when the change
   would:
   - break a rule in **Boundaries**;
   - go against an accepted ADR (`docs/decisions/`);
   - bring in a way of doing a recurring thing (errors, config, logging, validation, data
     access, a new dependency) that **Patterns** does not list and the code does not
     already use.

   Say what conflicts and quote the rule. Give options with a recommendation, for example: a
   way that keeps the rule; changing the rule first (edit Architecture, or write a new ADR,
   which makes the work too big for one session, step 1); or dropping that part. Do this
   every time, even when the user asked for exactly that change or said not to ask. The rule
   is the project's, and changing it is a separate decision. Wait for the answer.

If the Architecture section is missing or still holds `FILL IN` placeholders, follow the
structure and patterns already in the code. Say once in the report that it is unfilled, and
that `/yotamake:setup` can fill it in.

## 4. Do the work

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

## 5. Run the checks

Run `scripts/check`. It picks the checks that match what changed, and prints one `PASS` or
`FAIL` line per check. Run it even though a pre-commit hook exists: the hook runs only the
fast checks (`--staged`), and this runs the slow ones too. If the project has no `scripts/check`, run the commands CLAUDE.md's
**Checks** section lists instead, and say in the report that the project has no single gate.

Do not add, skip or weaken a check to get a pass. Report only the summary lines.

If a check fails, fix it when the failure is yours. If it was already failing on the main
branch, say so and show the line, rather than fixing it in this branch.

## 6. Review

Skip this step when the branch changes only docs (Markdown files and `docs/`).

Otherwise review the branch's diff against the main branch in three parts:

1. **Reuse.** Run the built-in `/simplify` skill. It applies its fixes itself. Keep the
   fixes to code this branch added or changed. Undo the others by hand (not with
   `git checkout`, which would also drop your own uncommitted work) and list them in the
   report as suggestions. If `/simplify` is not available, check by hand: for each new
   function or block, search for code that already does the same, and reuse it.
2. **Design.** Read the diff against **Architecture** (step 3): a broken boundary, a clash
   with an accepted ADR, a pattern the project does not use, or logic copied from elsewhere.
   Fix what lies inside this change. A conflict you only see now gets the same stop as in
   step 3: ask before going on.
3. **Bugs.** Run the built-in `/code-review` skill at low effort. Fix each finding that is a
   real defect in this branch's change.

If any part changed code, run `scripts/check` again. A finding you judge wrong, or one
outside this branch's concern, goes in the report with one line on why you left it. If
`/code-review` is not available, say so in the report and carry on.

## 7. Stop and report

Do not commit yet. Tell the user:

- what changed, by file, in a few lines;
- for a code change, two lines: "Reused:" the existing code it reuses or extends (or
  "nothing"), and "New, because:" each new function, type or module and why nothing
  existing fit (or "nothing new"); and that the Architecture section is unfilled, if it is;
- which docs you updated, or why none needed it;
- with a spec: each criterion and how it was checked (test name or manual step), and
  whether to delete the spec file once this is merged;
- the check results (one line each);
- the review: what it found and fixed, what you left and why, or that it was skipped;
- any side-fixes and any suggestions you left out;
- the commit message you propose (Conventional Commits, `type(scope): summary`, ending with
  any attribution lines the environment asks for).

Then ask whether to commit and merge, or, if the project works through pull requests (below),
whether to commit, push and open a pull request.

## 8. On yes: commit, bump, integrate

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
