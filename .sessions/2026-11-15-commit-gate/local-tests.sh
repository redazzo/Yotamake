#!/usr/bin/env bash
# S1 local tests for ADR-0006: the cases that need a real permission prompt.
# Run on your own machine: bash local-tests.sh
# It makes four throwaway repos under a temp folder and prints how to open Claude Code in
# each. It changes nothing outside that folder (no user settings are touched).
set -eu
root=$(mktemp -d "${TMPDIR:-/tmp}/commit-gate-tests.XXXXXX")
ask_hook='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"stub ask (commit gate test)"}}'

mk() { # mk <name> <settings-json>
  local d="$root/$1"
  mkdir -p "$d/.claude"
  git -C "$d" init -q
  git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  printf '%s\n' "$2" >"$d/.claude/settings.json"
  printf '#!/bin/sh\ncat >/dev/null\nprintf %%s\\\\n %s\n' "'$ask_hook'" >"$d/.claude/ask.sh"
  chmod +x "$d/.claude/ask.sh"
}
hook='"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"\"$CLAUDE_PROJECT_DIR/.claude/ask.sh\""}]}]}'

mk L1-hook-ask-under-allow "{$hook}"
mk L2-bypass-ask-rule '{"permissions":{"ask":["Bash(git commit:*)"]}}'
mk L3-bypass-hook-ask "{$hook}"
mk L4-acceptedits-hook-ask "{$hook}"

allow="--settings '{\"permissions\":{\"allow\":[\"Bash(git:*)\"]}}'"
cat <<EOF
Made $root

In each folder, start Claude Code with the command shown, accept the trust dialog, and type:
  run: git commit --allow-empty -m test
Note whether Claude Code shows a permission prompt for the commit (answer No to it), then
quit. Report one line per case: prompt / no prompt (commit ran) / refused without a prompt.

L1  cd $root/L1-hook-ask-under-allow && claude $allow
    (hook says ask; a higher-priority allow rule covers git)          expect: prompt
L2  cd $root/L2-bypass-ask-rule && claude --permission-mode bypassPermissions
    (today's ask rule, no hook: the baseline for L3)                  expect: ?
L3  cd $root/L3-bypass-hook-ask && claude --permission-mode bypassPermissions
    (hook says ask)                                                   expect: same as L2
L4  cd $root/L4-acceptedits-hook-ask && claude --permission-mode acceptEdits $allow
    (hook says ask)                                                   expect: prompt

Afterwards: rm -rf $root
EOF
