#!/usr/bin/env bash
# PreToolUse hook for Edit/Write: refuse edits to protected files.
# The list is the .claude/yotamake/protected-paths.conf of the file's repository, else the
# project's, else the plugin template's copy of that file.
# Claude Code passes the tool call as JSON on stdin. Exit 2 blocks the call and
# sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
fp=$(tool_file_path <<<"$in")
[[ -n "$fp" ]] || exit 0
name=$(basename "$fp")

# The file's own repository and its path from there, for patterns such as
# config/secrets/*. That repository may be a linked worktree whose path does not start
# with the project directory's. For a file outside any repository, rel is the path from
# the project directory, or the full path when it is outside that too (matched anyway).
{ read -r root; read -r rel; } < <(repo_path_of "$fp")
[[ -n "$root" ]] || { root=$(hook_root "$in"); rel=${fp#"$root"/}; }

conf="$root/.claude/yotamake/protected-paths.conf"
[[ -f "$conf" ]] || conf="$(hook_root "$in")/.claude/yotamake/protected-paths.conf"
[[ -f "$conf" ]] || conf="$here/../template/.claude/yotamake/protected-paths.conf"
[[ -f "$conf" ]] || exit 0

# matches <glob>: the basename or the full path matches it, or, for a glob with a
# slash (as in .gitignore), the path from the project root does.
matches() {
    [[ "$name" == $1 || "$fp" == $1 ]] && return 0
    [[ "$1" == */* && "$rel" == $1 ]]
}

# Exceptions (lines starting with !) win over protections.
while read -r pattern; do
    [[ "$pattern" == !* ]] || continue
    if matches "${pattern#!}"; then exit 0; fi
done < <(grep -v '^\s*\(#\|$\)' "$conf")

while read -r pattern; do
    [[ "$pattern" == !* ]] && continue
    if matches "$pattern"; then
        echo "BLOCKED: $fp matches protected pattern '$pattern' ($conf). Ask the user to edit it by hand." >&2
        exit 2
    fi
done < <(grep -v '^\s*\(#\|$\)' "$conf")

exit 0
