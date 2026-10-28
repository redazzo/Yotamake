#!/usr/bin/env bash
# PreToolUse hook for Edit/Write: refuse edits to files listed in protected-paths.conf.
# Claude Code passes the tool call as JSON on stdin. Exit 2 blocks the call and
# sends stderr back to Claude.

here=$(dirname "$0")
conf="$here/protected-paths.conf"
[[ -f "$conf" ]] || exit 0

fp=$(python3 -c "
import json, sys
try:
    d = json.load(sys.stdin).get('tool_input', {})
except Exception:
    d = {}
print(d.get('file_path') or d.get('notebook_path') or '')
" 2>/dev/null)
[[ -n "$fp" ]] || exit 0
name=$(basename "$fp")

# Exceptions (lines starting with !) win over protections.
while read -r pattern; do
    [[ "$pattern" == !* ]] || continue
    if [[ "$name" == ${pattern#!} ]] || [[ "$fp" == ${pattern#!} ]]; then exit 0; fi
done < <(grep -v '^\s*\(#\|$\)' "$conf")

while read -r pattern; do
    [[ "$pattern" == !* ]] && continue
    if [[ "$name" == $pattern ]] || [[ "$fp" == $pattern ]]; then
        echo "BLOCKED: $fp matches protected pattern '$pattern' (.claude/hooks/protected-paths.conf). Ask the user to edit it by hand." >&2
        exit 2
    fi
done < <(grep -v '^\s*\(#\|$\)' "$conf")

exit 0
