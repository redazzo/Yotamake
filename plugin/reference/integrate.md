# Commit, bump, integrate

The `simple-session` skill sends you here ("On yes: commit, bump, integrate") once the user
says yes to the commit.

Only after the user says yes. Claude Code will also ask before `git commit`, `git merge` and
`git push` when the project's settings put them under `ask`; that is expected. Stage the files
you changed by name, not `git add -A`. If the pre-commit hook fails, fix the cause; never pass
`--no-verify`. The plugin's Bash hook refuses it; if the user wants the hook skipped, they run
the command themselves with `! <command>`. If the plugin's commit gate refuses, do the step
it names and commit again.

```bash
git add <files>
git commit -m "<message>"
```

If CLAUDE.md defines a version bump, code changes get one as its own commit on the branch,
using the command and file it names. Docs-only branches do not. After the bump's edits, run
`scripts/check` again: the plugin's commit gate refuses a commit until the check has passed
since the last edit. The bump comes after the review, so its message ends with the trailer
line `Review-skipped: release bump`, which the gate accepts in place of a new review.

Then integrate the way the `Integration` line in CLAUDE.md says.

**Local merge** (the default, when the line is missing or unfilled):

```bash
git switch <main-branch>
git merge --no-ff <branch> -m "Merge <branch> into <main-branch>"
```

Then do any after-merge step that a release or tags line in CLAUDE.md, **Branching and
releases**, lists, such as a release tag. With no such line, there is none. Do not push or
delete the branch unless the user asks.

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
