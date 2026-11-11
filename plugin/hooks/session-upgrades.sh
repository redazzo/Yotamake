#!/usr/bin/env bash
# SessionStart hook: print one line to Claude's context when this repository's harness
# (.claude/yotamake/version; missing means set up before 0.11.0) is older than the plugin,
# so Claude runs `simple-session`, "Harness upgrades" (ADR-0004, amendment). Silent
# otherwise, and in a project without the harness. It always exits 0.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

# The session's directory (a worktree, say). Without git (denied, say), hook_root falls
# back to that directory itself, so a session is not told "up to date" by silence.
root=$(hook_root "$(cat)")
if [[ -f "$root/.claude/yotamake/version" ]]; then
    read -r repo < "$root/.claude/yotamake/version"
elif [[ -f "$root/scripts/check" ]]; then
    repo=""
else
    exit 0
fi
plugin=$(node -p 'require(process.argv[1]).version' "$here/../.claude-plugin/plugin.json" 2>/dev/null)

# older <a> <b>: true when version a comes before version b (both dotted numbers).
older() {
    local IFS=. i
    local -a a=($1) b=($2)
    for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
        ((10#${a[i]:-0} < 10#${b[i]:-0})) && return 0
        ((10#${a[i]:-0} > 10#${b[i]:-0})) && return 1
    done
    return 1
}

# Silence must mean "up to date", so say so when the versions cannot be compared.
v='^[0-9]+(\.[0-9]+)*$'
if [[ ! "${repo:-0}" =~ $v || ! "$plugin" =~ $v ]]; then
    echo "Harness upgrades: could not compare this repository's harness version (${repo:-none}) with the plugin's (${plugin:-unreadable}). Before the first change, run simple-session, \"Harness upgrades\", reading the versions yourself."
elif [[ -z "$repo" ]] || older "$repo" "$plugin"; then
    echo "Harness upgrades: this repository's harness is ${repo:-older than 0.11.0 (no .claude/yotamake/version)}; the plugin is $plugin. Before the first change, run simple-session, \"Harness upgrades\"."
fi
exit 0
