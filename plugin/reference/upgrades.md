# Upgrades

Changes a plugin version makes to the files each repository owns (`CLAUDE.md`,
`scripts/check`). The installer never overwrites those, so a repository set up with an older
version does not get them on its own. The sessions read this file at their start
(`simple-session`, "Harness upgrades") and offer to apply what is missing.

`.claude/yotamake/version` in the repository holds the version its harness files were last
installed or upgraded to. The installer writes it. A repository without it was set up before
0.11.0.

Each entry has:

- **Check:** how to tell it is already applied. An entry whose check passes is skipped,
  whatever the version file says.
- **Apply:** what to do. Propose the filled-in lines from the repository, as
  `/yotamake:setup` does, and get the user's confirmation before writing a rule the sessions
  stop on.

Newest first; apply pending entries oldest first. Add an entry whenever a version changes a
project-owned template file.

## 0.38.0 — Session size line and session definition

- **Check:** `CLAUDE.md`, **Branching and releases**, has a line starting
  `**Session size:**`; "How to work here" no longer says "will not fit one branch and one
  context"; and **Conventions** no longer says "Work that spans several contexts".
- **Apply:**
  - Add that line from the plugin's `template/CLAUDE.md`, before the `Version bump` line or at
    the end of the section. Propose the template's default, and ask whether the project's
    reviews call for another limit.
  - In "How to work here", replace "If the change will not fit one branch and one context"
    with the template's pointer to `simple-session`, "Check the size".
  - In **Conventions**, replace "**Work that spans several contexts**" with "**Work too big
    for one session**".

## 0.35.0 — Hooks read the main branch and doc paths from project.conf

- **Check:** `.claude/yotamake/project.conf` exists, its `main-branch` line names the branch
  of the `Main branch` line in `CLAUDE.md`, and `main_branches()` in `scripts/check` reads
  `project.conf` (or `scripts/check` has no `main_branches()`).
