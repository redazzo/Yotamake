#!/usr/bin/env node

/**
 * Documentation linter — internal links and anchors, inventory blocks, and doc front-matter.
 *
 * WHY THIS EXISTS. Hand-written relative markdown links decay silently: files move,
 * get renamed or deleted, and nothing notices. Docs nobody links to become invisible.
 * Fixing links by hand without a checker decays again within weeks.
 *
 * WHAT IS ENFORCED. Every rule below fails the run:
 *
 *   - broken links — every internal link must resolve to a file.
 *   - broken anchors — a link's `#fragment` into a Markdown file, or a same-page `#…`
 *     link, must name a heading there (by GitHub's slug rules, `-1` for a repeat) or an
 *     HTML `id`/`name`. Fragments into other files are not checked.
 *   - orphans — every file under docs/ must be reachable from docs/README.md by
 *     following links. That index is the single entry point.
 *   - doc-to-doc link depth — a link from one docs/ file to another may not walk
 *     up more than three levels. More means the file is in the wrong place. Links
 *     from docs to source files are exempt.
 *   - front-matter — validated where present. Records need kind/date/status.
 *   - a stale records index (via generate-records-index.mjs --check).
 *   - inventory blocks — a list a doc keeps of files on disk, written between
 *     `<!-- inventory: <glob> [<glob> …] -->` and `<!-- /inventory -->`, must name every
 *     path its globs match (globs are from the repository root; `*` stays within one
 *     name; a trailing `/` matches folders). A path is named when it ends with a word
 *     in the list (`lib.sh`, `hooks/lib.sh`, `skills/` for a folder). A word that looks
 *     like a match (it fits the glob's last part) but names nothing on disk fails too; a
 *     bare `*` for files is never checked this way, since any word fits it. Add `names`
 *     after the globs for a list that writes folders without the `/`: it compares bare
 *     names, and only its `code` words count as claims.
 *
 * THE RATCHET. For adopting the harness in a repo with existing link debt:
 * `--update-baseline` writes scripts/docs/docs-lint-baseline.txt with the current
 * findings. The run then fails both for a finding outside it and for an entry in it
 * that no longer holds, so a fix must delete its line in the same commit. The
 * baseline records deliberate debt; never use it to silence a regression.
 *
 * Directories containing a package.json are skipped: a vendored sample app inside a
 * record is that record's payload, not documentation.
 *
 * WHAT IT CANNOT DO. It says nothing about whether a document is *accurate*: only
 * whether its links and anchors resolve, and whether its inventory blocks match the disk.
 * A list outside an inventory block is not compared with anything.
 *
 * Exit codes: 0 clean · 1 findings, stale baseline, or stale records index · 2 could not run.
 */

import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
// The generator owns the front-matter reader, so the linter and the index agree.
import { splitFrontMatter, readFrontMatter } from './generate-records-index.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(here, '../..');
const BASELINE_FILE = path.join(here, 'docs-lint-baseline.txt');

/** Directories never scanned: not ours, generated, or virtual-env noise. */
const SKIP_DIRS = new Set(['node_modules', '.git', 'dist', 'build', '.venv', '.turbo', 'coverage']);

/** The single entry point; orphan reachability starts here. */
const INDEX_DOC = 'docs/README.md';

/** Roots that are entry points in their own right, so not orphans by definition. */
const ENTRY_POINTS = new Set(['README.md', 'CLAUDE.md', INDEX_DOC]);

/**
 * Deepest legitimate doc-to-doc walk. A record inside a project directory
 * (docs/records/<year>/<project>/file.md) reaching a sibling kind directory needs
 * exactly three. Anything more means the file is misplaced, not that the link is clever.
 */
const MAX_DOC_LINK_DEPTH = 3;

// ---------------------------------------------------------------------------
// Scanning
// ---------------------------------------------------------------------------

