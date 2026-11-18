#!/usr/bin/env bash
# Stop hook: block the end of a turn once when Claude edited code in this session after
# the last passing scripts/check (`simple-session`, "Run the checks"). The step evaluator
# (steps.mjs, ADR-0010) decides, by the "stop" row of steps.json: post-edit-mark.sh logs
# each edit in the edited tree's git directory, and the project's scripts/check touches the
# stamp there when it passes. Besides the project's own tree, it looks in the repository's
# other worktrees, since an edit by absolute path into a linked worktree is logged in that
# worktree, not this one (ADR-0005). The message names each tree still to check.
#
# It lets the turn end when Claude Code is already continuing from this hook
# (stop_hook_active), when the project is not a git repository, and when no tree has a code
# edit from this session after its passing check (a question, a docs-only change, or a
# tree whose scripts/check has no stamp line). A gate with the stamp line but no checks never
# writes it, so it blocks once; the message says what to do then. A worktree whose folder is
# gone is skipped. If the evaluator cannot decide, the turn ends.
# Exit 2 blocks the stop and sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
root=$(hook_root "$in")
common=$(git -C "$root" rev-parse --git-common-dir 2>/dev/null) || exit 0
[[ "$common" == /* ]] || common="$root/$common"
# Cheap first: on many turns no tree has an events log.
compgen -G "$common/yotamake-events" >/dev/null ||
    compgen -G "$common/worktrees/*/yotamake-events" >/dev/null || exit 0
out=$(node "$here/steps.mjs" decide stop <<<"$in" 2>/dev/null) || exit 0
[[ -n "$out" ]] || exit 0

trees=$(cut -f1 <<<"$out" | awk 'NR > 1 { printf ", " } { printf "%s", $0 }')
echo "BLOCKED: code was edited in this session after the last passing scripts/check. Run scripts/check in $trees (cd there first), and the review if it has not run, before you report (simple-session, \"Run the checks\"). If you are stopping to ask the user something first, say so and end the turn again: this hook blocks only once. If the check says no check ran, it cannot pass: say so in the report and end the turn." >&2
exit 2
