#!/usr/bin/env bash
# PostToolUse hook for Edit/Write: run a fast per-file check (lint, format check)
# on the edited file, using the first matching rule in post-edit-checks.conf.
# A failing check exits 2, which shows its output to Claude so it can fix it.

here=$(dirname "$0")
conf="$here/post-edit-checks.conf"
[[ -f "$conf" ]] || exit 0

fp=$(python3 -c "
import json, sys
try:
    d = json.load(sys.stdin).get('tool_input', {})
except Exception:
    d = {}
print(d.get('file_path') or d.get('notebook_path') or '')
" 2>/dev/null)
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
    out=$(cd "$root" && bash -c "${cmd//\{file\}/$quoted}" 2>&1)
    status=$?
    if [[ $status -ne 0 ]]; then
        printf 'Post-edit check failed for %s:\n%s\n' "$fp" "$out" >&2
        exit 2
    fi
    exit 0
done < "$conf"

exit 0
