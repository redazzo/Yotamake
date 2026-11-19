---
name: simple-session
description: Use before editing code, tests or docs in a repository set up with the harness (it has scripts/check) — for ANY change, even a one-line fix, a rename or a typo, and also when the user already names the branch, says exactly what to change, says it is quick or not to ask, or the environment assigns a branch. Runs the change as one session: work on that branch (or cut one from the main branch), update the doc that owns the change, run scripts/check and a review, then stop and ask before commit, version bump and merge or pull request. Use multi-session instead when the work is too big to review and revert as one diff, or has a decision that must wait for part of the work. Not for questions or explanations.
---

# Simple session

A session is one change, on one branch with one merge, that can be reviewed as one diff and
reverted on its own, with its decisions settled before it starts (step 1). This skill is the
`multi-session` rules without the working folder: no plan, findings file or log, because
nothing has to survive a `/clear`.

Project specifics live in `CLAUDE.md`, not here. This skill reads these sections:

- **Checks** — how the project's one check command works (normally `scripts/check`), and
  the `Test-first` line (step 4, "Do the work").
- **Branching and releases** — the main branch, branch prefixes, how to integrate (a local
  merge or a pull request), whether code changes get a version bump, which files count
  as docs (the `Docs-only` line), and the `Session size` limit (steps 1 and 4).
- **Architecture** — the design a change follows: its `Style`, `Modules`, `Boundaries`,
  `Shared code`, `Patterns`, `Constraints` and `Domain language` lines, and the accepted
  ADRs (step 3).

If a section or line is missing or still holds `<!-- FILL IN -->` placeholders, say so once
in the report and use the defaults given below or in "Missing setup and tools".

**Docs-only.** A docs-only branch skips the design and review steps and the version bump. A
branch is docs-only when every file it changes is a doc, as the `Docs-only` line names them.
Without that line, the docs are the files under `docs/` and the Markdown files at the
repository root other than `CLAUDE.md`. Everything else counts as code. When unsure, treat
the file as code.

**Trivial.** A trivial branch changes code, but every changed line is a comment or a prose
typo fix (in a docstring, or in Markdown that counts as code). It skips the design and
review steps; the checks and any version bump still apply. A change to a string literal,
identifier, config value or logic is never trivial, even a one-character typo. When unsure,
it is not trivial.

## Findings not acted on

A finding not acted on is a real problem you see, at any step, that this branch does not
fix: work outside the task, a `/simplify` fix you undid, a review finding outside the
branch's concern. This holds on every branch, and a backlog entry does not stop a branch
being docs-only or trivial. When you have one, read
`<this skill's directory>/../../reference/findings-not-acted-on.md`: where to write it, or
why to drop it. Write it before your last `scripts/check` run, so that run covers it.

## Missing setup and tools

No filled **Architecture** section, no `scripts/check` or an empty one, no `docs/README.md`,
or no review tool: read `<this skill's directory>/../../reference/missing-setup.md` at that step.

## 0. Harness upgrades — first

Do this once per conversation, before step 1. With the plugin loaded, no line starting
`Harness upgrades:` in your context means the versions match: carry on without comment.
When there is such a line, or the plugin is not loaded, read
`<this skill's directory>/../../reference/harness-upgrades.md` and follow it.

## 1. Check the size — before branching

Do this before any branch, edit or install. Unless the change is trivial or docs-only, first
estimate its files and changed lines, in one line. It is **too big for one session** if any hold:

- the estimate is over the `Session size` line (a judgment; if it is missing or unfilled,
  about 400 changed lines or 15 files, not counting lockfiles and generated files);
- it bundles separate changes that could each ship, and be reviewed, alone;
- a decision can only be made after part of the work is done;
- it will span days, people or container resets;
- it has a step that cannot be undone;
- as a backstop, it clearly will not fit in one context.

Schema plus code, several interfaces or several packages are not too big by themselves. Nor
is an ADR: it lands first, as its own commit (or session), once the user agrees. If a signal
holds, do not branch or edit: name it, offer `multi-session`, and stop. Otherwise say the
estimate and carry on.

If the request is ambiguous in a way that changes what you build, ask now. Do not ask about
things the code or CLAUDE.md already answer. A `spec-*.md` file in `.scratchpad/` or
`.sessions/` that matches this change is a spec from `/yotamake:spec`: read it now; its
criteria (A1, A2, …) are what done means. If several might match, ask which. If you offer
`multi-session`, say that the spec moves into its folder.