function findMarkdownFiles(dir, acc = []) {
  const entries = readdirSync(dir, { withFileTypes: true });

  // A directory with its own package.json is a project, not documentation — a vendored
  // sample app copied into a record is that record's payload. The repo root is exempt.
  if (dir !== REPO_ROOT && entries.some((e) => e.isFile() && e.name === 'package.json')) {
    return acc;
  }

  for (const entry of entries) {
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      findMarkdownFiles(path.join(dir, entry.name), acc);
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      acc.push(path.join(dir, entry.name));
    }
  }
  return acc;
}

/**
 * Blank out fenced and inline code so example markdown inside a code block is
 * not mistaken for a real link. Replaced with spaces rather than removed, so
 * line numbers in findings still point at the right line.
 */
const blank = (m) => m.replace(/[^\n]/g, ' ');

/** Blank out fenced code only. Headings keep their inline code, which their slug uses. */
function stripFences(source) {
  return source.replace(/^([ \t]*)(```|~~~)[\s\S]*?^\1?\2[^\n]*$/gm, blank);
}

function stripCode(source) {
  return stripFences(source).replace(/`[^`\n]*`/g, blank);
}

const lineAt = (text, index) => text.slice(0, index).split('\n').length;

/** A percent-decoded string; a malformed escape is kept literal, to fail honestly. */
const safeDecode = (s) => {
  try {
    return decodeURIComponent(s);
  } catch {
    return s;
  }
};

const LINK_RE = /\[[^\]]*\]\(\s*([^)\s]+)(?:\s+"[^"]*")?\s*\)/g;

/**
 * Every internal link in a document, with the line it appears on. A same-page `#…` link
 * comes back with `same: true` and no target; `fragment` is the part after `#`, if any.
 */
function internalLinks(body) {
  body = stripCode(body);
  const links = [];

  for (const match of body.matchAll(LINK_RE)) {
    let href = match[1].trim();
    if (href.startsWith('<') && href.endsWith('>')) href = href.slice(1, -1);

    // External and protocol-relative URLs are not ours to check.
    if (/^(https?:|mailto:|tel:|data:|\/\/)/.test(href)) continue;
    const line = lineAt(body, match.index);

    const hash = href.indexOf('#');
    const fragment = hash < 0 ? '' : href.slice(hash + 1);
    if (hash === 0) {
      if (fragment) links.push({ href, same: true, fragment, line });
      continue;
    }

    const target = href.slice(0, hash < 0 ? undefined : hash).split('?')[0].trim();
    if (!target) continue;
    const decoded = safeDecode(target);

    links.push({
      href,
      target: decoded,
      fragment,
      line,
      depth: (decoded.match(/\.\.\//g) || []).length,
      absolute: decoded.startsWith('/'),
    });
  }
  return links;
}

// ---------------------------------------------------------------------------
// Anchors
// ---------------------------------------------------------------------------

/**
 * A heading's anchor as GitHub makes it: the text without link targets, tags and
 * emphasis, lower-cased, punctuation dropped except `-` and `_`, each space a `-`.
 */
function slugOf(text) {
  return text
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/<[^>]+>/g, '')
    .replace(/(^|[^\p{L}\p{N}])_+([^_]+?)_+(?=[^\p{L}\p{N}]|$)/gu, '$1$2')
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{M}\p{N}\p{Pc} -]/gu, '')
    .replace(/ /g, '-');
}

