#!/usr/bin/env bash
# Hook for the step evaluator (steps.mjs, ADR-0010): record a session step that is not an
# edit. Called as `record-event.sh review` from PreToolUse on Skill and from
# UserPromptExpansion (a typed /simplify or /code-review), and as `record-event.sh prompt`
# from UserPromptSubmit. steps.mjs keeps only the exact review skills in steps.json, and
# skips a background agent's <task-notification> prompt. The event goes to the events log
# of the hook's cwd. It never blocks.
#
# It fires on every prompt and Skill call, so it stays cheap. Text checks in bash drop a
# Skill call that names neither review skill and a <task-notification> prompt; steps.mjs
# decides exactly. While the tree has no events log yet, a prompt or a review changes no
# decision (the review window starts at the first edit), so it exits before starting Node.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
case $1 in
    review) [[ $in == *simplify* || $in == *code-review* ]] || exit 0 ;;
    prompt) [[ $in != *'"prompt":"<task-notification>'* ]] || exit 0 ;;
esac
if [[ $in =~ \"cwd\":[[:space:]]*\"([^\"\\]*)\" ]]; then
    log=$(gate_file "${BASH_REMATCH[1]}" yotamake-events) && [[ -f "$log" ]] || exit 0
fi
node "$here/steps.mjs" record "$1" <<<"$in" >/dev/null 2>&1
exit 0
