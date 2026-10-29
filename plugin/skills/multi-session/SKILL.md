---
name: multi-session
description: Plan and run work that will not fit in one context (a review, a migration, a multi-phase refactor) as numbered sessions with a working folder that survives /clear. Use when the user asks for such work, when a task clearly needs several branches or several context clears, or when the user says "start the next session".
---

# Multi-session work

Work that spans several contexts keeps its state in a working folder, so a fresh context can
pick it up from a few file reads instead of re-deriving it.

A session is a branch and a merge that fits in one context. A multi-session effort is a
series of sessions that together complete a task. The user can `/clear` between sessions, and
the folder survives to let the next session start quickly.

Each session follows the `simple-session` skill for branching, checks, review, reporting and
integration. This skill adds the working folder and the order of sessions.

## Where the folder lives, and how branches are used

Two setups. Pick one in S0 and write it in the folder's `README.md`.

- **Local** (the default): a git-ignored folder, `.scratchpad/<yyyy-mm-dd>-<slug>/`, and one
  branch per session, cut from the main branch and merged (or opened as a pull request) at
  the end of the session.
- **Committed**: use this when the work runs in an ephemeral environment (a cloud container
  that is thrown away between sessions), when the environment assigns one branch to work on,
  or when other people need to follow the work. The folder is committed at
  `.sessions/<yyyy-mm-dd>-<slug>/`, outside `docs/` so the docs linter does not treat it as
  docs. If the environment assigns a branch, every session is one or more commits on that
  branch instead of a branch of its own; push after each session so the next container
  finds the work.

If it is not clear which applies, ask in S0 and record the answer in `decisions.md`.

## Resuming

The user resumes with: **"Read <folder>/README.md and start the next session."**

1. In a committed setup, first make sure you are on the effort's branch with its latest
   commits (`git pull`), since the folder lives there.
2. Read that `README.md`, then `plan.md`, then the last entry in `log.md`.
3. Read only the parts of `findings.md` the current session names.
4. Start the first session in `plan.md` whose status is not `done`. Ask its questions from
   `decisions.md` before doing anything else, unless they already have answers.
5. Do not redo the analysis. Do re-check any file:line or fact you are about to act on or
   copy into a durable doc. Code moves, and the log can be wrong: a stale inventory row can
   name the wrong file and slip into a permanent record.

If the user says "start the next session" without naming a folder, look in `.scratchpad/`
and `.sessions/`. If several folders exist, list them and ask which. A `spec-*.md` file
there is a standalone spec from `/yotamake:spec`, not an effort.

## Starting a new effort

1. Create the folder (see above) and copy the templates from `templates/` in this skill's
   directory. Fill them in, including the setup and the resume line in `README.md`. Copy
   `spec.md` only when the effort builds a new feature or changes behaviour users see; a
   review, a migration or a refactor leaves it out. If the user already wrote one with
   `/yotamake:spec` (a `spec-*.md` file in `.scratchpad/` or `.sessions/`), move it into the
   folder as `spec.md` instead, and move its open questions into `decisions.md`.
2. Do the analysis once, in the first session (S0). Record what you found in `findings.md`
   with file:line references. Each finding gets an ID (F1, F2, …) and a severity. With a
   spec, agree it first: ask the questions that change scope or a criterion, one at a time,
   write the acceptance criteria (A1, A2, …, rules in the `spec` skill, step 3), and get the
   user's approval before writing `plan.md`. Questions about how to build it wait in
   `decisions.md` for the session that needs them (step 5).
3. If the effort changes code, fill in the Design section of `plan.md` before cutting
   sessions. Read the **Architecture** section of CLAUDE.md (and accepted ADRs) and the code,
   then write: the modules touched, the existing code to reuse or extend, any new
   interfaces, and the boundaries and constraints at risk. Any plan that would break a
   boundary or a constraint, or go against an ADR, is raised as a question now, as in `simple-session`, step 3. Agree the
   Design section with the user before S1. Each session's design step then checks its work
   against it.
4. Split the work into sessions in `plan.md`. Size each one to **one branch and one merge
   (or, on an assigned branch, one set of commits) that fits in one context**, so a `/clear`
   never lands mid-change. Order them so each makes
   the next one easier (bugs first, then deletions, then refactors, docs last so they describe
   the final state). With a spec, each session names the criteria it delivers, and every
   criterion is in some session.
5. Put every question for the user in `decisions.md`, tagged with the session that needs the
   answer. Give a recommendation with each. Ask at the start of that session, not all up front:
   by then the earlier sessions may have changed the question.
6. End S0 by telling the user the resume line and that it is a good point to `/clear`.

## Rules for every session

- Branch from an up-to-date main branch, as in `simple-session`, or stay on the assigned
  branch in a committed setup. Never work on the main branch.
- Before proposing a commit, run `scripts/check` (see `simple-session`, step 5). Save its
  output to `s<N>-checks.log` in the folder and report only the summary lines.
- Commit, version bump, push and merge only after the user says yes. In a committed setup,
  commit the folder's updates with the session's work.
- Deploying is the user's decision, never part of a session.
- A session that changes behaviour updates the reference doc that owns it (the "Owns" table in
  `docs/README.md`) in the same branch. The close-out sweep below catches what slips through; it
  is not the place to write them.
- At the end of a session: set its status in `plan.md`, append an entry to `log.md` (what was
  done, commit hashes, what is left, anything surprising), then tell the user it is a good
  point to `/clear`. In a committed setup, commit and push those updates first.

## Closing out

The folder is disposable. Its last session moves anything worth keeping somewhere that lasts,
then the folder is deleted:

- how the system works now → the reference docs that own each changed subject (the "Owns"
  table in `docs/README.md`) and CLAUDE.md. Grep `docs/reference/` for every table, column,
  file and function the effort renamed or removed, and fix each hit. Bump `updated:` on each
  doc you change. If there is a `spec.md`, check each criterion is met, and put the behaviour
  it describes in those docs, not in a copy of the spec;
- what was built and why → a record in `docs/records/` (then run
  `node scripts/docs/generate-records-index.mjs`);
- follow-ups and out-of-scope findings → `docs/backlog.md`, each with a trigger to act;
- an architecturally significant decision → an ADR in `docs/decisions/` (check its bar first).

The `write-doc` skill has the format for each. A repository with no `docs/README.md` (a lite
install) has none of these: move what lasts into CLAUDE.md or `README.md`, and list
follow-ups for the user in the close-out entry. Then mark every session done, write a
close-out entry in `log.md` listing what is left for the user, and ask before deleting the
folder. A committed folder is deleted in a commit of its own.