## 2. Branch

If the user or the environment names a branch to work on, and you are on it, stay there and
skip to step 3. The same holds in a linked git worktree made for this session (a
`multi-session` parallel session): its branch is already cut.

Otherwise cut a new branch:

```bash
git switch <main-branch> && git pull --ff-only
git switch -c <prefix>/<short-slug>
```

Default main branch: `main`. Default prefixes: `feat/`, `fix/`, `refactor/`, `perf/`,
`docs/`, `test/`, `chore/`. Never edit files on the main branch or on a release branch. If
you cannot create a branch, stop and say why, without editing anything.

If the working tree is dirty, stop and ask what to do with the changes. Do not stash or
discard them yourself.

## 3. Design and reuse — before any edit

Skip this step when the branch is docs-only or trivial. Otherwise read the **Architecture**
section of CLAUDE.md and decide how the change fits before you write it.

1. **Reuse first.** Before you write a new function, type, component or module, search for
   code that already does the job: first in the places **Shared code** names, then in the
   module the change touches. Reuse it, or extend it when a small change makes it fit. Write
   new code only when nothing fits, and know why. New code that more than one place will use
   goes where **Shared code** says.
2. **Fit the design.** Put the change in the module that owns it (**Modules**). Shape a new
   part the way **Style** says, e.g. a new adapter rather than database code in a hexagonal
   core. Do recurring things the way **Patterns** and the nearby code already do them.
   Name domain ideas with the glossary's words (the **Domain language** line), and follow
   `<this skill's directory>/../../reference/domain-language.md` for a new term.
3. **Stop on a design conflict.** Stop before any edit and ask the user when the change
   would:
   - break a rule in **Boundaries**;
   - break a limit in **Constraints** (a runtime or platform version, a size or speed
     budget, a licence, a security or data rule);
   - go against an accepted ADR (`docs/decisions/`);
   - bring in a kind of part or a way for parts to talk that **Style** does not include,
     e.g. a message queue in a system of direct calls, or a new deployable service in a
     monolith;
   - bring in a way of doing a recurring thing (errors, config, logging, validation, data
     access) that **Patterns** does not list and the code does not already use;
   - add a dependency that overlaps or replaces one the project already uses, or that
     **Boundaries**, **Patterns** or **Constraints** rule out. Any other new dependency goes ahead, and the
     report names it.

   Say what conflicts and quote the rule. Give options with a recommendation, for example: a
   way that keeps the rule; changing the rule first (edit Architecture, or write a new ADR
   first, as in step 1; the order is in "Changing the style" in
   `<this skill's directory>/../../reference/architecture-styles.md`); or dropping that part.
   Do this every time, even when the user asked for exactly that change or said not to ask.
   The rule is the project's, and changing it is a separate decision. Wait for the answer.

## 4. Do the work

Follow CLAUDE.md. Keep to the one concern the branch is named for. The trivial side-fix
policy (CLAUDE.md, Conventions) applies: fix a typo or stale comment you pass, and note it in
the report. Anything with behavioural reach that is outside the task is a finding not acted
on (above), not part of the diff.

**Test-first.** When **Checks** says `Test-first: yes`, start a change in behaviour with a
test. Run just that test (not `scripts/check`) and see it fail for the reason you expect,
then change the code and see it pass. Refactors, docs-only and trivial branches are exempt.
When the line is missing or says `no`, write tests as the project already does.

**Bug fixes.** For a bug fix, follow the `debugging` skill here, then come back for step 5.

**Stop partway**, here or in `debugging`, if a step 1 signal starts to hold (judge the size
by eye; measure it once, for the report): say which, and offer `multi-session` with the work
so far as S1. Inside a `multi-session` effort, stop and ask instead (autopilot: `PAUSE`).

If the change alters how something works, update the reference doc that owns it in the same
branch. The "Owns" table in `docs/README.md` names it. Also fix CLAUDE.md if it describes the
thing you changed, and bump `updated:` on each doc you edit. A follow-up you are not doing is
a finding not acted on. An architecturally significant decision needs an ADR in
`docs/decisions/`, landed first as in step 1. The `write-doc` skill covers the formats.

## 5. Run the checks

