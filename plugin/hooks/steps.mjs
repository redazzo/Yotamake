#!/usr/bin/env node
// The step evaluator (ADR-0010). Hooks call it with the hook input on stdin:
//
//   node steps.mjs record edit|review|prompt
//       Append one event to the events log of the worktree it belongs to.
//   node steps.mjs decide stop|commit [--tree <dir>] [--message <text> | --message-json <json>]
//       Print one line per worktree with a missing step, "<tree>\t<step>,<step>", and
//       nothing when the action may go ahead. stop looks in every worktree of the
//       repository; commit in --tree, else the hook's own tree. --message is the commit
//       message, for the Review-skipped: trailer; --message-json gives it as a JSON string
//       (null: the message could not be read).
//
// The steps each action needs are in steps.json beside this file. The events log is
// yotamake-events in the worktree's git directory: one JSON line per event, in the order
// written, each with the HEAD it saw. An edit event goes to the edited file's worktree; a
// review or prompt event, which has no path, to the worktree of the hook's cwd. Only
// repositories whose scripts/check writes the yotamake-check-passed stamp get events.
//
// It never blocks by itself and always exits 0. Any error (unreadable input, log or git)
// prints nothing, which lets the action through: hooks let the action through when they
// cannot decide (CLAUDE.md, Boundaries).

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const LOG = 'yotamake-events';
const STAMP = 'yotamake-check-passed';
// The default Docs-only rule (CLAUDE.md, Branching and releases).
const DEFAULT_DOCS = ['docs/*', '*.md', '!CLAUDE.md'];
// Past this size the log keeps only its newer half.
const TRIM_BYTES = 512 * 1024;

// git <dir> <args...>: stdout without its last newline, or null when git fails.
function git(dir, ...args) {
  try {
    return execFileSync('git', ['-C', dir, ...args], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).replace(/\n$/, '');
  } catch {
    return null;
  }
}

const isDir = (p) => { try { return fs.statSync(p).isDirectory(); } catch { return false; } };
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch { return false; } };
const mtime = (p) => { try { return fs.statSync(p).mtimeMs; } catch { return null; } };

