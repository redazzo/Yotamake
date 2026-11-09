#!/usr/bin/env node
/**
 * Checks that the rules in CLAUDE.md about keeping this repository in step hold.
 *
 *   node scripts/consistency.mjs            every rule below
 *   node scripts/consistency.mjs upgrades   reads changed paths on stdin; fails when a
 *                                           project-owned template file changed and
 *                                           plugin/reference/upgrades.md did not
 *
 * Rules:
 *   - version: plugin.json and marketplace.json name the same version.
 *   - sections: every CLAUDE.md section a skill names ("the **X** section",
 *     "CLAUDE.md, **X**") or the template's top comment lists is a heading in the template.
 *   - labels: the template's Architecture labels are all in the eval fixture's CLAUDE.md
 *     and in this repository's own.
 *   - evals: README.md's eval table has one row per folder in plugin/evals/, and no other.
 *   - step refs: a pointer to another skill's step names its heading, as
 *     `simple-session`, "Design and reuse", and that heading exists. No pointer uses a
 *     step number, which would break silently when the skill is renumbered.
 *   - harness copies: this repository's own harness-owned files (it installs its own
 *     harness) match plugin/template/. Re-run ./plugin/install.sh . to refresh them.
 *
 * Exit 0 when every rule holds, 1 otherwise.
 */

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (p) => readFileSync(path.join(ROOT, p), 'utf8');
const problems = [];
const fail = (rule, message) => problems.push(`${rule}: ${message}`);

/** The `managed` list in install.sh: the harness-owned template files. */
function managedFiles() {
  const m = read('plugin/install.sh').match(/^managed=\(([^)]*)\)/m);
  if (!m) throw new Error('no managed=(...) line in plugin/install.sh');
  return m[1].split(/\s+/).filter(Boolean);
}

/** Each skill as [name, path of its SKILL.md]. */
function skillFiles() {
  return readdirSync(path.join(ROOT, 'plugin/skills'))
    .map((name) => [name, `plugin/skills/${name}/SKILL.md`])
    .filter(([, file]) => existsSync(path.join(ROOT, file)));
}

