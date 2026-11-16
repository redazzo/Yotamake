#!/usr/bin/env bash
# PostToolUse hook for Edit/Write: note that Claude changed a code file in this session,
# for stop-check-ran.sh. It writes the session id to yotamake-edited in the repository's
# git directory. Docs are left alone (the docs globs in .claude/yotamake/project.conf, else
# the default Docs-only rule: files under docs/, and Markdown at the root other than
# CLAUDE.md), as are git-ignored files, files outside a repository, and repositories whose
# scripts/check writes no stamp. It never blocks.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

in=$(cat)
fp=$(tool_file_path <<<"$in")
[[ -n "$fp" && -f "$fp" ]] || exit 0

{ read -r root; read -r rel; } < <(repo_path_of "$fp")
[[ -n "$root" ]] || exit 0
uses_gate_stamp "$root" || exit 0

# A docs glob is matched against the path from the repository root; one with no / matches
# only files at the root. A ! line is an exception and wins (ADR-0008).
globs=$(read_fact "$root" docs) || globs=$'docs/*\n*.md\n!CLAUDE.md'
doc_glob() { [[ "$1" == */* || "$rel" != */* ]] && [[ "$rel" == $1 ]]; }
doc=""
while IFS= read -r g; do
    if [[ "$g" == !* ]]; then
        doc_glob "${g#!}" && { doc=""; break; }
    elif doc_glob "$g"; then
        doc=1
    fi
done <<<"$globs"
[[ -n "$doc" ]] && exit 0
git -C "$root" check-ignore -q -- "$fp" && exit 0

marker=$(gate_file "$root" yotamake-edited) || exit 0
sid=$(hook_field session_id <<<"$in")
printf '%s\n' "${sid:-unknown}" > "$marker" 2>/dev/null
exit 0
