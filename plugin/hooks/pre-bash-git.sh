#!/usr/bin/env bash
# PreToolUse hook for Bash: refuse git commands the skills forbid.
#   - Any git command with --no-verify (or `git commit -n`), which skips the pre-commit
#     hook and so the gate (CLAUDE.md, Checks). A person can still run it with `! <command>`.
#   - `git commit` while the repository is on its main branch, read as
#     pre-edit-main-branch.sh reads it (`simple-session`, "Branch"). Finishing a merge
#     (MERGE_HEAD exists) is allowed, and so is a repository with
#     .claude/yotamake/allow-edits-on-main.
#   - `git commit` while a session step it needs is missing: the commit gate (ADR-0010).
#     The step evaluator (steps.mjs) decides by the "commit" row of steps.json: the check
#     has passed since the last edit, and both review skills ran in the review window,
#     unless the branch changes only docs or the message has a `Review-skipped:` trailer.
#     The message comes from -m/--message (several join as paragraphs, and the
#     `"$(cat <<'EOF' ... EOF)"` form is read), or -F/--file (a file, or `-` with the
#     command's first heredoc after "commit"). A message it cannot read counts as none.
#     Only the commit's own message counts, not other text in the command.
#     A commit that finishes a merge is not gated, as `git merge` is not: the edits that
#     resolved the conflicts still face the Stop gate. When the evaluator cannot decide,
#     the commit goes through.
# The command is split into simple commands with a small quote-aware parser; `cd <dir>` and
# `git -C <dir>` move the directory the next git command runs in. Shell keywords and
# wrappers in front of git (`{`, `then`, `do`, `time`, `env`, `nohup`, …) are skipped, and
# the script given to `bash -c` or `sh -c` is read the same way. When the command cannot
# be read (an unclosed quote, say), the hook lets it through. Exit 2 blocks the call and
# sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

input=$(cat)
# Only commit and --no-verify (or commit -n) can be refused: skip node for anything else.
[[ "$input" == *commit* || "$input" == *no-verify* ]] || exit 0

