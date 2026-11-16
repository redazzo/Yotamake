#!/usr/bin/env bash
# Stop hook: block the end of a turn once when Claude edited code in this session after
# the last passing scripts/check (`simple-session`, "Run the checks"). post-edit-mark.sh
# records the edit in the edited tree's git directory; the project's scripts/check touches
# the stamp there when it passes. Besides the project's own tree, it looks in the
# repository's other worktrees, since an edit by absolute path into a linked worktree marks
# that worktree, not this one (ADR-0005). The message names each tree still to check.
#
# It lets the turn end when Claude Code is already continuing from this hook
# (stop_hook_active), when the project is not a git repository, and when no tree has a code
# edit from this session newer than its passing check (a question, a docs-only change, or a
# tree whose scripts/check has no stamp line). A gate with the stamp line but no checks never
# writes it, so it blocks once; the message says what to do then. A worktree whose folder is
# gone is skipped.
# Exit 2 blocks the stop and sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
root=$(hook_root "$in")
common=$(git -C "$root" rev-parse --git-common-dir 2>/dev/null) || exit 0
[[ "$common" == /* ]] || common="$root/$common"
# Cheap first: on most turns no tree has a marker (a question, a docs-only change).
compgen -G "$common/yotamake-edited" >/dev/null ||
    compgen -G "$common/worktrees/*/yotamake-edited" >/dev/null || exit 0
[[ "$(hook_field stop_hook_active <<<"$in")" == true ]] && exit 0
sid=$(hook_field session_id <<<"$in")
[[ -n "$sid" ]] || exit 0

# unchecked <tree>: true when this session edited code in <tree> after its last passing check.
unchecked() {
    local marker stamp first
    [[ -d "$1" ]] || return 1
    marker=$(gate_file "$1" yotamake-edited) && [[ -f "$marker" ]] || return 1
    read -r first <"$marker"
    [[ "$first" == "$sid" ]] && uses_gate_stamp "$1" || return 1
    stamp=$(gate_file "$1" yotamake-check-passed) || return 1
    ! [[ -f "$stamp" && "$stamp" -nt "$marker" ]]
}

# The list holds every worktree, this one included.
pending=()
while IFS= read -r line; do
    [[ "$line" == "worktree "* ]] && unchecked "${line#worktree }" && pending+=("${line#worktree }")
done < <(git -C "$root" worktree list --porcelain 2>/dev/null)
(( ${#pending[@]} )) || exit 0

trees=$(printf '%s, ' "${pending[@]}")
echo "BLOCKED: code was edited in this session after the last passing scripts/check. Run scripts/check in ${trees%, } (cd there first), and the review if it has not run, before you report (simple-session, \"Run the checks\"). If you are stopping to ask the user something first, say so and end the turn again: this hook blocks only once. If the check says no check ran, it cannot pass: say so in the report and end the turn." >&2
exit 2