/** A line that can sit above a setext underline: plain paragraph text. */
const isParagraphLine = (line) => line.trim() !== '' && !/^\s*([#>|]|[-*+]\s|\d+[.)]\s|<!--)/.test(line);

/**
 * Every anchor a link may name in a document: one per heading (a repeat gets `-1`,
 * `-2`, as on GitHub), plus each `id` or `name` attribute in its HTML.
 */
function headingAnchors(body) {
  const lines = stripFences(body).split('\n');
  const anchors = new Set();
  const seen = new Map();
  const add = (text) => {
    const base = slugOf(text);
    const count = seen.get(base) ?? 0;
    seen.set(base, count + 1);
    anchors.add(count ? `${base}-${count}` : base);
  };

  lines.forEach((line, i) => {
    const atx = line.match(/^ {0,3}#{1,6}(?:[ \t]+(.*?))?(?:[ \t]+#+)?[ \t]*$/);
    if (atx) add(atx[1] ?? '');
    else if (i > 0 && /^ {0,3}(=+|-+)[ \t]*$/.test(line) && isParagraphLine(lines[i - 1])) add(lines[i - 1]);
  });
  for (const m of stripCode(body).matchAll(/<[a-z][^>]*?\s(?:id|name)\s*=\s*["']([^"']+)["']/gi)) {
    anchors.add(m[1].toLowerCase());
  }
  return anchors;
}

const hasAnchor = (anchors, fragment) => anchors.has(safeDecode(fragment).toLowerCase());

// ---------------------------------------------------------------------------
// Inventory blocks
// ---------------------------------------------------------------------------

/** What separates the names in a block: spaces, code marks, commas, brackets, table bars. */
const TOKEN_SPLIT = /[\s`,()[\]{}|<>"']+/;
const cleanToken = (t) => t.replace(/^\*+/, '').replace(/[*.:;!?]+$/, '').replace(/^\.\//, '');
const tokensOf = (text) => text.split(TOKEN_SPLIT).map(cleanToken).filter(Boolean);

/** A glob part as a regular expression. `*` matches within one name, never across `/`. */
const partRegex = (part) =>
  new RegExp(`^${part.split('*').map((s) => s.replace(/[.+?^${}()|[\]\\]/g, '\\$&')).join('[^/]*')}$`);

function parseGlob(glob) {
  const dirOnly = glob.endsWith('/');
  const parts = glob.replace(/^\.?\//, '').replace(/\/+$/, '').split('/');
  return { glob, dirOnly, parts };
}

/** The repo-relative paths a glob matches; a directory ends in `/`. Hidden names need a `.` in the glob. */
function expandGlob({ dirOnly, parts }) {
  let found = [''];
  parts.forEach((part, i) => {
    const last = i === parts.length - 1;
    const next = [];
    const re = partRegex(part);
    for (const dir of found) {
      for (const entry of readdirSync(path.join(REPO_ROOT, dir), { withFileTypes: true })) {
        if (!re.test(entry.name) || (entry.name.startsWith('.') && !part.startsWith('.'))) continue;
        if (!last) {
          if (entry.isDirectory()) next.push(`${dir}${entry.name}/`);
        } else if (dirOnly ? entry.isDirectory() : entry.isFile()) {
          next.push(`${dir}${entry.name}${dirOnly ? '/' : ''}`);
        }
      }
    }
    found = next;
  });
  return found.sort();
}

/** A token names a path when the path ends with it, at a `/`. `names` blocks drop the trailing `/`. */
function tokenNames(pathOnDisk, token, bare) {
  const p = bare ? pathOnDisk.replace(/\/$/, '') : pathOnDisk;
  const t = bare ? token.replace(/\/$/, '') : token;
  return p === t || p.endsWith(`/${t}`);
}

/**
 * Whether a token looks like something the glob would match, so is a claim that it is
 * on disk. Its last part must fit the glob's last part (a trailing `/` for `*\/`), and a
 * bare `*` for files claims nothing, since any word would fit it.
 */
function tokenClaims({ dirOnly, parts }, token, bare) {
  if (token.includes('*') || token.includes('://')) return false;
  if (!bare && token.endsWith('/') !== dirOnly) return false;
  const tokenParts = token.replace(/\/$/, '').split('/');
  if (tokenParts.length > parts.length || tokenParts.some((p) => !p)) return false;
  if (!dirOnly && /^\*+$/.test(parts.at(-1))) return false;
  const tail = parts.slice(parts.length - tokenParts.length);
  return tokenParts.every((p, i) => partRegex(tail[i]).test(p) && (!p.startsWith('.') || tail[i].startsWith('.')));
}

/** Whether the token is on disk inside `dir`, as a folder when it ends in `/`. */
function existsBeside(dir, token, bare) {
  const abs = path.join(REPO_ROOT, dir, token);
  if (!existsSync(abs)) return false;
  return bare || token.endsWith('/') === statSync(abs).isDirectory();
}

/**
 * The inventory blocks in a document: `<!-- inventory: <glob> [<glob> …] [names] -->`, then
 * the list, then `<!-- /inventory -->`. The markers are found outside code; the list
 * between them is read as written, code blocks included.
 */
function inventoryBlocks(body) {
  const plain = stripCode(body);
  const blocks = [];
  for (const open of plain.matchAll(/<!--\s*inventory:([^>]*?)-->/g)) {
    const words = open[1].trim().split(/\s+/).filter(Boolean);
    const bare = words.at(-1) === 'names';
    if (bare) words.pop();
    const start = open.index + open[0].length;
    const end = plain.slice(start).search(/<!--\s*\/inventory\s*-->/);
    blocks.push({
      globs: words.map(parseGlob),
      bare,
      line: lineAt(body, open.index),
      text: end < 0 ? null : body.slice(start, start + end),
    });
  }
  return blocks;
}

/** What a block gets wrong: a path on disk it does not name, or a name it claims that is not on disk. */
function inventoryProblems({ globs, bare, text }) {
  if (!globs.length) return ['the inventory block names no glob'];
  if (text === null) return ['the inventory block has no closing <!-- /inventory -->'];

  const tokens = tokensOf(text);
  // A `names` block writes bare words, so only its code spans count as claims.
  const claims = bare ? [...text.matchAll(/`([^`\n]+)`/g)].flatMap((m) => tokensOf(m[1])) : tokens;
  const problems = [];
  const onDisk = new Set();
  const above = new Set(); // folders above a match, which a tree names as headings

  for (const glob of globs) {
    for (const match of expandGlob(glob)) {
      onDisk.add(match);
      const segments = match.replace(/\/$/, '').split('/');
      for (let i = 1; i < segments.length; i++) above.add(`${segments.slice(0, i).join('/')}/`);
      if (!tokens.some((t) => tokenNames(match, t, bare))) {
        problems.push(`${glob.glob}: ${match} is on disk but the block does not name it`);
      }
    }
  }
  const known = [...onDisk, ...above];
  for (const token of new Set(claims)) {
    if (!globs.some((g) => tokenClaims(g, token, bare))) continue;
    if (known.some((p) => tokenNames(p, token, bare))) continue;
    // A tree also names what sits beside the matches, such as other folders.
    if ([...above].some((dir) => existsBeside(dir, token, bare))) continue;
    problems.push(`${globs.map((g) => g.glob).join(' ')}: the block names ${token}, which is not on disk`);
  }
  return problems;
}

// ---------------------------------------------------------------------------
// Front-matter (validated only where present — see header)
// ---------------------------------------------------------------------------

const VALID_KINDS = new Set(['reference', 'guide', 'decision', 'record']);
const VALID_STATUSES = new Set(['current', 'superseded', 'historical']);

function frontMatterProblems(data) {
  const problems = [];
  if (data.kind && !VALID_KINDS.has(data.kind)) {
    problems.push(`kind: "${data.kind}" is not one of ${[...VALID_KINDS].join(', ')}`);
  }
  if (data.status && !VALID_STATUSES.has(data.status)) {
    problems.push(`status: "${data.status}" is not one of ${[...VALID_STATUSES].join(', ')}`);
  }
  for (const field of ['updated', 'date']) {
    if (data[field] && !/^\d{4}-\d{2}-\d{2}$/.test(data[field])) {
      problems.push(`${field}: "${data[field]}" is not YYYY-MM-DD`);
    }
  }
  if (data.kind === 'record') {
    if (!data.date) problems.push('a record needs a date: YYYY-MM-DD');
    if (!data.status) problems.push('a record needs a status:');
  }
  if (data.owns && !Array.isArray(data.owns)) {
    problems.push('owns: must be a list, e.g. [auth, session-handling]');
  }
  return problems;
}

// ---------------------------------------------------------------------------
// Baseline
// ---------------------------------------------------------------------------

/** A finding's stable identity. Must not embed line numbers — those move. */
const keyOf = (f) => `${f.rule}\t${f.file}\t${f.detail}`;

function readBaseline() {
  if (!existsSync(BASELINE_FILE)) return new Set();
  return new Set(
    readFileSync(BASELINE_FILE, 'utf8')
      .split('\n')
      .map((l) => l.trimEnd())
      .filter((l) => l && !l.startsWith('#'))
  );
}

function writeBaseline(keys) {
  const header = [
    `# Known documentation lint findings, recorded ${new Date().toISOString().slice(0, 10)}.`,
    '#',
    '# This file is a RATCHET, not a suppression list. scripts/docs/lint-docs.mjs fails when a',
    '# link breaks that is not listed here, and equally when a line here is no longer',
    '# broken — fixing a link means deleting its line in the same commit.',
    '#',
    '# Format: <rule>\\t<file>\\t<detail>. Regenerate with `node scripts/docs/lint-docs.mjs --update-baseline`.',
    '',
  ].join('\n');
  writeFileSync(BASELINE_FILE, `${header}${[...keys].sort().join('\n')}\n`, 'utf8');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function lint() {
  const files = findMarkdownFiles(REPO_ROOT).sort();
  const findings = [];
  const linkGraph = new Map(); // repo-relative file -> Set of repo-relative targets
  const sources = new Map(); // absolute path -> text, each file read once
  const sourceOf = (absolute) => {
    if (!sources.has(absolute)) sources.set(absolute, readFileSync(absolute, 'utf8').replace(/\r\n/g, '\n'));
    return sources.get(absolute);
  };
  const anchorCache = new Map(); // absolute path -> Set of anchors
  const anchorsOf = (absolute) => {
    if (!anchorCache.has(absolute)) anchorCache.set(absolute, headingAnchors(splitFrontMatter(sourceOf(absolute)).body));
    return anchorCache.get(absolute);
  };
  let totalLinks = 0;

  for (const absolute of files) {
    const file = path.relative(REPO_ROOT, absolute);
    const source = sourceOf(absolute);
    const { body } = splitFrontMatter(source);

    for (const problem of frontMatterProblems(readFrontMatter(source).data)) {
      findings.push({ rule: 'front-matter', file, detail: problem, line: 1 });
    }

    for (const block of inventoryBlocks(body)) {
      for (const problem of inventoryProblems(block)) {
        findings.push({ rule: 'inventory', file, detail: problem, line: block.line });
      }
    }

    const outbound = new Set();
    for (const link of internalLinks(body)) {
      totalLinks += 1;
      const brokenAnchor = (target) => {
        if (!hasAnchor(anchorsOf(target), link.fragment)) {
          findings.push({ rule: 'broken-anchor', file, detail: link.href, line: link.line });
        }
      };

      if (link.same) {
        brokenAnchor(absolute);
        continue;
      }

      // A leading `/` is repo-root-relative on GitHub but filesystem-absolute to
      // Node, so it has to be re-anchored before it can be checked at all.
      const resolved = link.absolute
        ? path.join(REPO_ROOT, link.target)
        : path.resolve(path.dirname(absolute), link.target);

      if (!existsSync(resolved)) {
        findings.push({ rule: 'broken-link', file, detail: link.href, line: link.line });
        continue;
      }
      const targetRel = path.relative(REPO_ROOT, resolved);
      if (file.startsWith('docs/') && targetRel.startsWith('docs/') && link.depth > MAX_DOC_LINK_DEPTH) {
        findings.push({
          rule: 'deep-link',
          file,
          detail: `${link.href} walks up ${link.depth} levels; ${MAX_DOC_LINK_DEPTH} is the most any docs/ file should need`,
          line: link.line,
        });
      }
      if (resolved.endsWith('.md') && statSync(resolved).isFile()) {
        outbound.add(targetRel);
        if (link.fragment) brokenAnchor(resolved);
      }
    }
    linkGraph.set(file, outbound);
  }

  // Orphans: docs/ files not reachable from the index by following links.
  const reachable = new Set();
  const queue = [...ENTRY_POINTS].filter((f) => linkGraph.has(f));
  while (queue.length) {
    const current = queue.pop();
    if (reachable.has(current)) continue;
    reachable.add(current);
    for (const next of linkGraph.get(current) ?? []) queue.push(next);
  }
  for (const file of [...linkGraph.keys()].sort()) {
    if (!file.startsWith('docs/') || reachable.has(file)) continue;
    findings.push({
      rule: 'orphan',
      file,
      detail: `nothing reachable from ${INDEX_DOC} links to this file`,
      line: 1,
    });
  }

  return { files, totalLinks, findings };
}

function main() {
  const updating = process.argv.includes('--update-baseline');
  const verbose = process.argv.includes('--verbose');

  let result;
  try {
    result = lint();
  } catch (error) {
    console.error(`docs lint: could not run — ${error.message}`);
    process.exit(2);
  }

  const { files, totalLinks, findings } = result;
  const current = new Set(findings.map(keyOf));

  if (updating) {
    writeBaseline(current);
    console.log(`docs lint: baseline rewritten with ${current.size} entr${current.size === 1 ? 'y' : 'ies'}.`);
    process.exit(0);
  }

  const baseline = readBaseline();
  const regressions = findings.filter((f) => !baseline.has(keyOf(f)));
  const fixed = [...baseline].filter((k) => !current.has(k));

  console.log(
    `docs lint: ${files.length} markdown files, ${totalLinks} internal links, ` +
      `${findings.length} finding${findings.length === 1 ? '' : 's'} ` +
      `(${baseline.size} baselined).`
  );

  if (verbose) {
    for (const f of findings) console.log(`      ${f.rule}: ${f.file}:${f.line}  ${f.detail}`);
  }

  // The generated records index is part of the corpus's integrity: a record added
  // without regenerating it is a record nothing links to.
  let indexStale = false;
  try {
    execFileSync('node', [path.join(here, 'generate-records-index.mjs'), '--check'], {
      cwd: REPO_ROOT,
      stdio: 'pipe',
    });
  } catch (error) {
    indexStale = true;
    console.error(`\n${(error.stdout || '') + (error.stderr || '')}`.trimEnd());
  }

  if (regressions.length) {
    console.error(`\n${regressions.length} new finding(s) — not in the baseline:\n`);
    for (const f of regressions) {
      console.error(`  ${f.file}:${f.line}  [${f.rule}]  ${f.detail}`);
    }
    console.error(
      '\nFix the link, or if the target was deliberately deleted, update every document ' +
        'that pointed at it. Do not add entries to the baseline by hand.'
    );
  }

  if (fixed.length) {
    console.error(
      `\n${fixed.length} baseline entr${fixed.length === 1 ? 'y is' : 'ies are'} no longer broken. ` +
        'Delete these lines from scripts/docs/docs-lint-baseline.txt (or run with --update-baseline):\n'
    );
    for (const k of fixed.sort()) {
      const [rule, file, detail] = k.split('\t');
      console.error(`  ${file}  [${rule}]  ${detail}`);
    }
  }

  if (regressions.length || fixed.length || indexStale) process.exit(1);

  console.log(
    findings.length
      ? 'docs lint: clean against baseline (no new findings, none silently fixed).'
      : 'docs lint: clean — links resolve, nothing orphaned, records index current.'
  );
  process.exit(0);
}

main();
