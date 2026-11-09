#!/usr/bin/env bash
# PostToolUse hook for Edit/Write: run a fast per-file check (lint, format check)
# on the edited file, using the first matching rule in the project's
# .claude/yotamake/post-edit-checks.conf. No file, no checks.
# A failing check exits 2, which shows its output to Claude so it can fix it.

conf="${CLAUDE_PROJECT_DIR:-.}/.claude/yotamake/post-edit-checks.conf"
[[ -f "$conf" ]] || exit 0

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

fp=$(tool_file_path)
[[ -n "$fp" && -f "$fp" ]] || exit 0

case "$fp" in
    */node_modules/*|*/.git/*|*/dist/*|*/build/*|*/.venv/*|*/vendor/*) exit 0 ;;
esac

root="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$fp")" rev-parse --show-toplevel 2>/dev/null)}"
[[ -n "$root" ]] || exit 0

while read -r glob cmd; do
    [[ -z "$glob" || "$glob" == \#* || -z "$cmd" ]] && continue
    [[ "$fp" == $glob ]] || continue

    quoted=$(printf '%q' "$fp")
    # Inner quotes keep bash 5.2 from reading & in the path as "the matched text".
    out=$(cd "$root" && bash -c "${cmd//\{file\}/"$quoted"}" 2>&1)
    status=$?
    if [[ $status -ne 0 ]]; then
        printf 'Post-edit check failed for %s:\n%s\n' "$fp" "$out" >&2
        exit 2
    fi
    exit 0
done < "$conf"

exit 0
