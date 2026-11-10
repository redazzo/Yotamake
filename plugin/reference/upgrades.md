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