Run `scripts/check`. It picks the checks that match what changed, and prints one `PASS` or
`FAIL` line per check. Run it even though a pre-commit hook exists: the hook runs only the
fast checks (`--staged`), and this runs the slow ones too.

Do not add, skip or weaken a check to get a pass. Report only the summary lines. If it says
no check ran, nothing was checked: say so in the report. No `scripts/check`, or one with no
checks yet: see "Missing setup and tools" above.

If a check fails, fix it when the failure is yours. If it was already failing on the main
branch, say so and show the line, rather than fixing it in this branch.

## 6. Review

The review runs once per session, here: after the work is done and the checks pass, on the
whole branch diff. Never after each edit. Fixing its findings does not start another review;
re-run only `scripts/check` (below). If the user asks for more changes after the report, run
the full review once more before the next report, on what changed since the last one: both
skills again, however small the new change, unless that change alone is trivial.

Skip this step when the branch is docs-only or trivial. Any other branch gets the full
review, however small its diff: a small diff makes a cheap review, and reading it yourself
does not replace the skills. Call each with the Skill tool from this context, not from a
subagent you start: each runs its own agents, so their reading stays out of this context.
Only the design read (part 2) goes to a subagent. A skill or the Agent tool not available:
see "Missing setup and tools" above.

Both skills read `git diff HEAD`, which leaves out files git does not track yet. So first run
`git add -N` on each new file this branch adds (`git status --short` marks them `??`): the
diff then shows them in full, but nothing is staged or committed.

Otherwise review the branch's diff against the main branch in three parts:

1. **Reuse.** Run the built-in `/simplify` skill. It applies its fixes itself. Keep the
   fixes to code this branch added or changed. Undo the others by hand (not with
   `git checkout`, which would also drop your own uncommitted work) and treat them as
   findings not acted on (above).
2. **Design.** Once part 1's fixes are in, start one built-in `general-purpose` agent in
   the background with the Agent tool, go on to part 3, and act on its answer when it
   comes. It did not write the change, so it reads it fresh. Its brief, self-contained: "Design read: run `git diff <main branch>`. Read the
   **Architecture** section of CLAUDE.md, and from `docs/decisions/` the accepted ADRs on
   what the diff touches. Find a broken boundary or constraint, a clash with an ADR, a part
   that does not fit the Style, a pattern the project does not use, or logic copied from
   elsewhere. Edit nothing. Return each conflict as file:line and the rule it breaks,
   quoted, or 'none'."
   Fix what lies inside this change. A conflict you only see now gets the same stop as in
   step 3: ask before going on.
3. **Bugs.** Run the built-in `/code-review` skill at low effort. Fix each finding that is a
   real defect in this branch's change.

If any part changed a file, run `scripts/check` again.

## 7. Stop and report

Do not commit yet. (Inside a `multi-session` effort, its rules come first: "Running
sessions in parallel" for a worktree session, "Autopilot" under autopilot.) Tell the user:

- what changed, by file, in a few lines;
- for a code change, two lines: "Reused:" the existing code it reuses or extends (or
  "nothing"), and "New, because:" each new function, type, module or dependency and why
  nothing existing fit (or "nothing new");
- which docs you updated, or why none needed it;
- unless trivial or docs-only, step 1's estimate beside the real diff size (files and changed lines);
- with a spec: each criterion and how it was checked (test name or manual step), and
  whether to delete the spec file once this is merged;
- with `Test-first: yes`, the test you saw fail before the change;
- for a bug fix, what `debugging`, "Report", asks for;
- the check results (one line each);
- the review: which skills you ran, what they found and fixed, or
  that it was skipped because the branch is docs-only, or trivial (and why);
- any side-fixes, each finding not acted on and where it went (a backlog entry, the ledger,
  or this report), and the findings you dropped as wrong, one line each;
- the commit message you propose (Conventional Commits, `type(scope): summary`, ending with
  `Review-skipped: trivial` if the review was skipped as trivial, then any attribution lines
  the environment asks for).

Then ask whether to commit and merge, or, if the project works through pull requests (step 8),
whether to commit, push and open a pull request.

## 8. On yes: commit, bump, integrate

Only after the user says yes. Read `<this skill's directory>/../../reference/integrate.md`
and follow it: stage files by name (never `git add -A` or `--no-verify`) and commit, the
version bump CLAUDE.md defines, then a local merge or a pull request as its `Integration`
line says. Never deploy.
