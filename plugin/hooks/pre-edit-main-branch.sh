#!/usr/bin/env bash
# PreToolUse hook for Edit/Write: refuse edits while the file's repository is on
# its main branch. Work happens on a branch cut from main (simple-session, step 2).
#
# The main branch is read from the repository's CLAUDE.md line
# "- **Main branch:** `<name>`"; without one, both main and master count.
# Files outside a git repository (scratchpad, /tmp) are always allowed, and so are
# git-ignored files (a multi-session .scratchpad/ folder, made on main) and a
# repository with no commits yet. A repository that works on main on purpose
# opts out with an empty file at .claude/yotamake/allow-edits-on-main.
# Exit 2 blocks the call and sends stderr back to Claude.

fp=$(node -e '
let d = {};
try { d = JSON.parse(require("fs").readFileSync(0, "utf8")).tool_input || {}; } catch {}
process.stdout.write(String(d.file_path || d.notebook_path || ""));
' 2>/dev/null)
[[ -n "$fp" ]] || exit 0

# The file may not exist yet: start from its nearest existing directory.
dir=$(dirname "$fp")
while [[ ! -d "$dir" && "$dir" != / && "$dir" != . ]]; do dir=$(dirname "$dir"); done
[[ -d "$dir" ]] || exit 0

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
[[ -f "$root/.claude/yotamake/allow-edits-on-main" ]] && exit 0
git -C "$root" rev-parse --verify -q HEAD >/dev/null || exit 0
git -C "$root" check-ignore -q -- "$fp" && exit 0
main=$(sed -n 's/^[-*][[:space:]]*\*\*Main branch:\*\*[[:space:]]*`\([^`]*\)`.*/\1/p' "$root/CLAUDE.md" 2>/dev/null | head -n1)
mains=${main:-main master}

# On a branch: block when it is a main branch. Detached: block when HEAD is a main branch's tip.
on=""
if branch=$(git -C "$root" symbolic-ref --short -q HEAD); then
    for m in $mains; do [[ "$branch" == "$m" ]] && on=$m; done
else
    head=$(git -C "$root" rev-parse HEAD)
    for m in $mains; do
        [[ "$(git -C "$root" rev-parse -q --verify "refs/heads/$m")" == "$head" ]] && on="$m (detached HEAD at its tip)"
    done
fi
[[ -n "$on" ]] || exit 0

echo "BLOCKED: $root is on its main branch '$on'. Cut a branch first (e.g. git switch -c fix/<topic>), then edit. If this repository works on main on purpose, the user can create .claude/yotamake/allow-edits-on-main." >&2
exit 2