- **Apply:** copy the plugin's `template/.claude/yotamake/project.conf` into
  `.claude/yotamake/`. Set `main-branch` to the `Main branch` name in `CLAUDE.md`, and the
  `docs` lines to the paths its `Docs-only` line names (one glob per line; a glob with no `/`
  matches only root files; a `!` line is an exception). In `scripts/check`, make
  `main_branches()` read the conf before `CLAUDE.md`: put these lines in place of its `m=$(sed
  …)` line, keeping that line as the fallback:

  ```bash
  m=$(awk '{ sub(/#.*/, "") } $1 == "main-branch" && NF == 2 { print $2; exit }' .claude/yotamake/project.conf 2>/dev/null)
  [[ -n "$m" ]] ||
      m=$(sed -n 's/^[-*][[:space:]]*\*\*Main branch:\*\*[[:space:]]*`\([^`]*\)`.*/\1/p' CLAUDE.md 2>/dev/null | head -n1)
  ```

  In `CLAUDE.md`, end the `Main branch` line with "Hooks read the name from `main-branch` in
  `.claude/yotamake/project.conf`; change both together." in place of "it reads the name
  from this line", and tell the user that a change to the `Main branch` or `Docs-only` line
  now needs the same change in `project.conf` (`/yotamake:doctor` checks they agree).

## 0.35.0 — An empty gate writes no pass stamp

- **Check:** `scripts/check` writes `yotamake-check-passed` only when at least one check ran
  (the block below), or does not contain `yotamake-check-passed` at all.
- **Apply:** replace the stamp lines at the end of `scripts/check`, just before its final
  `exit $failed`, with these (and drop the old `no checks configured` note line):

  ```bash
  # A passing run outside the pre-commit hook leaves a stamp in the git directory. The
  # plugin's Stop hook reads it: Claude may not end a turn with code edited after the last
  # pass. A run in which no check ran leaves none. Keep these lines when you edit the file.
  if [[ $ran -eq 0 && "$mode" != --staged ]]; then
      echo "note: no check ran for this change, so no pass stamp was written. If scripts/check has no checks yet, add them (/yotamake:setup finds them)." >&2
  elif [[ $ran -gt 0 && $failed -eq 0 && "$mode" != --staged ]]; then
      touch "$(git rev-parse --git-path yotamake-check-passed)"
  fi
  ```

  If the script has no `ran` counter, add `ran=0` beside `failed=0` and `ran=$((ran + 1))`
  as the first line of `run()`. If it names its variables differently, use its names. Tell
  the user that a run with no checks now leaves the `Stop` hook unsatisfied, so a session
  that edits code says the gate is empty instead of counting it as checked.

## 0.34.1 — Protected paths are not read either

- **Check:** the first comment line of `.claude/yotamake/protected-paths.conf` says "read or
  edit". A missing file, or one whose comments the project has rewritten, passes.
- **Apply:** in that comment, change "Files Claude may not edit" to "Files Claude may not
  read or edit", and "pre-edit-protect.sh hook." to "pre-edit-protect.sh hook, on Edit,
  Write and Read." The hook reads the list on Read from this version on, whatever the
  comment says; take out a line whose file Claude needs to read.

## 0.32.0 — Domain language line

- **Check:** the Architecture section of `CLAUDE.md` has a `**Domain language:**` line.
- **Apply:** add a `**Domain language:**` line after Constraints, filled in as "Where the
  glossary lives" in `domain-language.md` (this folder) says. In the section's comment,
  change "FILL IN each line. Keep the six labels" to "FILL IN each line but Domain language.
  Keep the labels".

## 0.29.0 — ADRs may be amended

- **Check:** `CLAUDE.md`'s **Docs** line says "only superseded or amended", and the
  **Decisions** row of the first table in `docs/README.md` mentions a dated amendment. A
  missing file, or a `CLAUDE.md` with no **Docs** line (a lite install), passes.
- **Apply:** in `CLAUDE.md`, change "(ADRs — never edited, only superseded)" to "(ADRs —
  never edited, only superseded or amended)". In `docs/README.md`, change the **Decisions**
  row's update rule to "Never edited — superseded by a later ADR, or given a dated amendment".
  Where the project has reworded either line, make the same change in its words.

## 0.29.0 — ADR template moves into write-doc

- **Check:** the `## Template` section of `docs/decisions/README.md` names `write-doc`'s
  `templates/decision.md`, or the repository has no `docs/decisions/README.md` (a lite
  install).
- **Apply:** replace everything from the `## Template` heading to the end of
  `docs/decisions/README.md` with the same part of the plugin's
  `template/docs/decisions/README.md`. Keep the index and anything above that heading. If
  there is no `## Template` heading, or the project changed its template, show the user the
  difference and ask before replacing it. Do not edit existing ADRs. Tell the user the ADR
  template now lives in the `write-doc` skill, so later changes to it arrive with plugin
  updates.

## 0.24.0 — Test-first line

- **Check:** `CLAUDE.md`, **Checks**, has a line starting `**Test-first:**`.
- **Apply:** add that line from the plugin's `template/CLAUDE.md` at the end of the section.
  Ask the user whether a change in behaviour should start with a failing test, and write
  `yes` or `no` (the default). Tell the user that `simple-session` and `spec` read it.

## 0.22.0 — Worktree setup line

- **Check:** `CLAUDE.md`, **Branching and releases**, has a line starting
  `**Worktree setup:**`.
- **Apply:** add that line from the plugin's `template/CLAUDE.md` before the
  `Release branch / tags` line, or at the end of the section if it has none, and propose its
  value as `/yotamake:setup` does. Tell the user that parallel sessions in worktrees
  (`multi-session`, "Running sessions in parallel") read it.

## 0.20.1 — CLAUDE.md says what to do without the plugin

- **Check:** `CLAUDE.md`, "How to work here", has a paragraph starting
  `**If the plugin is not loaded**`.
- **Apply:** copy that paragraph, its list and the short paragraph after it from the plugin's
  `template/CLAUDE.md` to the end of "How to work here". If the repository has no
  `scripts/check`, name its check commands instead. Tell the user that a session without the
  plugin now has steps to follow.

## 0.17.0 — SessionStart hook tells Claude where it is

- **Check:** `.claude/settings.json` has a `SessionStart` hook whose command names
  `session-context.sh`, or `.claude/yotamake/session-context.sh` is listed in
  `.claude/yotamake/skip`.
- **Apply:** re-run the plugin's `install.sh` against the repository root. It installs
  `.claude/yotamake/session-context.sh` and merges its `SessionStart` entry into
  `.claude/settings.json`, keeping the repository's own hooks. Tell the user that each
  session now starts with a few lines in Claude's context: the branch and whether it is the
  main branch, any active multi-session effort and its next session, and the session rule
  (ADR-0004, amendment). The person does not see them. To opt out, list the script in
  `.claude/yotamake/skip` and delete it.

## 0.16.0 — SessionStart hook sets core.hooksPath

- **Check:** `.claude/settings.json` has a `SessionStart` hook whose command names
  `set-hooks-path.sh`, or `.claude/yotamake/set-hooks-path.sh` is listed in
  `.claude/yotamake/skip`.
- **Apply:** re-run the plugin's `install.sh` against the repository root. It installs
  `.claude/yotamake/set-hooks-path.sh` and merges the `SessionStart` entry into
  `.claude/settings.json`, keeping the repository's own hooks. Tell the user that, from now
  on, a clone without `core.hooksPath` gets it set to `.githooks` at the first Claude Code
  session, unless another hook tool is in use, and that the person sees one line when it
  happens (ADR-0004). To opt out, list the script in `.claude/yotamake/skip` and delete it.

## 0.15.0 — scripts/check stamps a passing run

- **Check:** `scripts/check` contains `yotamake-check-passed`, or the repository chose to go
  without the `Stop` hook on purpose.
- **Apply:** add these lines to `scripts/check`, just before its final `exit $failed`, as in
  the plugin's `template/scripts/check`:

  ```bash
  # A passing run outside the pre-commit hook leaves a stamp in the git directory. The
  # plugin's Stop hook reads it: Claude may not end a turn with code edited after the last
  # pass. Keep this line when you edit the file.
  [[ $failed -eq 0 && "$mode" != --staged ]] && touch "$(git rev-parse --git-path yotamake-check-passed)"
  ```

  If the script names its mode or failure variables differently, use its names. Tell the
  user that, from now on, Claude cannot end a turn with code edited since the last passing
  run (`README.md` explains the hook).

## 0.14.0 — Switching branches without a prompt

- **Check:** the `allow` list in `.claude/settings.json` has `Bash(git switch:*)`, and the
  `ask` list has `Bash(git switch -f:*)`, `Bash(git switch --force:*)`,
  `Bash(git switch --discard-changes:*)`, `Bash(git switch -C:*)` and
  `Bash(git switch --force-create:*)`, or the repository chose otherwise on purpose.
- **Apply:** re-run the plugin's `install.sh` on the repository. It merges the new rules into
  `.claude/settings.json` and keeps everything else. An old `Bash(git switch -c:*)` rule
  can stay; `Bash(git switch:*)` covers it.

## 0.13.0 — Session steps allowed without a prompt

- **Check:** the `allow` list in `.claude/settings.json` has `Bash(git checkout -b:*)`,
  `Bash(git switch -c:*)`, `Bash(git add:*)` and `Bash(git pull --ff-only:*)`, or the
  repository has put them under `ask` or `deny` on purpose.
- **Apply:** re-run the plugin's `install.sh` on the repository. It merges the four rules
  into `.claude/settings.json` and keeps everything else. The `ask` rules are unchanged.

## 0.12.0 — Docs-only line

- **Check:** the Branching and releases section of `CLAUDE.md` has a `**Docs-only:**` line.
- **Apply:** add a `**Docs-only:**` line to Branching and releases, after `Integration`,
  from the plugin's `template/CLAUDE.md`. Before 0.12.0 any Markdown, `CLAUDE.md` included,
  counted as docs. If other Markdown is docs (a `guides/` folder, say), name its paths in the
  line. Tell the user that `CLAUDE.md`, and any Markdown that holds prompts, skills or
  templates, now gets design and review.

## 0.11.3 — Paths from the project root in protected-paths.conf

- **Check:** the comment at the top of `.claude/yotamake/protected-paths.conf` says a glob
  with a `/` is also matched against the path from the project root, or the repository has
  no such file.
- **Apply:** replace the first comment paragraph with the one in the plugin's
  `template/.claude/yotamake/protected-paths.conf`. Then look for a glob in the list that
  holds a `/` but starts with neither `/` nor `*`: before 0.11.3 it never matched anything,
  so tell the user it now protects those files.

## 0.11.0 — Style line

- **Check:** the Architecture section of `CLAUDE.md` has a `**Style:**` line.
- **Apply:** add a `**Style:**` line first in the Architecture list, naming the style or
  styles the code follows and where, from the "Signs in code" entries in
  `architecture-styles.md` (this folder). In the section's intro, change "that **Patterns**
  does not list" to "that **Style** or **Patterns** does not list"; in its comment, "five
  labels" to "six labels". Then use the style's catalogue entry to suggest Boundaries and
  Patterns rules the code keeps but the lines leave out.

## 0.10.0 — Constraints line

- **Check:** the Architecture section of `CLAUDE.md` has a `**Constraints:**` line.
- **Apply:** add a `**Constraints:**` line after Patterns: limits from outside the code that
  the repository states, such as the runtime version in `package.json` `engines`, the CI
  matrix, or the licence. In the intro, add "break a **Constraint**," after "cross a
  **Boundary**,".

## 0.9.0 — Architecture section and design gates

- **Check:** `CLAUDE.md` has an `## Architecture` section with `**Modules:**`,
  `**Boundaries:**`, `**Shared code:**` and `**Patterns:**` lines; `scripts/check` has a
  "Design gates" comment or a boundary or duplicate-code `run` line.
- **Apply:** add the `## Architecture` section from the plugin's `template/CLAUDE.md`, after
  Conventions, with every line the repository's version lacks, and fill each line in as
  `/yotamake:setup` does. Add "Architecture" to the list of section names in the comment at
  the top of `CLAUDE.md`. Add the "Design gates" comment block from `template/scripts/check`
  before the docs lines, and a `run` line for any boundary or duplicate-code tool the
  repository already has.
