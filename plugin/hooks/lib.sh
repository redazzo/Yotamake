# Shared by the plugin's hooks, which source it from their own directory.

# hook_field <key>...: print the first non-empty of the given keys from the hook input on
# stdin, or nothing when none is set or the JSON cannot be read. A key may be a dotted path
# (tool_input.file_path).
hook_field() {
    node -e '
let d = {};
try { d = JSON.parse(require("fs").readFileSync(0, "utf8")) || {}; } catch {}
for (const k of process.argv.slice(1)) {
    const v = k.split(".").reduce((o, p) => (o && typeof o === "object" ? o[p] : undefined), d);
    if (v !== undefined && v !== null && v !== "") { process.stdout.write(String(v)); break; }
}
' "$@" 2>/dev/null
}

# tool_file_path: print the path the tool call on stdin edits (its file_path or
# notebook_path), or nothing when there is none or the JSON cannot be read.
tool_file_path() { hook_field tool_input.file_path tool_input.notebook_path; }

# repo_path_of <path>: print the repository's top level and the path from it, one per line.
# The file and its directories need not exist yet; it starts from the nearest existing
# directory. Fails when the path is not in a git repository.
repo_path_of() {
    local dir rest=${1##*/} out prefix=""
    dir=$(dirname "$1")
    while [[ ! -d "$dir" && "$dir" != / && "$dir" != . ]]; do
        rest="${dir##*/}/$rest"
        dir=$(dirname "$dir")
    done
    [[ -d "$dir" ]] || return 1
    out=$(git -C "$dir" rev-parse --show-toplevel --show-prefix 2>/dev/null) || return 1
    [[ "$out" == *$'\n'* ]] && prefix=${out#*$'\n'}
    printf '%s\n%s%s\n' "${out%%$'\n'*}" "$prefix" "$rest"
}

# gate_file <repo root> <name>: print the absolute path of <name> in the repository's git
# directory (per worktree). The gate files:
#   yotamake-check-passed  touched by the project's scripts/check when it passes
#   yotamake-edited        holds the id of the last session that edited a code file
gate_file() {
    local p
    p=$(git -C "$1" rev-parse --git-path "$2" 2>/dev/null) || return 1
    [[ "$p" == /* ]] || p="$1/$p"
    printf '%s' "$p"
}

# uses_gate_stamp <repo root>: true when the repository's scripts/check writes the stamp.
# Older installs do not, and then the gate hooks stay out of the way.
uses_gate_stamp() { grep -qs 'yotamake-check-passed' "$1/scripts/check"; }

# guarded_main_branch <repo root>: print the main branch the repository is on, and succeed;
# fail (printing nothing) when it is on another branch, has no commits yet, or works on main
# on purpose (an empty file at .claude/yotamake/allow-edits-on-main). The main branch is read
# from CLAUDE.md's "- **Main branch:** `<name>`" line; without one, both main and master
# count. A detached HEAD counts when it sits at a main branch's tip.
guarded_main_branch() {
    local main m branch head
    [[ -f "$1/.claude/yotamake/allow-edits-on-main" ]] && return 1
    git -C "$1" rev-parse --verify -q HEAD >/dev/null || return 1
    main=$(sed -n 's/^[-*][[:space:]]*\*\*Main branch:\*\*[[:space:]]*`\([^`]*\)`.*/\1/p' "$1/CLAUDE.md" 2>/dev/null | head -n1)
    if branch=$(git -C "$1" symbolic-ref --short -q HEAD); then
        for m in ${main:-main master}; do
            [[ "$branch" == "$m" ]] && { printf '%s' "$m"; return 0; }
        done
    else
        head=$(git -C "$1" rev-parse HEAD)
        for m in ${main:-main master}; do
            [[ "$(git -C "$1" rev-parse -q --verify "refs/heads/$m")" == "$head" ]] &&
                { printf '%s (detached HEAD at its tip)' "$m"; return 0; }
        done
    fi
    return 1
}

# MAIN_OPT_OUT: the sentence both main-branch hooks end their message with.
MAIN_OPT_OUT="If this repository works on main on purpose, the user can create .claude/yotamake/allow-edits-on-main."
