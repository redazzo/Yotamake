#!/usr/bin/env bash
# Feeds fake tool calls to the plugin's hooks and checks each exit code
# (0 lets the edit through, 2 blocks it). Prints failures only; exit 1 if any.
set -uo pipefail
hooks="$(cd "$(dirname "$0")/../plugin/hooks" && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

# expect <exit code> <hook> <file path or whole JSON input> [env assignments...]
expect() {
    local want=$1 hook=$2 fp=$3; shift 3
    local got input=$fp
    [[ "$fp" == \{* ]] || input=$(printf '{"tool_input":{"file_path":"%s"}}' "$fp")
    printf '%s' "$input" | env "$@" bash "$hooks/$hook" >/dev/null 2>&1
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
expect 2 pre-edit-protect.sh "/x/.env" CLAUDE_PROJECT_DIR="$tmp/none"   # the template's list
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

# --- post-edit-mark.sh and stop-check-ran.sh -----------------------------------
edit() { printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2"; }
stop() { printf '{"session_id":"%s","stop_hook_active":%s}' "$1" "${2:-false}"; }
g=$tmp/gate
git init -q -b feat/x "$g"
mkdir -p "$g/scripts" "$g/docs" "$g/src" "$g/.scratchpad"
printf 'touch "$(git rev-parse --git-path yotamake-check-passed)"\n' > "$g/scripts/check"
printf '.scratchpad/\n' > "$g/.gitignore"
for f in src/a.js docs/x.md README.md CLAUDE.md .scratchpad/plan.md; do printf 'x\n' > "$g/$f"; done
export CLAUDE_PROJECT_DIR=$g
marker=$g/.git/yotamake-edited stamp=$g/.git/yotamake-check-passed
expect 0 stop-check-ran.sh "$(stop s1)"                   # nothing edited: a question
for f in docs/x.md README.md .scratchpad/plan.md; do
    expect 0 post-edit-mark.sh "$(edit s1 "$g/$f")"
done
[[ -f $marker ]] && { echo "FAIL post-edit-mark.sh: a doc or ignored file was marked"; failed=1; }
ln -s "$g" "$tmp/gate-link"
expect 0 post-edit-mark.sh "$(edit s1 "$tmp/gate-link/docs/x.md")"   # a doc through a symlink
[[ -f $marker ]] && { echo "FAIL post-edit-mark.sh: a doc or ignored file was marked"; failed=1; }
expect 0 post-edit-mark.sh "$(edit s1 "$g/CLAUDE.md")"   # CLAUDE.md is code
[[ $(cat "$marker" 2>/dev/null) == s1 ]] || { echo "FAIL post-edit-mark.sh: CLAUDE.md not marked"; failed=1; }
rm -f "$marker"
expect 0 post-edit-mark.sh "$(edit s1 "$g/src/a.js")"
expect 2 stop-check-ran.sh "$(stop s1)"                   # code edited, no check yet
expect 0 stop-check-ran.sh "$(stop s1 true)"              # already continuing: block once
expect 0 stop-check-ran.sh "$(stop s2)"                   # another session's edit
sleep 0.05; (cd "$g" && bash scripts/check)
expect 0 stop-check-ran.sh "$(stop s1)"                   # check passed after the edit
sleep 0.05; expect 0 post-edit-mark.sh "$(edit s1 "$g/src/a.js")"
expect 2 stop-check-ran.sh "$(stop s1)"                   # edited again after the pass
: > "$g/scripts/check"
expect 0 stop-check-ran.sh "$(stop s1)"                   # an older scripts/check: no stamp
expect 0 stop-check-ran.sh "$(stop s1)" CLAUDE_PROJECT_DIR="$tmp/none"   # not a repository
unset CLAUDE_PROJECT_DIR

# --- Every hook lets the edit through when it cannot read the tool call ---------
for hook in pre-edit-protect.sh pre-edit-main-branch.sh post-edit-check.sh post-edit-mark.sh stop-check-ran.sh; do
    echo 'not json' | bash "$hooks/$hook" >/dev/null 2>&1 ||
        { echo "FAIL $hook: unreadable input should exit 0"; failed=1; }
done

exit $failed
