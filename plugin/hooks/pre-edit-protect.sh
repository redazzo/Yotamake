#!/usr/bin/env bash
# PreToolUse hook for Edit/Write: refuse edits to protected files.
# The list is the project's .claude/yotamake/protected-paths.conf, or the plugin
# template's copy of that file when the project has none.
# Claude Code passes the tool call as JSON on stdin. Exit 2 blocks the call and
# sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

root="${CLAUDE_PROJECT_DIR:-$PWD}"
conf="$root/.claude/yotamake/protected-paths.conf"
[[ -f "$conf" ]] || conf="$here/../template/.claude/yotamake/protected-paths.conf"
[[ -f "$conf" ]] || exit 0

fp=$(tool_file_path)
[[ -n "$fp" ]] || exit 0
name=$(basename "$fp")

# The path from the project root, for patterns such as config/secrets/*. For a file
# outside the project it stays the full path, which is matched anyway.
rel=${fp#"$root"/}

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