// readFact(root, key): each value of key in .claude/yotamake/project.conf, or null when
// the file or the key is missing. Same rules as read_fact in lib.sh (ADR-0008).
export function readFact(root, key) {
  let text;
  try { text = fs.readFileSync(path.join(root, '.claude/yotamake/project.conf'), 'utf8'); } catch { return null; }
  const vals = [];
  for (const line of text.split('\n')) {
    const w = line.replace(/#.*/, '').trim().split(/\s+/);
    if (w.length === 2 && w[0] === key) vals.push(w[1]);
  }
  return vals.length ? vals : null;
}

// globRegex(glob): a shell pattern as a RegExp; * and ? match / too, as in [[ == ]].
function globRegex(g) {
  let re = '';
  for (let i = 0; i < g.length; i++) {
    const c = g[i];
    if (c === '*') re += '.*';
    else if (c === '?') re += '.';
    else if (c === '[' && g.indexOf(']', i + 2) > 0) {
      const j = g.indexOf(']', i + 2);
      let body = g.slice(i + 1, j).replace(/\\/g, '\\\\');
      if (body[0] === '!') body = '^' + body.slice(1);
      re += `[${body}]`;
      i = j;
    } else re += c.replace(/[.+^${}()|[\]\\/]/g, '\\$&');
  }
  return new RegExp(`^${re}$`);
}

// isDoc(rel, globs): true when the path from the repository root is a doc by the docs
// globs. A glob with no / matches only files at the root. A ! glob is an exception and
// wins (ADR-0008).
export function isDoc(rel, globs = DEFAULT_DOCS) {
  let doc = false;
  for (const g of globs) {
    const neg = g.startsWith('!');
    const pat = neg ? g.slice(1) : g;
    const hit = (pat.includes('/') || !rel.includes('/')) && globRegex(pat).test(rel);
    if (hit && neg) return false;
    if (hit) doc = true;
  }
  return doc;
}

export const docGlobs = (root) => readFact(root, 'docs') ?? DEFAULT_DOCS;

// mainBranches(root): the main branch as the hooks read it: project.conf's main-branch,
// else CLAUDE.md's "Main branch" line, else main and master.
function mainBranches(root) {
  const conf = readFact(root, 'main-branch');
  if (conf) return [conf[0]];
  try {
    const m = fs.readFileSync(path.join(root, 'CLAUDE.md'), 'utf8')
      .match(/^[-*][ \t]*\*\*Main branch:\*\*[ \t]*`([^`]*)`/m);
    if (m) return [m[1]];
  } catch {}
  return ['main', 'master'];
}

// branchFiles(tree): the files the branch changes against the main branch, uncommitted and
// untracked ones included, or null when there is no merge base.
export function branchFiles(tree) {
  for (const b of mainBranches(tree)) {
    for (const ref of [b, `origin/${b}`]) {
      const base = git(tree, 'merge-base', 'HEAD', ref);
      if (!base) continue;
      const diff = git(tree, 'diff', '--name-only', base);
      const untracked = git(tree, 'ls-files', '--others', '--exclude-standard');
      if (diff === null || untracked === null) return null;
      return [...diff.split('\n'), ...untracked.split('\n')].filter(Boolean);
    }
  }
  return null;
}

const usesStamp = (root) => {
  try { return fs.readFileSync(path.join(root, 'scripts/check'), 'utf8').includes(STAMP); } catch { return false; }
};
const gitDir = (tree) => git(tree, 'rev-parse', '--absolute-git-dir');
const headOf = (tree) => git(tree, 'rev-parse', '-q', '--verify', 'HEAD');

// hookTree(input): the top level of the first set of the input's cwd, CLAUDE_PROJECT_DIR
// and the current directory (hook_root in lib.sh), or null outside a repository.
function hookTree(input) {
  const d = input.cwd || process.env.CLAUDE_PROJECT_DIR || process.cwd();
  return git(d, 'rev-parse', '--show-toplevel');
}

function loadTable() {
  return JSON.parse(fs.readFileSync(path.join(here, 'steps.json'), 'utf8'));
}

// reviewSkills(table): every step that is not the check, across all actions.
function reviewSkills(table) {
  const s = new Set();
  for (const a of Object.values(table.actions)) {
    for (const part of [a.afterLastEdit, a.inReviewWindow]) {
      for (const step of part?.steps ?? []) if (step !== 'check') s.add(step);
    }
  }
  return s;
}

function append(gd, event) {
  const f = path.join(gd, LOG);
  fs.appendFileSync(f, JSON.stringify(event) + '\n');
  if (fs.statSync(f).size > TRIM_BYTES) {
    const lines = fs.readFileSync(f, 'utf8').split('\n').filter(Boolean);
    fs.writeFileSync(`${f}.tmp`, lines.slice(Math.floor(lines.length / 2)).join('\n') + '\n');
    fs.renameSync(`${f}.tmp`, f);
  }
}

// record(kind, input): append the event the hook input describes, if it is one.
export function record(kind, input) {
  const base = {
    event: kind,
    t: new Date().toISOString(),
    session: input.session_id ?? null,
    ...(input.agent_id ? { agent: input.agent_id } : {}),
  };
  if (kind === 'edit') {
    const fp0 = input.tool_input?.file_path || input.tool_input?.notebook_path;
    if (typeof fp0 !== 'string' || !fp0) return;
    const fp = path.resolve(input.cwd || process.cwd(), fp0);
    if (!isFile(fp)) return;
    const out = git(path.dirname(fp), 'rev-parse', '--show-toplevel', '--absolute-git-dir', '--show-prefix');
    if (out === null) return;
    const [root, gd, prefix = ''] = out.split('\n');
    const rel = prefix + path.basename(fp);
    if (!gd || !usesStamp(root)) return;
    if (git(root, 'check-ignore', '-q', '--', rel) !== null) return;
    const doc = isDoc(rel, docGlobs(root));
    append(gd, { ...base, path: rel, ...(doc ? { doc: true } : {}), head: headOf(root), stamp: mtime(path.join(gd, STAMP)) });
    return;
  }
  let extra;
  if (kind === 'review') {
    // A Skill call made by Claude, or a command the user typed. Exact names only: a
    // plugin's x:simplify is another skill.
    const skill = input.tool_input?.skill ?? input.command_name;
    if (typeof skill !== 'string' || !reviewSkills(loadTable()).has(skill)) return;
    extra = { skill };
  } else if (kind === 'prompt') {
    // A background agent finishing sends a prompt too; it is not the user's.
    if (typeof input.prompt === 'string' && input.prompt.trimStart().startsWith('<task-notification>')) return;
    extra = {};
  } else return;
  const tree = hookTree(input);
  if (!tree || !usesStamp(tree)) return;
  const gd = gitDir(tree);
  if (!gd) return;
  append(gd, { ...base, ...extra, head: headOf(tree) });
}

// readEvents(gd): the events in log order, or null when there is no log. Throws on a line
// it cannot read.
function readEvents(gd) {
  let text;
  try { text = fs.readFileSync(path.join(gd, LOG), 'utf8'); } catch { return null; }
  return text.split('\n').filter((l) => l.trim()).map((l) => {
    const e = JSON.parse(l);
    if (!e || typeof e.event !== 'string') throw new Error('bad event');
    e.head ??= null;
    return e;
  });
}

const findLast = (arr, from, to, f) => { for (let i = to - 1; i >= from; i--) if (f(arr[i])) return i; return -1; };

// missingSteps(action, tree, ctx): the steps of the action missing in this tree, by the
// rules in ADR-0010 (items 5 and 6). ctx: { session, message }.
export function missingSteps(action, tree, ctx) {
  const gd = gitDir(tree);
  if (!gd) return [];
  const events = readEvents(gd);
  if (!events || !events.length) return [];
  const stampNow = mtime(path.join(gd, STAMP));
  // done(step, i): the step came after event i.
  const done = (step, i) => step === 'check'
    ? stampNow !== null && stampNow > (events[i].stamp ?? -Infinity)
    : findLast(events, i + 1, events.length, (e) => e.event === 'review' && e.skill === step) >= 0;
  const edit = (e) => e.event === 'edit';
  const code = (e) => edit(e) && !e.doc;
  const missing = [];

  const ale = action.afterLastEdit;
  if (ale) {
    const counts = ale.edits === 'any' ? edit : code;
    const last = findLast(events, 0, events.length, (e) => counts(e) &&
      (!ale.sameSession || e.session === ctx.session) && (!ale.mainOnly || !e.agent));
    if (last >= 0) for (const s of ale.steps) if (!done(s, last)) missing.push(s);
  }

  // The review window starts at the later of the last commit (the first event whose HEAD
  // differs from the one before, or past the end when HEAD moved since) and the last
  // prompt before the last code edit. Its steps must come after its first code edit.
  const rw = action.inReviewWindow;
  const lastCode = findLast(events, 0, events.length, code);
  if (rw?.steps?.length && lastCode >= 0) {
    let start = 0;
    for (let k = 1; k < events.length; k++) if (events[k].head !== events[k - 1].head) start = k;
    if (events.at(-1).head !== headOf(tree)) start = events.length;
    start = Math.max(start, findLast(events, 0, lastCode, (e) => e.event === 'prompt') + 1);
    const first = events.findIndex((e, k) => k >= start && code(e));
    if (first >= 0 && !skipped(rw.skipWhen ?? [], tree, ctx)) {
      for (const s of rw.steps) if (!done(s, first)) missing.push(s);
    }
  }
  return missing;
}

function skipped(skips, tree, ctx) {
  if (skips.includes('trailer') && /^Review-skipped:[ \t]*\S/m.test(ctx.message ?? '')) return true;
  if (skips.includes('docs-only')) {
    const files = branchFiles(tree);
    if (files === null) throw new Error('no merge base');
    const globs = docGlobs(tree);
    if (files.every((f) => isDoc(f, globs))) return true;
  }
  return false;
}

// decide(name, input, opts): [[tree, missing steps]] for each tree that blocks the action.
export function decide(name, input, opts = {}) {
  const action = loadTable().actions[name];
  if (!action) return [];
  // Claude Code is already continuing from a stop hook: block once only.
  if (input.stop_hook_active === true) return [];
  const ctx = { session: input.session_id, message: opts.message };
  if (action.afterLastEdit?.sameSession && !ctx.session) return [];
  let trees;
  if (action.scope === 'all-worktrees') {
    const root = hookTree(input);
    if (!root) return [];
    // Every worktree, this one included: an edit by absolute path into a linked worktree
    // is logged there (ADR-0005). One whose folder is gone is skipped.
    trees = (git(root, 'worktree', 'list', '--porcelain') ?? '').split('\n')
      .filter((l) => l.startsWith('worktree ')).map((l) => l.slice(9))
      .filter((t) => isDir(t) && usesStamp(t));
  } else {
    const t = opts.tree ? git(opts.tree, 'rev-parse', '--show-toplevel') : hookTree(input);
    trees = t && usesStamp(t) ? [t] : [];
  }
  const out = [];
  for (const t of trees) {
    let m;
    try { m = missingSteps(action, t, ctx); } catch { m = []; }
    if (m.length) out.push([t, m]);
  }
  return out;
}

function main(argv) {
  const [cmd, name, ...rest] = argv;
  const opts = {};
  for (let i = 0; i < rest.length; i += 2) {
    if (rest[i] === '--tree') opts.tree = rest[i + 1];
    else if (rest[i] === '--message') opts.message = rest[i + 1];
    else if (rest[i] === '--message-json') opts.message = JSON.parse(rest[i + 1]) ?? undefined;
  }
  const input = JSON.parse(fs.readFileSync(0, 'utf8')) || {};
  if (typeof input !== 'object') return;
  if (cmd === 'record') record(name, input);
  else if (cmd === 'decide') {
    for (const [t, m] of decide(name, input, opts)) process.stdout.write(`${t}\t${m.join(',')}\n`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  try { main(process.argv.slice(2)); } catch {}
  process.exitCode = 0;
}
