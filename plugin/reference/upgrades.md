# Upgrades

Changes a plugin version makes to the files each repository owns (`CLAUDE.md`,
`scripts/check`). The installer never overwrites those, so a repository set up with an older
version does not get them on its own. The sessions read this file at their start (step 0 of
`simple-session`) and offer to apply what is missing.

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
