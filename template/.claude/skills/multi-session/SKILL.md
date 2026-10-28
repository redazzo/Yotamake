---
name: multi-session
description: Plan and run work that will not fit in one context (a review, a migration, a multi-phase refactor) as numbered sessions with a local working folder that survives /clear. Use when the user asks for such work, when a task clearly needs several branches or several context clears, or when the user says "start the next session".
---

# Multi-session work

Work that spans several contexts keeps its state in a local folder, so a fresh context can
pick it up from a few file reads instead of re-deriving it.

A session is a branch and a merge that fits in one context. A multi-session effort is a
series of sessions that together complete a task. The user can `/clear` between sessions, and
the folder survives to let the next session start quickly.

Each session follows the `simple-session` skill for branching, checks, reporting and
integration. This skill adds the working folder and the order of sessions.

## Resuming

The user resumes with: **"Read .scratchpad/<folder>/README.md and start the next session."**

1. Read that `README.md`, then `plan.md`, then the last entry in `log.md`.
2. Read only the parts of `findings.md` the current session names.
3. Start the first session in `plan.md` whose status is not `done`. Ask its questions from
   `decisions.md` before doing anything else, unless they already have answers.
4. Do not redo the analysis. Do re-check any file:line or fact you are about to act on or
   copy into a durable doc. Code moves, and the log can be wrong: a stale inventory row can
   name the wrong file and slip into a permanent record.

If the user says "start the next session" and several folders exist, list them and ask which.

## Starting a new effort

1. Create `.scratchpad/<yyyy-mm-dd>-<slug>/` (git-ignored) and copy the templates from
   `templates/` in this skill's directory. Fill them in.
2. Do the analysis once, in the first session (S0). Record what you found in `findings.md`
   with file:line references. Each finding gets an ID (F1, F2, …) and a severity.
3. Split the work into sessions in `plan.md`. Size each one to **one branch and one merge
   that fits in one context**, so a `/clear` never lands mid-change. Order them so each makes
   the next one easier (bugs first, then deletions, then refactors, docs last so they describe
   the final state).
4. Put every question for the user in `decisions.md`, tagged with the session that needs the
   answer. Give a recommendation with each. Ask at the start of that session, not all up front:
   by then the earlier sessions may have changed the question.
5. End S0 by telling the user the resume line and that it is a good point to `/clear`.

## Rules for every session

- Branch from an up-to-date main branch, as in `simple-session`. Never work on the main
  branch.
- Before proposing a commit, run the checks in CLAUDE.md's **Checks** section. Write long
  output to a log file in the folder (`s<N>-checks.log`) and report only the summary lines.
- Commit, version bump and merge only after the user says yes.
- Deploying is the user's decision, never part of a session.
- A session that changes behaviour updates the reference doc that owns it (the "Owns" table in
  `docs/README.md`) in the same branch. The close-out sweep below catches what slips through; it
  is not the place to write them.
- At the end of a session: set its status in `plan.md`, append an entry to `log.md` (what was
  done, commit hashes, what is left, anything surprising), then tell the user it is a good
  point to `/clear`.

## Closing out

The folder is disposable. Its last session moves anything worth keeping somewhere that lasts,
then the folder is deleted:

- how the system works now → the reference docs that own each changed subject (the "Owns"
  table in `docs/README.md`) and CLAUDE.md. Grep `docs/reference/` for every table, column,
  file and function the effort renamed or removed, and fix each hit. Bump `updated:` on each
  doc you change;
- what was built and why → a record in `docs/records/` (then run
  `node scripts/docs/generate-records-index.mjs`);
- follow-ups and out-of-scope findings → `docs/backlog.md`, each with a trigger to act;
- an architecturally significant decision → an ADR in `docs/decisions/` (check its bar first).

The `write-doc` skill has the format for each. Then mark every session done, write a
close-out entry in `log.md` listing what is left for the user, and ask before deleting the
folder.