# The first line is the directory the command runs in. Then one line per git call:
# <dir, relative to that one unless absolute> TAB <subcommand> TAB <1 if it skips hooks,
# else 0> TAB <for a commit, its message as a JSON string, or null>. Prints nothing when
# the input or the command cannot be read.
calls=$(node -e '
const fs = require("fs");
let d;
try { d = JSON.parse(fs.readFileSync(0, "utf8")); } catch { process.exit(0); }
const base = d.cwd || process.env.CLAUDE_PROJECT_DIR || process.cwd();
// split(src): the simple commands in src, each a list of words, or null when it cannot be
// read (an unclosed quote).
const split = (src) => {
const cmds = [[]];
let word = null, quote = null;
const end = () => { if (word !== null) cmds[cmds.length - 1].push(word); word = null; };
for (let i = 0; i < src.length; i++) {
    const c = src[i];
    if (quote === "\x27") { if (c === quote) quote = null; else word += c; continue; }
    if (quote === "\"") {
        if (c === "\\" && i + 1 < src.length) word += src[++i];
        else if (c === quote) quote = null;
        else word += c;
        continue;
    }
    if (c === "\x27" || c === "\"") { quote = c; word = word ?? ""; continue; }
    if (c === "\\" && i + 1 < src.length) { word = (word ?? "") + src[++i]; continue; }
    if (/\s/.test(c) && c !== "\n") { end(); continue; }
    if (c === "\n" || c === ";" || c === "&" || c === "|" || c === "(" || c === ")") {
        end(); cmds.push([]); continue;
    }
    word = (word ?? "") + c;
}
if (quote) return null;
end();
return cmds;
};
const src = String(d?.tool_input?.command ?? "");
const cmds = split(src);
if (!cmds) process.exit(0);
// heredoc(s): the body of the first heredoc in s, or null.
const heredoc = (s) => {
    const m = /<<(-?)[ \t]*(["\x27]?)([A-Za-z_][A-Za-z0-9_]*)\2[^\n]*\n/.exec(s);
    if (!m) return null;
    const body = [];
    for (let l of s.slice(m.index + m[0].length).split("\n")) {
        if (m[1]) l = l.replace(/^\t+/, "");
        if (l.trim() === m[3]) return body.join("\n");
        body.push(l);
    }
    return null;
};
// The first heredoc after "commit", read from the command as written, since quotes inside
// it confuse split.
const commitHeredoc = () => heredoc(src.slice(Math.max(0, src.indexOf("commit"))));
// message(value): the text of a -m value, or null when the shell would fill it in.
const message = (v) => {
    if (v === undefined) return null;
    if (/^\$\(\s*cat\s+<</.test(v)) return commitHeredoc();
    return /\$[({A-Za-z_]|`/.test(v) ? null : v;
};
// messageFile(value, dir): the text of a -F value read from dir, or null.
const messageFile = (v, dir) => {
    if (v === undefined) return null;
    if (v === "-") return commitHeredoc();
    const from = dir.startsWith("/") ? dir : base + "/" + dir;
    try { return fs.readFileSync(v.startsWith("/") ? v : from + "/" + v, "utf8"); } catch { return null; }
};
const commitValueFlags = "mFcCt";
const valueLong = /^--(message|file|reuse-message|reedit-message|template|author|date|cleanup|trailer|fixup|squash)$/;
const join = (a, b) => (b.startsWith("/") ? b : a + "/" + b);
const out = [];
// Words that can stand before the command itself, and how many words each option of theirs
// takes: a shell keyword, a `{` group, `!`, or a wrapper that runs the rest of the line.
// Best effort: other wrappers (sudo, xargs, eval, $(…)) still hide git. The `ask` rules stay
// the guard for the commit itself.
const assign = /^[A-Za-z_][A-Za-z0-9_]*=/;
const lead = new Set(["{", "!", "if", "then", "elif", "else", "do", "while", "until", "time",
    "command", "exec", "nohup", "env"]);
const leadValueOpts = { env: ["-u", "-C", "-S"], exec: ["-a"] };
const shell = /(^|\/)(ba|da|z|k)?sh$/;
// walk(cmds, dir): add each git call in cmds to out. A `bash -c` script is walked with a
// copy of dir, so a `cd` inside it does not move the commands after it.
const walk = (cmds, dir) => {
for (let words of cmds) {
    while (words.length) {
        while (words.length && assign.test(words[0])) words = words.slice(1);
        const w = words[0];
        if (!lead.has(w)) break;
        let i = 1;
        while (i < words.length && (words[i].startsWith("-") || (w === "env" && assign.test(words[i])))) {
            i += (leadValueOpts[w] || []).includes(words[i]) ? 2 : 1;
        }
        // `command -v git` only looks git up.
        words = w === "command" && words.slice(1, i).some((o) => /^-[A-Za-z]*[vV]/.test(o)) ? [] : words.slice(i);
    }
    // bash -c "<script>": read the script as commands of its own.
    if (words.length && shell.test(words[0])) {
        const c = words.findIndex((w, k) => k > 0 && /^-[A-Za-z]*c[A-Za-z]*$/.test(w));
        const inner = c > 0 && words[c + 1] !== undefined ? split(words[c + 1]) : null;
        if (inner) walk(inner, dir);
        continue;
    }
    if (words[0] === "cd" && words[1]) { dir = join(dir, words[1]); continue; }
    if (!words.length || !/(^|\/)git$/.test(words[0])) continue;
    let i = 1, gdir = dir;
    for (; i < words.length && words[i].startsWith("-"); i++) {
        if (words[i] === "-C") gdir = join(gdir, words[++i] ?? "");
        else if (words[i] === "-c") i++;
    }
    const sub = words[i] ?? "";
    let skip = 0;
    const msgs = [];
    const take = (opt, v) => {
        if (opt === "m" || opt === "message") msgs.push(message(v));
        else if (opt === "F" || opt === "file") msgs.push(messageFile(v, gdir));
    };
    for (let j = i + 1; j < words.length; j++) {
        const w = words[j];
        if (w === "--") break;
        if (w === "--no-verify") { skip = 1; break; }
        if (sub !== "commit") continue;
        const eq = /^--(message|file)=([\s\S]*)$/.exec(w);
        if (eq) { take(eq[1], eq[2]); continue; }
        if (valueLong.test(w)) { take(w.slice(2), words[++j]); continue; }
        if (/^-[^-]/.test(w)) {
            let k = 1;
            for (; k < w.length; k++) {
                if (w[k] === "n") { skip = 1; break; }
                if (commitValueFlags.includes(w[k])) break;
            }
            if (skip) break;
            // The value is the rest of the word, or the next word.
            if (k < w.length) take(w[k], k === w.length - 1 ? words[++j] : w.slice(k + 1));
        }
    }
    const msg = msgs.length && !msgs.includes(null) ? msgs.join("\n\n") : null;
    out.push([gdir, sub, skip, sub === "commit" ? JSON.stringify(msg) : ""].join("\t"));
}
};
walk(cmds, ".");
if (out.length) process.stdout.write([base, ...out].join("\n"));
' <<<"$input" 2>/dev/null)
[[ -n "$calls" ]] || exit 0
{ read -r cwd; calls=$(cat); } <<<"$calls"

while IFS=$'\t' read -r dir sub skip msg; do
    if [[ $skip == 1 ]]; then
        echo "BLOCKED: this git command skips the pre-commit hook (--no-verify or commit -n). Fix what the hook reports instead. If the user asked to skip it, they can run the command themselves with '! <command>'." >&2
        exit 2
    fi
    [[ $sub == commit ]] || continue
    [[ "$dir" == /* ]] || dir="$cwd/$dir"
    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || continue
    git -C "$root" rev-parse -q --verify MERGE_HEAD >/dev/null && continue
    if on=$(guarded_main_branch "$root"); then
        echo "BLOCKED: $root is on its main branch '$on'. Commit on a branch (e.g. git switch -c fix/<topic>), then merge it. $MAIN_OPT_OUT" >&2
        exit 2
    fi
    missing=$(node "$here/steps.mjs" decide commit --tree "$root" --message-json "${msg:-null}" <<<"$input" 2>/dev/null | cut -f2)
    [[ -n "$missing" ]] || continue
    names=$(tr ',' '\n' <<<"$missing" | sed '/^check$/s//scripts\/check/; /^scripts\/check$/!s/^/\//' | paste -sd ',' - | sed 's/,/, /g')
    echo "BLOCKED: this commit is missing session steps in $root: $names (the commit gate, ADR-0010)." >&2
    case ,$missing, in *,check,*)
        echo "- scripts/check has not passed since the last edit: run it from $root and fix what fails." >&2 ;;
    esac
    [[ $missing == check ]] ||
        echo "- The review has not run on this change: run the missing review skills (simple-session, \"Review\"), fix what they find, then run scripts/check again. If the branch is trivial, or this is the release bump commit, add a trailer line to the commit message instead: 'Review-skipped: <reason>'." >&2
    exit 2
done <<<"$calls"
exit 0
