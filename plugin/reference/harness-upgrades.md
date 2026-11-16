# Harness upgrades

The `simple-session` skill sends you here ("Harness upgrades") once per conversation, before
its first step, when the repository's harness may be older than the plugin.

When the repository's harness is older than the plugin, the plugin's `SessionStart` hook puts
a line starting `Harness upgrades:` in your context, with both versions, or saying it could
not compare them (then read them yourself, as below). With the plugin loaded, no such line
means the versions match: carry on without comment.

Without the plugin, compare the versions yourself: the plugin's is in
`<plugin directory>/.claude-plugin/plugin.json` (this file's directory is
`<plugin directory>/reference/`), the repository's in `.claude/yotamake/version`. If that
file is missing, the repository was set up before 0.11.0.

If the repository's version is older, read `upgrades.md` in this file's directory and run the
**Check** of each entry newer than the repository's version. If every check passes, carry on
without comment.

Otherwise list the entries whose check fails, one line each, and ask the user to pick one:

- **Apply now** (recommended): on its own branch, `chore/yotamake-upgrade` (cut as in
  `simple-session`, "Branch"), run the plugin's `install.sh` against the repository root,
  which refreshes the harness files and the version file. Then do each pending entry's
  **Apply**, oldest first, run `scripts/check`, and report and ask as in `simple-session`,
  "Stop and report". After it is merged, go back to the user's request at `simple-session`,
  "Check the size". On an assigned branch, do this as its own commit there instead.
- **Not now:** carry on with the request. The next conversation asks again.
- **Skip these:** once the request's branch is cut (`simple-session`, "Branch"), write the
  plugin's version to `.claude/yotamake/version` there, name it in the report, and carry on.
  No session asks about these entries again.

If the user said not to ask, do not stop for this: carry on and list the pending entries in
the report.
