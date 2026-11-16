#!/usr/bin/env bash
# Feeds fake tool calls to the plugin's hooks and checks each exit code
# (0 lets the edit through, 2 blocks it). Prints failures only; exit 1 if any.
set -uo pipefail
# Run from the pre-commit hook, git exports these for this repository; the test repositories
# below must not inherit them.
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_PREFIX
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
read_call() { printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$1"; }
expect 2 pre-edit-protect.sh "$(read_call "$p/.env")"          # reads are refused too
expect 0 pre-edit-protect.sh "$(read_call "$p/.env.example")"
expect 0 pre-edit-protect.sh "$(read_call "$p/src/app.js")"

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
# project.conf's main-branch wins over CLAUDE.md (ADR-0008); a broken line is skipped.
printf -- '# facts\nmain-branch feat/x # comment\n' > "$r/.claude/yotamake/project.conf"
expect 0 pre-edit-main-branch.sh "$r/a.js"                    # conf names another main
git -C "$r" switch -q feat/x
expect 2 pre-edit-main-branch.sh "$r/a.js"                    # on the conf's main
printf 'main-branch\nmain-branch a b\n' > "$r/.claude/yotamake/project.conf"
git -C "$r" switch -q trunk
expect 2 pre-edit-main-branch.sh "$r/a.js"                    # no usable key: CLAUDE.md's line
rm "$r/.claude/yotamake/project.conf"
git init -q -b main "$tmp/empty"
expect 0 pre-edit-main-branch.sh "$tmp/empty/a.js"            # no commits yet

# --- pre-bash-git.sh -----------------------------------------------------------
# bash_call <command> [cwd]: the hook input for a Bash call.
bash_call() { node -e 'process.stdout.write(JSON.stringify({cwd: process.argv[2] || undefined, tool_input: {command: process.argv[1]}}))' "$1" "${2:-}"; }
b=$tmp/bash
# git_expect <exit code> <command> [cwd, default $b]
git_expect() { expect "$1" pre-bash-git.sh "$(bash_call "$2" "${3:-$b}")"; }
git init -q -b main "$b" && git -C "$b" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
mkdir -p "$b/sub"
git_expect 2 'git commit -m x'                  # on main
git_expect 2 'git add a && git commit -am "x"' "$b/sub"   # compound, subfolder
git_expect 2 "git -C $b commit -m x" "$tmp"          # git -C
git_expect 2 "cd $b && git commit -m x" "$tmp"       # cd first
git_expect 2 '{ git commit -m x; }'             # wrapped forms (backlog, 2026-11-16)
git_expect 2 'if true; then git commit -m x; fi'
git_expect 2 'for f in a; do git commit -m x; done'
git_expect 2 'time git commit -m x'
git_expect 2 'time -p git commit -m x'
git_expect 2 'nohup git commit -m x'
git_expect 2 '! git commit -m x'
git_expect 2 'env A=1 git commit -m x'
git_expect 2 'env -u HOME git commit -m x'
git_expect 2 'bash -c "git commit -m x"'
git_expect 2 "sh -c 'cd sub && git commit -m x'"
git_expect 2 "/bin/bash -lc 'git add a; git commit -m x'"
git_expect 0 'bash -c "echo git commit"'          # quoted text inside the script
git_expect 0 'bash script.sh commit'              # no -c: not read
git_expect 2 "bash -c 'cd $tmp'; git commit -m x"   # a cd inside the script stays there
git_expect 0 'command -v git && echo commit'      # a lookup, not a git call
git_expect 0 'git status'                       # not a commit
git_expect 0 'echo "git commit"'                # quoted text
git_expect 0 'git commit -m x' "$tmp"                # not a repository
git -C "$b" switch -q -c feat/x
git_expect 0 'git commit -m x'                  # on a branch
git_expect 2 'git commit --no-verify -m x'      # skips the hook
git_expect 2 'git commit -anm x'                # -n in a cluster
git_expect 2 'git push --no-verify'
git_expect 2 'git merge --squash --no-verify x'   # --squash takes no value here
git_expect 2 'git status; git -c a=b commit -n'
git_expect 2 'env git commit --no-verify -m x'
git_expect 2 'bash -c "git commit --no-verify -m x"'
git_expect 2 "bash -c 'bash -c \"git push --no-verify\"'"   # nested
git_expect 0 'bash -c "unclosed'                 # cannot read the script: let through
git_expect 0 'git commit -m "docs: mention --no-verify"'   # in the message
git_expect 0 'git commit -mn'                   # n is the message
git_expect 0 'git commit -m -n'                 # so is -n here
git_expect 0 'git push -n'                      # push -n is a dry run
git_expect 0 'git commit -m "unclosed'          # cannot read: let through
git -C "$b" switch -q main
mh=$(git -C "$b" rev-parse --absolute-git-dir)/MERGE_HEAD
git -C "$b" rev-parse HEAD > "$mh"
git_expect 0 'git commit --no-edit'             # finishing a merge
rm "$mh"
mkdir -p "$b/.claude/yotamake" && touch "$b/.claude/yotamake/allow-edits-on-main"
git_expect 0 'git commit -m x'                  # opted out
git_expect 2 'git commit --no-verify -m x'      # but never --no-verify
git_expect 0 'git commit -m x' "$tmp/empty"     # no commits yet

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
printf '{}\n' > "$g/src/n.ipynb"
expect 0 post-edit-mark.sh "$(printf '{"session_id":"s1","tool_input":{"notebook_path":"%s"}}' "$g/src/n.ipynb")"
[[ $(cat "$marker" 2>/dev/null) == s1 ]] || { echo "FAIL post-edit-mark.sh: a notebook edit not marked"; failed=1; }
rm -f "$marker"
expect 0 post-edit-mark.sh "$(edit s1 "$g/src/a.js")"
expect 2 stop-check-ran.sh "$(stop s1)"                   # code edited, no check yet
expect 0 stop-check-ran.sh "$(stop s1 true)"              # already continuing: block once
expect 0 stop-check-ran.sh "$(stop s2)"                   # another session's edit
sleep 0.05; (cd "$g" && bash scripts/check)
expect 0 stop-check-ran.sh "$(stop s1)"                   # check passed after the edit
sleep 0.05; expect 0 post-edit-mark.sh "$(edit s1 "$g/src/a.js")"
expect 2 stop-check-ran.sh "$(stop s1)"                   # edited again after the pass
# project.conf's docs globs replace the default rule (ADR-0008).
rm -f "$marker"
mkdir -p "$g/.claude/yotamake" "$g/guides/sub" && printf 'x\n' > "$g/guides/sub/g.md"
printf 'x\n' > "$g/AGENTS.md"
printf 'docs guides/*\ndocs *.md\ndocs !AGENTS.md\n' > "$g/.claude/yotamake/project.conf"
for f in guides/sub/g.md README.md CLAUDE.md; do
    expect 0 post-edit-mark.sh "$(edit s1 "$g/$f")"
done
[[ -f $marker ]] && { echo "FAIL post-edit-mark.sh: a doc by project.conf was marked"; failed=1; }
expect 0 post-edit-mark.sh "$(edit s1 "$g/docs/x.md")"   # docs/ is not in this conf's globs
[[ $(cat "$marker" 2>/dev/null) == s1 ]] || { echo "FAIL post-edit-mark.sh: docs/x.md not marked by project.conf"; failed=1; }
rm -f "$marker"
expect 0 post-edit-mark.sh "$(edit s1 "$g/AGENTS.md")"   # an exception wins
[[ $(cat "$marker" 2>/dev/null) == s1 ]] || { echo "FAIL post-edit-mark.sh: a ! exception not marked"; failed=1; }
rm -f "$marker"
# The template's conf gives the same answers as the built-in default rule.
cp "$hooks/../template/.claude/yotamake/project.conf" "$g/.claude/yotamake/project.conf"
for f in docs/x.md README.md; do expect 0 post-edit-mark.sh "$(edit s1 "$g/$f")"; done
[[ -f $marker ]] && { echo "FAIL post-edit-mark.sh: a doc by the template conf was marked"; failed=1; }
expect 0 post-edit-mark.sh "$(edit s1 "$g/CLAUDE.md")"
[[ $(cat "$marker" 2>/dev/null) == s1 ]] || { echo "FAIL post-edit-mark.sh: CLAUDE.md not marked by the template conf"; failed=1; }
rm -f "$marker" "$g/.claude/yotamake/project.conf"
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
mkdir -p "$c/.claude/yotamake" && printf 'main-branch master\n' > "$c/.claude/yotamake/project.conf"
ctx_has "reads the main branch from project.conf first" '^Branch: trunk \(not the main branch, master\)'
rm "$c/.claude/yotamake/project.conf"
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

# --- session-upgrades.sh: one line when the repo's harness is older (ADR-0004) ---
u=$tmp/upgrades
git init -q "$u" && mkdir -p "$u/.claude/yotamake" "$u/sub"
pv=$(node -p 'require(process.argv[1]).version' "$hooks/../.claude-plugin/plugin.json")
# up_check <want lines> <name> [project dir]: the hook exits 0, prints that many lines, and
# any line names the step. Leaves the output in $up_out.
up_check() {
    local status n
    up_out=$(CLAUDE_PROJECT_DIR="${3:-$u/sub}" bash "$hooks/session-upgrades.sh" </dev/null 2>&1); status=$?
    n=$(grep -c . <<<"$up_out")
    [[ $status -eq 0 && $n == "$1" ]] && { [[ $1 == 0 ]] || grep -qF 'simple-session, "Harness upgrades"' <<<"$up_out"; } ||
        { echo "FAIL session-upgrades.sh $2: status $status, output '$up_out'"; failed=1; }
}
up_check 0 "is quiet in a repo without the harness"
mkdir -p "$u/scripts" && touch "$u/scripts/check"
up_check 1 "speaks when the version file is missing"
echo 0.1.0 > "$u/.claude/yotamake/version"
up_check 1 "speaks when the repo is older"
grep -qF "is 0.1.0; the plugin is $pv" <<<"$up_out" ||
    { echo "FAIL session-upgrades.sh does not name both versions"; failed=1; }
echo "$pv" > "$u/.claude/yotamake/version"
up_check 0 "is quiet when the versions match"
echo 999.0.0 > "$u/.claude/yotamake/version"
up_check 0 "is quiet when the repo is newer"
echo 0.9.0 > "$u/.claude/yotamake/version"
up_check 1 "compares numbers, not text"
echo 1.x > "$u/.claude/yotamake/version"
up_check 1 "speaks when it cannot compare"
grep -qF "could not compare" <<<"$up_out" || { echo "FAIL session-upgrades.sh unclear when it cannot compare"; failed=1; }
up_check 0 "is quiet outside a repository" "$tmp/none"
mkdir -p "$tmp/nogit" && printf '#!/bin/sh\nexit 128\n' > "$tmp/nogit/git" && chmod +x "$tmp/nogit/git"
echo 0.1.0 > "$u/.claude/yotamake/version"
PATH="$tmp/nogit:$PATH" up_check 1 "falls back to the project directory without git" "$u"

# --- From a linked worktree (ADR-0005) -----------------------------------------
# Claude Code's CLAUDE_PROJECT_DIR stays at the main worktree after EnterWorktree, while the
# hook input's cwd follows the worktree. The hooks must act on the worktree.
m=$tmp/wt-main w=$tmp/wt-feat
git init -q -b main "$m"
mkdir -p "$m/.claude/yotamake" "$m/scripts" "$m/.scratchpad/2026-02-02-e"
printf 'config/secrets/*\n' > "$m/.claude/yotamake/protected-paths.conf"
printf 'touch "$(git rev-parse --git-path yotamake-check-passed)"\n' > "$m/scripts/check"
printf '.scratchpad/\n' > "$m/.gitignore"
git -C "$m" add -A && git -C "$m" -c user.name=t -c user.email=t@t commit -q -m init
printf '## S1 — Shared — `todo`\n' > "$m/.scratchpad/2026-02-02-e/plan.md"
git -C "$m" worktree add -q -b feat/y "$w"
mkdir -p "$w/src" "$w/sub"
printf 'x\n' > "$w/src/a.bad"
printf '*.bad false {file}\n' > "$w/.claude/yotamake/post-edit-checks.conf"   # this tree only
export CLAUDE_PROJECT_DIR=$m
# wt_call <session id> [file]: hook input from the worktree, for that session and file.
wt_call() { node -e 'const [s, c, f] = process.argv.slice(1); process.stdout.write(JSON.stringify({session_id: s, cwd: c, stop_hook_active: false, tool_input: f ? {file_path: f} : undefined}))' "$1" "$w" "${2:-}"; }
expect 2 pre-edit-protect.sh "$w/config/secrets/db.txt"         # slash pattern, other tree
expect 2 pre-edit-protect.sh "$(wt_call s1 "$w/config/secrets/db.txt")"
expect 2 post-edit-check.sh "$(wt_call s1 "$w/src/a.bad")"     # the worktree's conf
expect 0 post-edit-mark.sh "$(wt_call s1 "$w/src/a.bad")"
expect 2 stop-check-ran.sh "$(wt_call s1)"                     # the worktree's marker
sleep 0.05; (cd "$w" && bash scripts/check)
expect 0 stop-check-ran.sh "$(wt_call s1)"                     # the worktree's stamp
# From the main tree, an edit by absolute path into the worktree marks the worktree.
main_stop() { printf '{"session_id":"%s","cwd":"%s","stop_hook_active":false}' "$1" "$m"; }
sleep 0.05; expect 0 post-edit-mark.sh "$(edit s2 "$w/src/a.bad")"
expect 2 stop-check-ran.sh "$(main_stop s2)"                   # the other tree's marker
out=$(main_stop s2 | bash "$hooks/stop-check-ran.sh" 2>&1)
grep -qF "$w" <<<"$out" || { echo "FAIL stop-check-ran.sh does not name the worktree: '$out'"; failed=1; }
expect 0 stop-check-ran.sh "$(main_stop s3)"                   # another session's edit there
sleep 0.05; (cd "$w" && bash scripts/check)
expect 0 stop-check-ran.sh "$(main_stop s2)"                   # checked in the worktree
git -C "$m" worktree add -q -b feat/z "$tmp/wt-gone"
sleep 0.05; expect 0 post-edit-mark.sh "$(edit s2 "$tmp/wt-gone/scripts/check")"
expect 2 stop-check-ran.sh "$(main_stop s2)"
rm -rf "$tmp/wt-gone"
expect 0 stop-check-ran.sh "$(main_stop s2)"                   # its folder is gone
plugin_version=$(node -p 'require(process.argv[1]).version' "$hooks/../.claude-plugin/plugin.json")
printf '%s\n' "$plugin_version" > "$m/.claude/yotamake/version"
printf '0.1.0\n' > "$w/.claude/yotamake/version"
out=$(wt_call s1 | bash "$hooks/session-upgrades.sh" 2>&1)
grep -qF "harness is 0.1.0" <<<"$out" ||
    { echo "FAIL session-upgrades.sh does not read the worktree's version: '$out'"; failed=1; }
out=$(cd "$w/sub" && bash "$scx" 2>&1)
grep -qF "Worktree of $m;" <<<"$out" && grep -qxF "  $m/.scratchpad/2026-02-02-e: next is S1 — Shared" <<<"$out" ||
    { echo "FAIL session-context.sh from a worktree: '$out'"; failed=1; }
out=$(cd "$m" && bash "$scx" 2>&1)
grep -qF "Worktree of" <<<"$out" &&
    { echo "FAIL session-context.sh calls the main worktree a worktree: '$out'"; failed=1; }
unset CLAUDE_PROJECT_DIR

# --- hooks.json registers each hook for every tool it covers --------------------
node -e '
const h = require(process.argv[1]).hooks;
const has = (ev, hook, tool) => (h[ev] || []).some((e) =>
    new RegExp("^(" + e.matcher + ")$").test(tool) && JSON.stringify(e.hooks).includes(hook));
const want = [["PreToolUse", "pre-edit-protect.sh", "Read"]];
for (const t of ["Edit", "Write", "MultiEdit", "NotebookEdit"]) {
    for (const k of ["pre-edit-protect.sh", "pre-edit-main-branch.sh"]) want.push(["PreToolUse", k, t]);
    for (const k of ["post-edit-check.sh", "post-edit-mark.sh"]) want.push(["PostToolUse", k, t]);
}
const miss = want.filter((w) => !has(...w));
for (const m of miss) console.log("FAIL hooks.json: " + m[1] + " not registered for " + m[2]);
process.exit(miss.length ? 1 : 0);' "$hooks/hooks.json" || failed=1

# --- Every hook lets the edit through when it cannot read the tool call ---------
for hook in pre-edit-protect.sh pre-edit-main-branch.sh pre-bash-git.sh post-edit-check.sh post-edit-mark.sh stop-check-ran.sh; do
    echo 'not json' | bash "$hooks/$hook" >/dev/null 2>&1 ||
        { echo "FAIL $hook: unreadable input should exit 0"; failed=1; }
done

exit $failed
