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

Before starting or resuming an effort, check for harness upgrades once per conversation, as
in `simple-session`, "Harness upgrades". An upgrade applied then gets its own branch and
merge, outside the effort's sessions and its `plan.md`.

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
   commits (`git switch <branch> && git pull --ff-only`), since the folder lives there.
2. Read that `README.md`, then `plan.md`, then the last entry in `log.md`, then `docs.md`.
   An effort started before the ledger existed has no `docs.md`: copy the template now, and
   fill it from `log.md` and the diffs of the sessions already done, before going on.
3. Read only the parts of `findings.md` the current session names.
4. Start the first session in `plan.md` whose status is not `done` and whose `Needs:`
   sessions are all `done`. Skip one marked `in progress` in another worktree (see "Running
   sessions in parallel"). Ask its questions from `decisions.md` before doing anything else,
   unless they already have answers. If the user resumes autopilot, follow "Resuming
   autopilot" instead.
5. Do not redo the analysis. Do re-check any file:line or fact you are about to act on or
   copy into a durable doc. Code moves, and the log can be wrong: a stale inventory row can
   name the wrong file and slip into a permanent record.

If the user says "start the next session" without naming a folder, use the efforts listed
in your session-start context (the project's `session-context.sh` names each folder and its
next session). Without that list, look in `.scratchpad/` and `.sessions/`. If there are
several efforts, list them and ask which. A `spec-*.md` file there is a standalone spec from
`/yotamake:spec`, not an effort.

When the context lists an effort and the user asks for work that looks like its next
session, offer to resume that effort instead of starting a new one.

## Starting a new effort

1. Create the folder (see above) and copy the templates from `templates/` in this skill's
   directory. Fill them in, including the setup and the resume line in `README.md`. Copy
   `spec.md` only when the effort builds a new feature or changes behaviour users see; a
   review, a migration or a refactor leaves it out. If the user already wrote one with
   `/yotamake:spec` (a `spec-*.md` file in `.scratchpad/` or `.sessions/`), move it into the
   folder as `spec.md` instead, and move its open questions into `decisions.md`. Always copy
   `docs.md`, the docs ledger (see the rules below); it starts with no rows. Leave out
   `report.md`: only autopilot uses it, at the end.
2. Do the analysis once, in the first session (S0). Record what you found in `findings.md`
   with file:line references. Each finding gets an ID (F1, F2, …) and a severity. With a
   spec, first ask the questions that change scope or a criterion, one at a time, and wait for
   each answer. Then write the acceptance criteria (A1, A2, …) and go on to `plan.md` in the
   same turn; the user approves the spec and the plan together at the end of S0 (step 6).
   The rules for criteria are in `spec`, "Write `spec.md`". Questions about how to build it
   wait in `decisions.md` for the session that needs them (step 5).

   **Hand the reading to subagents** when it spans more than a few files: this skill asks
   you to. Split it by area (a module, a set of skills, the tests) and start one built-in
   `Explore` agent per area, or `general-purpose` when the area needs a command run. Start
   them in one message so they run at once. Each brief says what the effort is for, the area
   and the questions to answer, and asks for findings with file:line references and a
   suggested severity, not file contents. The agents only read. You write `findings.md` and
   the plan from their reports. Re-read a file:line yourself only when the finding changes
   the plan and you doubt it; for anything else, send that agent a follow-up question.
   Without the Agent tool, or for a small area, read it yourself.
3. If the effort changes code, fill in the Design section of `plan.md` before cutting sessions.
   Read the **Architecture** section of CLAUDE.md (and accepted ADRs) and the code, then write:
   the style the new parts follow, the modules touched, the existing code to reuse or extend,
   any new interfaces, and the boundaries and constraints at risk. Any plan that would break a
   boundary or a constraint, step outside the Style, or go against an ADR, is raised as a
   question now, as in `simple-session`, "Design and reuse". Agree the Design section with
   the user before S1 (step 6). Each session's design step then checks its work against it.
4. Split the work into sessions in `plan.md`. Size each one to **one branch and one merge
   (or, on an assigned branch, one set of commits) that fits in one context**, so a `/clear`
   never lands mid-change. Order them so each makes
   the next one easier (bugs first, then deletions, then refactors, docs last so they describe
   the final state). With a spec, each session names the criteria it delivers, and every
   criterion is in some session. Give each session a `Needs:` line naming the sessions it
   depends on (`Needs: S1, S2`, or `Needs: none`), and list the files it will change when
   another session could run beside it.
5. Put every question for the user in `decisions.md`, tagged with the session that needs the
   answer. Give a recommendation with each. Ask at the start of that session, not all up front:
   by then the earlier sessions may have changed the question.
6. End S0 with one message: a summary of the spec (if any) and the plan with its Design
   section, a request to approve them before S1, the resume line, and that it is a good point
   to `/clear` once they are approved. Write `spec.md` and `plan.md` before this message, so
   the user approves files, not a draft in the chat. In the same message, offer autopilot as
   the other way on: approve and say "run autopilot", and the remaining sessions run without
   them, ending with one report and one merge question (see "Autopilot"). Start nothing on
   autopilot until they choose it.

## Rules for every session

Under autopilot, "Autopilot" overrides these where it says so.

- Branch from an up-to-date main branch, as in `simple-session`, or stay on the assigned
  branch in a committed setup. Never work on the main branch.
- Before proposing a commit, run `scripts/check` (see `simple-session`, "Run the checks").
  Save its output to `s<N>-checks.log` in the folder and report only the summary lines.
- Commit, version bump, push and merge only after the user says yes. In a committed setup,
  commit the folder's updates with the session's work. The one exception is a worktree
  commit in an effort that opted in (see "Running sessions in parallel").
- Deploying is the user's decision, never part of a session.
- A session that changes behaviour updates the reference doc that owns it (the "Owns" table in
  `docs/README.md`) in the same branch. The close-out sweep below catches what slips through; it
  is not the place to write them.
- Keep the docs ledger, `docs.md`, as you go, not from memory at the end. Before the report
  (`simple-session`, "Stop and report"), add a row for every behaviour, rule, interface,
  config or command this session changed: the doc that owns it, and `done`, `open` or `none`.
  Also add every name this session renamed or removed, any follow-up for the backlog, any
  decision that may need an ADR, and a line for the record. A doc update you put off is an
  `open` row, never just a line in `log.md`. The report's docs line names the rows this
  session added.
- At the end of a session: set its status in `plan.md`, append an entry to `log.md` (what was
  done, commit hashes, what is left, anything surprising), check `docs.md` is up to date, then
  tell the user it is a good point to `/clear`. In a committed setup, commit and push those
  updates first.

## Running sessions in parallel

Two sessions may run at the same time, each in its own git worktree with its own Claude Code
conversation (the harness's ADR-0005 has the reasons). Only when all of these hold:

- the effort uses the local setup, not a committed folder;
- every session each one needs (its `Needs:` line) is `done`;
- they change different files.

When the user wants a session to run beside the current one, start it like this:

1. From the main worktree, on an up-to-date main branch, add the worktree as a sibling
   folder on the session's branch: `git worktree add ../<repo>-s<N> -b <prefix>/<slug>`.
2. Do the project's worktree setup there: the `Worktree setup` line in CLAUDE.md, **Branching
   and releases** (copy `.env`, install dependencies). If the line is missing, say so and
   ask the user what the checks need; do not guess.
3. Set the session's status in `plan.md` to `in progress (worktree ../<repo>-s<N>)`.
4. Give the user the command to open Claude Code there (`cd ../<repo>-s<N> && claude`) and a
   resume line with the folder's absolute path: "Read <absolute path>/README.md and start
   S<N>." The working folder stays in the main worktree; the new one has no copy, since it is
   git-ignored.

Inside a worktree session:

- The branch is already cut: skip the cut (`simple-session`, "Branch").
- Edit only your own `## S<N>` section of `plan.md`. Only append to `log.md` and `docs.md`;
  never rewrite another session's rows. If an edit fails because the file changed, read it
  again and redo the edit.
- **Commits.** If the effort opted in to worktree commits (a row in `decisions.md` saying
  so), commit on the session's branch as soon as the checks and the review pass, then report.
  Claude Code still prompts for each commit. Without that row, stop and ask as usual.
  Merge, push, rebase, `reset --hard`, tag and the release always keep their stop.

Merging, one branch at a time:

1. In the worktree, if the main branch has moved since the branch was cut, merge it into the
   branch (`git merge <main-branch>`), fix any conflict, and run `scripts/check` again.
2. Then do the project's release steps (CLAUDE.md, **Branching and releases**), never
   earlier, so two branches do not claim the same version.
3. Merge into the main branch from the main worktree, as `simple-session`, "On yes: commit,
   bump, integrate" says (`git -C <main worktree> merge --no-ff <branch>` works from the
   worktree).
4. After the merge, remove the worktree: `git worktree remove ../<repo>-s<N>`. Delete the
   branch only if the user asks.

## Autopilot

Autopilot runs every session after S0 without the user, one after another, on one mother
branch, then writes one report and asks one question: merge. ADR-0007 has the reasons. Each
session still does the `simple-session` work, checks and review; what goes is the stop, the
report and the `/clear` between sessions. Every `git commit` and `git merge` still prompts,
and autopilot never pushes, merges into the main branch, tags or deploys without a yes.

**Turning it on.** Only the user turns it on: when they answer the S0 message (step 6 of
"Starting a new effort"), or later, with the line in "Resuming autopilot". When they do:

1. Write `Autopilot: on (<yyyy-mm-dd>), mother branch <branch>.` under **Setup** in the
   folder's `README.md`, and a row in `decisions.md` saying the user chose it.
2. Pick the mother branch. If the environment assigns a branch, that branch is the mother
   branch. Otherwise cut one from an up-to-date main branch, as in `simple-session`,
   "Branch", named `<prefix>/<effort-slug>` with the project's prefix for the effort's main
   kind of change (**Branching and releases**). No session gets a branch of its own.

**Each session.** Pick the first session in `plan.md` not `done` whose `Needs:` sessions are
all `done`. Then, in the main conversation:

1. **Decisions.** For each of the session's questions in `decisions.md` with no answer, take
   the recommendation and write `assumed (<yyyy-mm-dd>): <the recommendation>` as the answer.
   The final report lists every `assumed` row.
2. **Start the session.** Set its status in `plan.md` to `in progress`. Start one built-in
   `general-purpose` agent in the foreground (so its permission prompts reach the user) with
   the brief below. Its fresh context stands in for `/clear`, and its reading stays out of
   the main conversation.
3. **Pause, if it says so.** If the agent returns `PAUSE`, write the reason and what is done
   in `log.md`, and ask the user. Record the answer in `decisions.md`, then send it to the
   paused agent so it carries on. If that agent can no longer be reached, start a new one
   with the brief, adding one line: what was settled. If the user would rather stop the run
   here, the session stays `in progress` for "Resuming autopilot".
4. **Review.** Run `scripts/check`, saving its output as "Rules for every session" says.
   Then run the review as `simple-session`, "Review", says, on this session's uncommitted
   diff, not the whole mother branch: the docs-only and trivial tests apply to that diff,
   and the design read's brief uses `git diff HEAD`. A conflict the design read finds pauses
   as above, and so does a check that still fails after two fix attempts.
5. **Commit.** Set the session's status in `plan.md` to `done` and append its `log.md`
   entry, with what the review found, fixed and left; the report is built from these
   entries. Commit on the mother branch as `simple-session`, "On yes: commit, bump,
   integrate", says, with the folder's updates in a committed setup and `(S<N>)` at the end
   of the summary. No version bump and no merge yet.
6. Go on to the next session.

**The session brief.** Write it for the agent, filled in:

> You run session S<N> of the multi-session effort in `<folder>`, under autopilot, on branch
> `<mother branch>`. Read the folder's `README.md`, `plan.md`, `spec.md` (if any),
> `decisions.md`, `docs.md` and the last entry of `log.md`, then the parts of `findings.md`
> that S<N> names. Do S<N>'s tasks by the `simple-session` skill's "Design and reuse", "Do
> the work" and "Run the checks" (its file is `<path to simple-session/SKILL.md>`). If the
> working tree already holds part of S<N>'s work, carry on from it. Add this session's rows
> to `docs.md`, as the `multi-session` skill's "Rules for every session" says. Treat
> `assumed` answers in `decisions.md` as answers. Do not switch branches, commit, push,
> merge, run `/simplify` or `/code-review`, or start agents of your own. Do not edit
> `plan.md` or `log.md`. Stop and return `PAUSE: <reason>` instead of going on wherever a
> step or skill you follow says to stop and ask the user; when `scripts/check` still fails
> after two fix attempts; or when the session cannot finish within its plan. Otherwise
> return, in under 30 lines, what `simple-session`, "Stop and report", lists, leaving out
> the review and the commit message; then the `docs.md` rows added and anything surprising.

**The end.** After the last session:

1. **Close-out.** Run "Closing out" as one more session, by the same steps and brief, with
   two differences: any ADR it writes is **Proposed**, for the user to accept, and it keeps
   the folder until the merge answer.
2. **Report.** Copy `report.md` from `templates/` into the folder, fill it in, and show it
   to the user.
3. **One question.** End the report with one question: merge the mother branch into the
   main branch, or, if the `Integration` line says pull requests or the environment assigns
   the branch, push it and open a pull request. Change nothing before the answer.

On yes, in this order, each its own commit:

1. Delete the folder (in a committed setup, `git rm -r` it). Its lasting parts are already
   in the record and the docs.
2. Bump and integrate as `simple-session`, "On yes: commit, bump, integrate", says. Its
   bump is the effort's only one, the last commit on the mother branch.

On no, leave the branch and the folder as they are, and ask what to change.

**Resuming autopilot.** The user resumes with: **"Read <folder>/README.md and continue
autopilot."** Do "Resuming" steps 1 to 3, then the loop above from the first session not
`done`. A session left `in progress` (paused, or cut off) starts again. If the working tree
holds its uncommitted work, ask whether to keep it or start the session afresh. Do not stash
or discard it yourself.

## Closing out

Under autopilot, close-out runs as "Autopilot" says.

The folder is disposable. Its last session moves anything worth keeping somewhere that lasts,
then the folder is deleted. Work from `docs.md`, row by row, not from memory or the log alone:

- how the system works now → the reference docs that own each changed subject (the "Owns"
  table in `docs/README.md`) and CLAUDE.md. Do every `open` row in `docs.md` and re-read each
  `done` row's doc against the final code, since a later session may have changed it again.
  Grep `docs/` and CLAUDE.md for every old name under "Renames and removals", and fix each
  hit. Bump `updated:` on each doc you change. If there is a `spec.md`, check each criterion
  is met, and put the behaviour it describes in those docs, not in a copy of the spec;
- what was built and why → a record in `docs/records/`, from the ledger's Record lines and
  `log.md` (then run `node scripts/docs/generate-records-index.mjs`);
- follow-ups and out-of-scope findings → `docs/backlog.md`, each with a trigger to act
  (the ledger's Backlog lines, and any finding no session fixed);
- an architecturally significant decision → an ADR in `docs/decisions/` (the ledger's ADR
  candidates; check the bar first).

The `write-doc` skill has the format for each. A repository with no `docs/README.md` (a lite
install) has none of these: move what lasts into CLAUDE.md or `README.md`, and list
follow-ups for the user in the close-out entry. Mark each ledger row `done` or `none` as you
go. When no row is `open`, mark every session done, write a close-out entry in `log.md`
listing what is left for the user, and ask before deleting the folder. A committed folder is
deleted in a commit of its own.
