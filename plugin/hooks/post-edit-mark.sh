#!/usr/bin/env bash
# PostToolUse hook for Edit/Write: note that Claude changed a code file in this session,
# for stop-check-ran.sh. It writes the session id to yotamake-edited in the repository's
# git directory. Docs are left alone (files under docs/, and Markdown at the root other
# than CLAUDE.md: the default Docs-only rule in simple-session), as are git-ignored files,
# files outside a repository, and repositories whose scripts/check writes no stamp.
# It never blocks.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
fp=$(tool_file_path <<<"$in")
[[ -n "$fp" && -f "$fp" ]] || exit 0

{ read -r root; read -r rel; } < <(repo_path_of "$fp")
[[ -n "$root" ]] || exit 0
uses_gate_stamp "$root" || exit 0
case "$rel" in
    docs/*) exit 0 ;;
    CLAUDE.md) ;;
    */*) ;;
    *.md) exit 0 ;;
esac
git -C "$root" check-ignore -q -- "$fp" && exit 0

marker=$(gate_file "$root" yotamake-edited) || exit 0
sid=$(hook_field session_id <<<"$in")
printf '%s\n' "${sid:-unknown}" > "$marker" 2>/dev/null
exit 0
