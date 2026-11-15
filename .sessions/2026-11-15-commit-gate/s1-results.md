# S1 results — container (`claude -p`)

Claude Code 2.1.325, 2026-11-15, model claude-haiku-5-5, throwaway repos, stub hooks that
print a fixed decision. In `-p` there is no prompt: an "ask" ends as a refusal (a permission
denial), so "refused" below means the call would have asked or been denied. Scripts:
`scratchpad/s1/run.sh` and `cases.sh` (not kept); the commit is `git commit --allow-empty -m test`.

The project's `permissions.allow` is ignored in an untrusted folder under `-p` (Claude Code
prints a warning), so the broad allow rule comes from `--settings` (a higher-priority source
than project and user settings) or `--allowedTools`.

| Case | Setup | Result |
|---|---|---|
| b0 | no rules, no hook | refused (control) |
| b1 | `Bash(git:*)` allow via `--settings` | ran (control: the allow rule works) |
| b4 | `Bash(git:*)` via `--allowedTools` | ran (control) |
| b3 | project `ask` rule + `--settings` allow | refused (today's behaviour) |
| h1 | hook "allow", no rules | ran: a project hook runs in an untrusted folder, and its "allow" approves |
| h2 | hook "allow" + `ask` rule | refused: "allow" does not pass `ask` |
| h3 | hook "allow" + `deny` rule | refused |
| m7 | hook "allow" + `deny` rule, `bypassPermissions` | refused |
| h4 | hook "ask" + `--settings` allow | refused: "ask" holds under a higher-priority allow |
| h5 | hook "ask" + project and `--settings` allow | refused |
| h6 | hook "ask" + `--allowedTools` | refused |
| w0 | plain hook command, script missing | **ran: fails open** |
| w1 | fail-closed wrapper, script missing | refused |
| w2 | wrapper, script exits 1 | refused |
| w3 | wrapper, script prints nothing | refused |
| w4 | wrapper, script says "allow" | ran |
| w5 | script hangs past `timeout: 3`, no `onFailure` | **ran: a timeout fails open** |
| w6 | hangs, `onFailure: "block"` | refused |
| w7 | wrapper + hangs + `onFailure: "block"` | refused |
| m1 | `disableAllHooks` + allow (both via `--settings`), hook "ask" | **ran: hooks off, no stop** |
| m2 | `ask` rule, `bypassPermissions` | refused (in `-p`) |
| m3 | hook "ask", `bypassPermissions` | refused (in `-p`): same as m2 |
| m4 | hook "ask" + allow, `acceptEdits` | refused |
| m5 | hook "ask" + allow, `dontAsk` | refused |
| m6 | hook "allow", `dontAsk` | ran |
| g0 | `touch yotamake-x`, `Bash(touch:*)` allowed | ran (control) |
| g1 | `touch .git/yotamake-x`, `Bash(touch:*)` allowed | refused: `.git/` protection covers Bash writes |
| g2 | `touch .git/yotamake-x`, `bypassPermissions` | ran (file created) |

Not tested here: a real interactive prompt (see `local-tests.sh`), managed settings, and
`allowManagedHooksOnly`.
