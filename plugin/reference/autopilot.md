# Autopilot

The `multi-session` skill sends you here ("Autopilot") when autopilot starts or resumes.

Autopilot runs every session after S0 without the user, one after another, on one mother
branch, then writes one report and asks one question: commit and merge. ADR-0012 has the reasons. Each
session still does the `simple-session` work and checks; what goes is the stop, the report
and the `/clear` between sessions. Every `git merge` still prompts, the
commit waits for the user's yes, and autopilot never pushes, merges into the main branch, tags or deploys without a
yes.

**Commits and review depend on the setup:**

- **Local:** sessions neither commit nor review. Their work stays uncommitted on the mother
  branch. The review runs once, at the end, on the whole effort, and the effort lands as one
  commit.
- **Committed:** its container can be thrown away, so each session is reviewed, committed
  as `(S<N>)` and pushed.

The steps below say "local only" or "committed only" where the two differ.

**Turning it on.** Autopilot is on by default. It starts when the user approves S0's spec and
plan (`multi-session`, "Starting a new effort"), unless they turn it off in that same answer
(for example, "approve, step through"). It never starts before that approval. When it starts:

1. Write `Autopilot: on (<yyyy-mm-dd>), mother branch <branch>.` under **Setup** in the
   folder's `README.md`, and a row in `decisions.md` saying it is on. Switch the resume
   line to the autopilot one.
2. Pick the mother branch. If the environment assigns a branch, that branch is the mother
   branch. Otherwise cut one from an up-to-date main branch, as in `simple-session`,
   "Branch", named `<prefix>/<effort-slug>` with the project's prefix for the effort's main
   kind of change (**Branching and releases**). No session gets a branch of its own.

Turning it off is in `multi-session`, "Autopilot".

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

   A `PAUSE: size` also offers to split the session, as `multi-session`, "Rules for every
   session", says; it waits for the user's yes. You make the split in `plan.md`, not the
   agent. Then tell the agent to stop and return its report for the work so far, and go on
   to the check below.
4. **Check.** Run `scripts/check` yourself, saving its output as `multi-session`, "Rules for
   every session", says: the agent's report is not proof. A check that still fails after two
   fix attempts pauses as above.
5. **Review (committed only).** Run the review as `simple-session`, "Review", says, on this
   session's uncommitted diff: the docs-only and trivial tests apply to that diff, and the
   design read's brief uses `git diff HEAD`. A conflict the design read finds pauses as
   above.
6. **Record.** Set the session's status in `plan.md` to `done` and append its `log.md`
   entry; the report is built from these entries. Local: the entry has no commit hash.
   Committed: it adds what the review found, fixed and left; then commit on the mother
   branch as `simple-session`, "On yes: commit, bump, integrate", says, with the folder's
   updates and `(S<N>)` at the end of the summary, and push. No version bump and no merge
   yet.
7. Go on to the next session.

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
> after two fix attempts; or when the session cannot finish within its plan. Return
> `PAUSE: size — <reason>` when a size signal holds partway (`simple-session`, "Do the work",
> its "Stop partway"). Otherwise return, in under 30 lines, what `simple-session`,
> "Stop and report", lists, leaving out the review and the commit message; then the
> `docs.md` rows added and anything surprising.

**The end.** After the last session:

1. **Close-out.** Run `multi-session`, "Closing out", as one more session, by the same
   steps and brief, with two differences: any ADR it writes is **Proposed**, for the user
   to accept, and it keeps the folder until the merge answer.
2. **Review (local only).** Do not run `scripts/check` again; close-out's run counts. Run
   the review as `simple-session`, "Review", says, on the whole effort's uncommitted diff;
   its `git add -N` step brings in every file the effort added. A conflict the design read
   finds pauses as above. Add what the review found, fixed and left to `log.md`.
3. **Report.** Copy `report.md` from the `multi-session` skill's `templates/` into the
   folder, fill it in, and show it to the user.
4. **One question.** End the report with one question: commit the effort and merge the
   mother branch into the main branch, or, if the `Integration` line says pull requests or
   the environment assigns the branch, commit, push it and open a pull request. Change
   nothing before the answer.

On yes, in this order:

1. Delete the folder. Its lasting parts are already in the record and the docs. Committed
   only: `git rm -r` it, in a commit of its own.
2. Local only: commit the whole effort as one commit, as `simple-session`, "On yes:
   commit, bump, integrate", says. Its summary names the effort; its body lists the
   sessions, one line each.
3. Bump and integrate as that step says, the bump as its own commit. It is the effort's
   only bump, the last commit on the mother branch.

On no, leave the branch and the folder as they are, and ask what to change.

**Resuming autopilot.** The user resumes with: **"Read <folder>/README.md and continue
autopilot."** Do `multi-session`, "Resuming", as far as reading `findings.md`, then
the loop above from the first session not `done`. A session left `in progress` (paused, or
cut off) starts again. Local only: the working tree holds the finished sessions' work;
keep it. If the tree may also hold part of the session left `in progress`, ask whether to
keep that part or start the session afresh. Do not stash or discard anything yourself.
