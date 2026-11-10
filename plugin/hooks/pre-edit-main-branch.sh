#!/usr/bin/env bash
# PreToolUse hook for Edit/Write: refuse edits while the file's repository is on
# its main branch. Work happens on a branch cut from main (`simple-session`, "Branch").
#
# The main branch is read from the repository's CLAUDE.md line
# "- **Main branch:** `<name>`"; without one, both main and master count.
# Files outside a git repository (scratchpad, /tmp) are always allowed, and so are
# git-ignored files (a multi-session .scratchpad/ folder, made on main) and a
# repository with no commits yet. A repository that works on main on purpose
# opts out with an empty file at .claude/yotamake/allow-edits-on-main.
# Exit 2 blocks the call and sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

fp=$(tool_file_path)
[[ -n "$fp" ]] || exit 0

# The file may not exist yet: repo_path_of starts from its nearest existing directory.
root=$(repo_path_of "$fp" | head -n1)
[[ -n "$root" ]] || exit 0
git -C "$root" check-ignore -q -- "$fp" && exit 0
on=$(guarded_main_branch "$root") || exit 0

echo "BLOCKED: $root is on its main branch '$on'. Cut a branch first (e.g. git switch -c fix/<topic>), then edit. $MAIN_OPT_OUT" >&2
exit 2