/** Paths in .claude/yotamake/skip, read the way plugin/install.sh reads them. */
function skipped() {
  const file = path.join(ROOT, '.claude/yotamake/skip');
  if (!existsSync(file)) return new Set();
  return new Set(
    readFileSync(file, 'utf8')
      .split('\n')
      .map((l) => l.replace(/#.*/, '').trim().replace(/^\.\//, ''))
      .filter(Boolean)
  );
}

/** `- **Label:**` lines in a CLAUDE.md's Architecture section, docs-system lines left out. */
function architectureLabels(source) {
  const section = (source.split(/^## Architecture$/m)[1]?.split(/^## /m)[0] ?? '')
    .replace(/<!-- yotamake:docs begin -->[\s\S]*?<!-- yotamake:docs end -->/g, '');
  return [...section.matchAll(/^- \*\*([^*]+):\*\*/gm)].map((m) => m[1]);
}

function checkVersion() {
  const plugin = JSON.parse(read('plugin/.claude-plugin/plugin.json')).version;
  const listed = JSON.parse(read('.claude-plugin/marketplace.json')).plugins.find(
    (p) => p.name === 'yotamake'
  )?.version;
  if (plugin !== listed) {
    fail('version', `plugin.json says ${plugin}, marketplace.json says ${listed}; bump both`);
  }
}

/** Section names a skill reads: "the **X** section", "CLAUDE.md, **X**", "(CLAUDE.md, X)". */
const SECTION_REFS = [
  /\*\*([A-Z][A-Za-z ]+?)\*\* section/g,
  /CLAUDE\.md(?:,|'s) \*\*([A-Z][A-Za-z ]+?)(?:\*\*| →)/g,
  /\(CLAUDE\.md, ([A-Z][A-Za-z ]+)\)/g,
];

function checkSections() {
  const template = read('plugin/template/CLAUDE.md');
  const named = new Map(); // section name -> where it is named
  const listed = template.match(/read the sections below BY NAME:\s*\n\s*([^\n]+)\./)?.[1];
  for (const name of listed?.split(/,\s*/) ?? []) named.set(name, "the template's top comment");
  for (const [, file] of skillFiles()) {
    for (const re of SECTION_REFS) {
      for (const m of read(file).matchAll(re)) named.set(m[1], file);
    }
  }
  for (const [name, where] of named) {
    if (!new RegExp(`^## ${name}$`, 'm').test(template)) {
      fail('sections', `${where} names "${name}", but plugin/template/CLAUDE.md has no "## ${name}"`);
    }
  }
}

function checkLabels() {
  const want = architectureLabels(read('plugin/template/CLAUDE.md'));
  for (const file of ['plugin/evals/_fixture/files/CLAUDE.md', 'CLAUDE.md']) {
    const have = new Set(architectureLabels(read(file)));
    const missing = want.filter((l) => !have.has(l));
    if (missing.length) fail('labels', `${file} Architecture lacks: ${missing.join(', ')}`);
  }
}

function checkEvals() {
  const cases = new Set(readdirSync(path.join(ROOT, 'plugin/evals')).filter((d) => /^\d\d-/.test(d)));
  const rows = new Set([...read('README.md').matchAll(/^\| (\d\d-[\w-]+) \|/gm)].map((m) => m[1]));
  for (const c of cases) if (!rows.has(c)) fail('evals', `README.md's eval table has no row for ${c}`);
  for (const r of rows) if (!cases.has(r)) fail('evals', `README.md's eval table lists ${r}, not in plugin/evals/`);
}

/** "## 3. Design and reuse — before any edit" -> "Design and reuse". */
const stepName = (heading) => heading.replace(/^\d+\.\s*/, '').replace(/\s+—.*$/, '').trim();

function checkStepRefs() {
  const steps = new Map(skillFiles().map(([name, file]) => [
    name,
    new Set([...read(file).matchAll(/^## (.+)$/gm)].map((m) => stepName(m[1]))),
  ]));
  // Every doc and script under plugin/ (bar the evals), plus the root docs.
  const files = execFileSync('git', ['ls-files', '-co', '--exclude-standard', 'plugin/*.md',
    'plugin/*.sh', 'README.md', 'CLAUDE.md'], { cwd: ROOT, encoding: 'utf8' })
    .split('\n')
    .filter((f) => f && !f.startsWith('plugin/evals/') && existsSync(path.join(ROOT, f)));
  for (const file of files) {
    const text = read(file).replace(/\s+/g, ' '); // a pointer may wrap across lines
    for (const m of text.matchAll(/`([a-z][a-z-]*)`, "([^"]+)"/g)) {
      if (steps.has(m[1]) && !steps.get(m[1]).has(m[2])) {
        fail('step refs', `${file} points at ${m[1]}, "${m[2]}", but that skill has no such step`);
      }
    }
    // A skill may number its own steps. Anything else names a step by its heading.
    const numbered = file.endsWith('/SKILL.md')
      ? [/`([a-z][a-z-]*)`(?:'s| skill)?,? step \d+/g, /step \d+ of `([a-z][a-z-]*)`/g]
      : [/\bsteps? \d+/g];
    for (const re of numbered) {
      for (const m of text.matchAll(re)) {
        if (m[1] === undefined || steps.has(m[1])) {
          fail('step refs', `${file} points at a step by number ("${m[0]}"); name its heading`);
        }
      }
    }
  }
}

function checkHarnessCopies() {
  const skip = skipped();
  for (const f of managedFiles()) {
    if (skip.has(f)) continue;
    const ours = path.join(ROOT, f);
    if (!existsSync(ours) || readFileSync(ours, 'utf8') !== read(`plugin/template/${f}`)) {
      fail('harness copies', `${f} differs from plugin/template/${f}; run ./plugin/install.sh .`);
    }
  }
}

function checkUpgrades(changed) {
  if (changed.includes('plugin/reference/upgrades.md')) return;
  // Template files that reach older installs on their own. The last two mirror special
  // cases in plugin/install.sh: settings.json is merged, the records index regenerated.
  const exempt = new Set([...managedFiles(), '.claude/settings.json', 'docs/records/README.md']);
  const owned = changed
    .filter((p) => p.startsWith('plugin/template/'))
    .map((p) => p.slice('plugin/template/'.length))
    .filter((p) => !exempt.has(p));
  for (const p of owned) {
    fail('upgrades', `plugin/template/${p} is project-owned; add an entry to plugin/reference/upgrades.md`);
  }
}

if (process.argv[2] === 'upgrades') {
  checkUpgrades(readFileSync(0, 'utf8').split('\n').filter(Boolean));
} else {
  checkVersion();
  checkSections();
  checkLabels();
  checkEvals();
  checkStepRefs();
  checkHarnessCopies();
}

for (const p of problems) console.error(p);
process.exit(problems.length ? 1 : 0);
