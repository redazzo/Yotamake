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

# --- set-hooks-path.sh: the template's SessionStart hook (ADR-0004) -------------
shp="$hooks/../template/.claude/yotamake/set-hooks-path.sh"
# hp_case <name> <want: set|unset|keep> <want output: notice|none> [setup commands...]
# Runs the hook in a fresh repository with .githooks/pre-commit, after the setup.
hp_case() {
    local name=$1 want=$2 say=$3 r out status value; shift 3
    r=$(mktemp -d "$tmp/hp.XXXX")
    git init -q "$r" && mkdir -p "$r/.githooks" && : > "$r/.githooks/pre-commit"
    (cd "$r" && for c in "$@"; do eval "$c"; done)
    out=$(cd "$r/.githooks" && bash "$shp" 2>&1); status=$?   # from a subfolder too
    value=$(git -C "$r" config --get core.hooksPath)
    local ok=1
    [[ $status -eq 0 ]] || ok=0
    case $want in
        set) [[ "$value" == .githooks && "$(git -C "$r" config --local --get core.hooksPath)" == .githooks ]] || ok=0 ;;
        unset) [[ -z "$value" ]] || ok=0 ;;
        keep) [[ "$value" == mine ]] || ok=0 ;;
    esac
    if [[ $say == notice ]]; then
        [[ $(wc -l <<<"$out") -eq 1 ]] && grep -q '"systemMessage".*git config --unset core.hooksPath' <<<"$out" || ok=0
    else
        [[ -z "$out" ]] || ok=0
    fi
    [[ $ok -eq 1 ]] || { echo "FAIL set-hooks-path.sh $name: status $status, value '$value', output '$out'"; failed=1; }
}
export GIT_CONFIG_GLOBAL=$tmp/gitconfig GIT_CONFIG_NOSYSTEM=1
: > "$GIT_CONFIG_GLOBAL"
hp_case "sets it in a clean clone" set notice
hp_case "leaves a local value" keep none 'git config core.hooksPath mine'
hp_case "leaves a global value" keep none 'git config --global core.hooksPath mine'
git config --global --unset core.hooksPath
hp_case "leaves pre-commit alone" unset none ': > .pre-commit-config.yaml'
hp_case "leaves lefthook alone" unset none ': > lefthook.yml'
hp_case "leaves a hook in .git/hooks alone" unset none ': > .git/hooks/pre-commit'
hp_case "needs .githooks/pre-commit" unset none 'rm .githooks/pre-commit'
hp_case "is quiet on a second run" set none 'git config core.hooksPath .githooks'
# session_start_basics <script>: what every SessionStart script in the template must do.
# Quiet outside a repository; its hook command exits 0 and prints nothing when the
# script is missing; it does not need the plugin.
session_start_basics() {
    local name=${1##*/} out status cmd
    out=$(cd "$tmp" && bash "$1" 2>&1); status=$?
    [[ $status -eq 0 && -z "$out" ]] || { echo "FAIL $name outside a repository: status $status, output '$out'"; failed=1; }
    cmd=$(node -p 'require(process.argv[1]).hooks.SessionStart.flatMap((e) => e.hooks)
        .find((h) => h.command.includes(process.argv[2])).command' "$hooks/../template/.claude/settings.json" "$name")
    out=$(CLAUDE_PROJECT_DIR="$tmp/none" bash -c "$cmd" 2>&1); status=$?
    [[ $status -eq 0 && -z "$out" ]] || { echo "FAIL $name hook command with no script: status $status, output '$out'"; failed=1; }
    grep -q CLAUDE_PLUGIN_ROOT "$1" && { echo "FAIL $name must not need the plugin"; failed=1; }
}
session_start_basics "$shp"
unset GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM

# --- session-context.sh: the template's SessionStart context lines (ADR-0004) ---
scx="$hooks/../template/.claude/yotamake/session-context.sh"
c=$tmp/context
git init -q -b main "$c" && git -C "$c" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init && mkdir "$c/sub"
# ctx_has / ctx_lacks <name> <regex>: the script, run from a subfolder, exits 0 and its
# output does or does not match.
ctx_check() {
    local want=$1 name=$2 out status found=no; shift 2
    out=$(cd "$c/sub" && bash "$scx" 2>&1); status=$?
    grep -qE -- "$1" <<<"$out" && found=yes
    [[ $status -eq 0 && $found == "$want" ]] ||
        { echo "FAIL session-context.sh $name: status $status, output '$out'"; failed=1; }
}
ctx_has() { ctx_check yes "$@"; }
ctx_lacks() { ctx_check no "$@"; }
ctx_has "says main is main without CLAUDE.md" '^Branch: main, the main branch'
git -C "$c" switch -q -c master
ctx_has "counts master too without CLAUDE.md" '^Branch: master, the main branch'
printf -- '- **Main branch:** `trunk`. Work on branches.\n' > "$c/CLAUDE.md"
ctx_has "reads the main branch from CLAUDE.md" '^Branch: master \(not the main branch, trunk\)'
git -C "$c" switch -q -c trunk
ctx_has "knows the CLAUDE.md main branch" '^Branch: trunk, the main branch'
expect 2 pre-edit-main-branch.sh "$c/a.txt"   # the edit hook agrees on the main branch
git -C "$c" switch -q -c feat/x
ctx_has "names a feature branch" '^Branch: feat/x \(not the main branch, trunk\)'
git -C "$c" switch -q --detach
ctx_has "says when HEAD is detached" '^Branch: none \(detached HEAD at [0-9a-f]+\)'
ctx_lacks "prints nothing about efforts without one" 'efforts'
ctx_has "prints the session rule" 'yotamake:simple-session.*yotamake:multi-session'
mkdir -p "$c/.scratchpad/2026-01-01-a" "$c/.sessions/2026-01-02-b" "$c/.scratchpad/no-plan"
printf '## Design\n\n## S1 — First (F1) — `done`\n\n## S2 — Second (F2) — `todo`\n\n## S3 — Third — `todo`\n' \
    > "$c/.scratchpad/2026-01-01-a/plan.md"
printf '## S1 — Only — `done`\n' > "$c/.sessions/2026-01-02-b/plan.md"
ctx_has "names an effort's next session" '^  \.scratchpad/2026-01-01-a: next is S2 — Second \(F2\)$'
ctx_has "names a committed effort that is all done" '^  \.sessions/2026-01-02-b: every session is done'
ctx_lacks "skips a folder without plan.md" 'no-plan'
for i in 1 2 3 4 5 6 7; do mkdir -p "$c/.scratchpad/x$i" && cp "$c/.sessions/2026-01-02-b/plan.md" "$c/.scratchpad/x$i/"; done
lines=$(cd "$c/sub" && bash "$scx" | wc -l)
[[ $lines -le 10 ]] || { echo "FAIL session-context.sh prints $lines lines with many efforts"; failed=1; }
ctx_has "says how many efforts it left out" '^  and 4 more$'
session_start_basics "$scx"

# --- Every hook lets the edit through when it cannot read the tool call ---------
for hook in pre-edit-protect.sh pre-edit-main-branch.sh post-edit-check.sh post-edit-mark.sh stop-check-ran.sh; do
    echo 'not json' | bash "$hooks/$hook" >/dev/null 2>&1 ||
        { echo "FAIL $hook: unreadable input should exit 0"; failed=1; }
done

exit $failed
