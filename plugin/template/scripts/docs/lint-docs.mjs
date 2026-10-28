#!/usr/bin/env node

/**
 * Documentation linter — internal link integrity and doc front-matter.
 *
 * WHY THIS EXISTS. Hand-written relative markdown links decay silently: files move,
 * get renamed or deleted, and nothing notices. Docs nobody links to become invisible.
 * Fixing links by hand without a checker decays again within weeks.
 *
 * WHAT IS ENFORCED. Every rule below fails the run:
 *
 *   - broken links — every internal link must resolve to a file.
 *   - orphans — every file under docs/ must be reachable from docs/README.md by
 *     following links. That index is the single entry point.
 *   - doc-to-doc link depth — a link from one docs/ file to another may not walk
 *     up more than three levels. More means the file is in the wrong place. Links
 *     from docs to source files are exempt.
 *   - front-matter — validated where present. Records need kind/date/status.
 *   - a stale records index (via generate-records-index.mjs --check).
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
 * WHAT IT CANNOT DO. It does not verify `#anchor` fragments, and it says nothing
 * about whether a document is *accurate* — only whether its links resolve.
 *
 * Exit codes: 0 clean · 1 findings, stale baseline, or stale records index · 2 could not run.
 */

import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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
function stripCode(source) {
  const blank = (m) => m.replace(/[^\n]/g, ' ');
  return source
    .replace(/^([ \t]*)(```|~~~)[\s\S]*?^\1?\2[^\n]*$/gm, blank)
    .replace(/`[^`\n]*`/g, blank);
}

/** Split YAML front-matter from the body. Returns `{ frontMatter, body }`. */
function splitFrontMatter(source) {
  const match = source.match(/^---\n([\s\S]*?)\n---\n?/);
  if (!match) return { frontMatter: null, body: source };
  return { frontMatter: match[1], body: source.slice(match[0].length) };
}

const LINK_RE = /\[[^\]]*\]\(\s*([^)\s]+)(?:\s+"[^"]*")?\s*\)/g;

/** Every internal link target in a document, with the line it appears on. */
function internalLinks(source) {
  const body = stripCode(splitFrontMatter(source).body);
  const links = [];

  for (const match of body.matchAll(LINK_RE)) {
    let href = match[1].trim();
    if (href.startsWith('<') && href.endsWith('>')) href = href.slice(1, -1);

    // External, same-page anchors, and protocol-relative URLs are not ours to check.
    if (/^(https?:|mailto:|tel:|data:|#|\/\/)/.test(href)) continue;

    const target = href.split('#')[0].split('?')[0].trim();
    if (!target) continue;

    let decoded;
    try {
      decoded = decodeURIComponent(target);
    } catch {
      decoded = target; // malformed escape — check the literal path and let it fail honestly
    }

    links.push({
      href,
      target: decoded,
      line: body.slice(0, match.index).split('\n').length,
      depth: (decoded.match(/\.\.\//g) || []).length,
      absolute: decoded.startsWith('/'),
    });
  }
  return links;
}

// ---------------------------------------------------------------------------
// Front-matter (validated only where present — see header)
// ---------------------------------------------------------------------------

const VALID_KINDS = new Set(['reference', 'guide', 'decision', 'record']);
const VALID_STATUSES = new Set(['current', 'superseded', 'historical']);

/** Minimal scalar/list YAML reader — enough for the schema, no dependency. */
function parseFrontMatter(text) {
  const data = {};
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const match = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (!match) continue;
    const [, key, rawValue] = match;
    const value = rawValue.trim();
    if (value.startsWith('[') && value.endsWith(']')) {
      data[key] = value
        .slice(1, -1)
        .split(',')
        .map((v) => v.trim().replace(/^["']|["']$/g, ''))
        .filter(Boolean);
    } else {
      data[key] = value.replace(/^["']|["']$/g, '');
    }
  }
  return data;
}

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
  let totalLinks = 0;

  for (const absolute of files) {
    const file = path.relative(REPO_ROOT, absolute);
    const source = readFileSync(absolute, 'utf8');

    const { frontMatter } = splitFrontMatter(source);
    if (frontMatter !== null) {
      for (const problem of frontMatterProblems(parseFrontMatter(frontMatter))) {
        findings.push({ rule: 'front-matter', file, detail: problem, line: 1 });
      }
    }

    const outbound = new Set();
    for (const link of internalLinks(source)) {
      totalLinks += 1;

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
