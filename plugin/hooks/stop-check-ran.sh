#!/usr/bin/env bash
# Stop hook: block the end of a turn once when Claude edited code in this session after
# the last passing scripts/check (`simple-session`, "Run the checks"). post-edit-mark.sh
# records the edit; the project's scripts/check touches the stamp when it passes.
#
# It lets the turn end when Claude Code is already continuing from this hook
# (stop_hook_active), when the project is not a git repository or its scripts/check writes
# no stamp, and when no code was edited in this session (a question, a docs-only change).
# Exit 2 blocks the stop and sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
root=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
uses_gate_stamp "$root" || exit 0
marker=$(gate_file "$root" yotamake-edited) || exit 0
[[ -f "$marker" ]] || exit 0

[[ "$(hook_field stop_hook_active <<<"$in")" == true ]] && exit 0
sid=$(hook_field session_id <<<"$in")
[[ -n "$sid" && "$(head -n1 "$marker")" == "$sid" ]] || exit 0
stamp=$(gate_file "$root" yotamake-check-passed) || exit 0
[[ -f "$stamp" && "$stamp" -nt "$marker" ]] && exit 0

echo "BLOCKED: code was edited in this session after the last passing scripts/check. Run scripts/check, and the review if it has not run, before you report (simple-session, \"Run the checks\"). If you are stopping to ask the user something first, say so and end the turn again: this hook blocks only once." >&2
exit 2
