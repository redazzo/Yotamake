#!/usr/bin/env bash
# Feeds fake tool calls to the plugin's hooks and checks each exit code
# (0 lets the edit through, 2 blocks it). Prints failures only; exit 1 if any.
set -uo pipefail
hooks="$(cd "$(dirname "$0")/../plugin/hooks" && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

# expect <exit code> <hook> <file path> [env assignments...]
expect() {
    local want=$1 hook=$2 fp=$3; shift 3
    local got
    printf '{"tool_input":{"file_path":"%s"}}' "$fp" | env "$@" bash "$hooks/$hook" >/dev/null 2>&1
    got=$?
    if [[ $got != "$want" ]]; then
        echo "FAIL $hook ${fp#"$tmp"/}: want $want, got $got"
        failed=1
    fi
}

# --- pre-edit-protect.sh ------------------------------------------------------
p=$tmp/protect
mkdir -p "$p/.claude/yotamake"
cp "$hooks/../template/.claude/yotamake/protected-paths.conf" "$p/.claude/yotamake/"
printf 'config/secrets/*\n!config/secrets/README.md\n' >> "$p/.claude/yotamake/protected-paths.conf"
export CLAUDE_PROJECT_DIR=$p
expect 2 pre-edit-protect.sh "$p/.env"
expect 2 pre-edit-protect.sh "$p/sub/.env.local"
expect 0 pre-edit-protect.sh "$p/.env.example"
expect 2 pre-edit-protect.sh "$p/keys/server.pem"
expect 2 pre-edit-protect.sh "$p/.claude/yotamake/allow-edits-on-main"
expect 2 pre-edit-protect.sh "$p/config/secrets/db.txt"
expect 2 pre-edit-protect.sh "$p/config/secrets/a/b.txt"
expect 0 pre-edit-protect.sh "$p/config/secrets/README.md"
expect 0 pre-edit-protect.sh "$p/other/config/secrets/db.txt"
expect 0 pre-edit-protect.sh "/elsewhere/config/secrets/db.txt"
expect 0 pre-edit-protect.sh "$p/id_rsa_dir/notes.txt"
expect 0 pre-edit-protect.sh "$p/src/app.js"
expect 2 pre-edit-protect.sh "/x/.env" CLAUDE_PROJECT_DIR="$tmp/none"   # plugin default list
expect 0 pre-edit-protect.sh ""                               # no path: let it through

# --- pre-edit-main-branch.sh --------------------------------------------------
unset CLAUDE_PROJECT_DIR
r=$tmp/repo
git init -q -b main "$r"
git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m init
printf '.scratchpad/\n' > "$r/.gitignore"
expect 2 pre-edit-main-branch.sh "$r/src/new-dir/file.js"     # on main, file not there yet
expect 0 pre-edit-main-branch.sh "$r/.scratchpad/plan.md"     # git-ignored
expect 0 pre-edit-main-branch.sh "$tmp/outside.txt"           # not in a repository
git -C "$r" switch -q -c feat/x
expect 0 pre-edit-main-branch.sh "$r/a.js"                    # on a feature branch
git -C "$r" switch -q --detach main
expect 2 pre-edit-main-branch.sh "$r/a.js"                    # detached at main's tip
git -C "$r" switch -q main
mkdir -p "$r/.claude/yotamake" && touch "$r/.claude/yotamake/allow-edits-on-main"
expect 0 pre-edit-main-branch.sh "$r/a.js"                    # opted out
rm "$r/.claude/yotamake/allow-edits-on-main"
printf -- '- **Main branch:** `trunk`\n' > "$r/CLAUDE.md"
expect 0 pre-edit-main-branch.sh "$r/a.js"                    # CLAUDE.md names another main
git -C "$r" switch -q -c trunk
expect 2 pre-edit-main-branch.sh "$r/a.js"
git init -q -b main "$tmp/empty"
expect 0 pre-edit-main-branch.sh "$tmp/empty/a.js"            # no commits yet

# --- post-edit-check.sh -------------------------------------------------------
c=$tmp/check
mkdir -p "$c/.claude/yotamake"
printf 'x\n' > "$c/a.bad"; printf 'x\n' > "$c/a.good"; printf 'x\n' > "$c/a.other"
printf '# comment\n*.bad false {file}\n*.good test -f {file}\n*.good false\n' \
    > "$c/.claude/yotamake/post-edit-checks.conf"
export CLAUDE_PROJECT_DIR=$c
expect 2 post-edit-check.sh "$c/a.bad"              # failing check
expect 0 post-edit-check.sh "$c/a.good"             # first match wins
expect 0 post-edit-check.sh "$c/a.other"            # no rule
expect 0 post-edit-check.sh "$c/missing.bad"        # file gone
expect 0 post-edit-check.sh "$c/a.bad" CLAUDE_PROJECT_DIR="$tmp/none"   # no conf

exit $failed
