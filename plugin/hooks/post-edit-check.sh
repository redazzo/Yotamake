#!/usr/bin/env bash
# PostToolUse hook for Edit/Write: run a fast per-file check (lint, format check)
# on the edited file, using the first matching rule in the
# .claude/yotamake/post-edit-checks.conf of the file's repository (else the project's), run
# from that repository's top level. No file, no checks.
# A failing check exits 2, which shows its output to Claude so it can fix it.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
fp=$(tool_file_path <<<"$in")
[[ -n "$fp" && -f "$fp" ]] || exit 0

case "$fp" in
    */node_modules/*|*/.git/*|*/dist/*|*/build/*|*/.venv/*|*/vendor/*) exit 0 ;;
esac

# The file's own repository (a linked worktree, say), else the project directory.
{ read -r root; } < <(repo_path_of "$fp")
[[ -n "$root" ]] || root=$(hook_root "$in")
conf="$root/.claude/yotamake/post-edit-checks.conf"
[[ -f "$conf" ]] || exit 0

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
