#!/usr/bin/env node
/**
 * Checks that the rules in CLAUDE.md about keeping this repository in step hold.
 *
 *   node scripts/consistency.mjs            every rule below
 *   node scripts/consistency.mjs upgrades   reads changed paths on stdin; fails when a
 *                                           project-owned template file changed and
 *                                           plugin/reference/upgrades.md did not
 *   node scripts/consistency.mjs sync-graders
 *                                           copies each plugin/evals/_graders/ file over
 *                                           the case graders of the same name
 *   node scripts/consistency.mjs evals-for  reads changed paths on stdin; prints the eval
 *                                           cases that cover them (a note: always exit 0)
 *   node scripts/consistency.mjs pages-for  reads changed paths on stdin; prints the site
 *                                           pages that mention them (a note: always exit 0)
 *
 * Rules:
 *   - version: plugin.json, marketplace.json and .claude/yotamake/version name the same
 *     version, and CHANGELOG.md has a `## X.Y.Z` entry for it.
 *   - sections: every CLAUDE.md section a skill names ("the **X** section",
 *     "CLAUDE.md, **X**") or the template's top comment lists is a heading in the template.
 *   - labels: the template's Architecture labels are all in the eval fixture's CLAUDE.md
 *     and in this repository's own.
 *   - evals: README.md's eval table has one row per folder in plugin/evals/, and no other,
 *     and each row's Skills cell names one or more skills that exist.
 *   - site skills: site/skills.html has a card for every folder in plugin/skills/, and no
 *     card for a skill that does not exist.
 *   - step refs: a pointer to another skill's step names its heading, as
 *     `simple-session`, "Design and reuse", and that heading exists. No pointer uses a
 *     step number, which would break silently when the skill is renumbered.
 *   - eval graders: a case grader named like one in plugin/evals/_graders/ is an exact
 *     copy of it (the eval runner reads each case's graders/ folder, so cases cannot
 *     share one file), and every shared grader is used by some case.
 *   - portable sed: no script uses GNU-only `sed -i` without a backup suffix (CLAUDE.md,
 *     Constraints: the harness runs on macOS too).
 *   - harness copies: this repository's own harness-owned files (it installs its own
 *     harness) match plugin/template/. Re-run ./plugin/install.sh . to refresh them.
 *
 * Exit 0 when every rule holds, 1 otherwise.
 */

import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
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

/** Tracked and untracked (not ignored) files matching the git pathspecs, deleted ones left out. */
function listedFiles(...pathspecs) {
  return execFileSync('git', ['ls-files', '-co', '--exclude-standard', ...pathspecs], { cwd: ROOT, encoding: 'utf8' })
    .split('\n')
    .filter((f) => f && existsSync(path.join(ROOT, f)));
}

/** The eval case folders in plugin/evals/, e.g. "02-small-change". */
function evalCases() {
  return readdirSync(path.join(ROOT, 'plugin/evals')).filter((d) => /^\d\d-/.test(d));
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
  const installed = read('.claude/yotamake/version').trim();
  if (installed !== plugin) {
    fail('version', `.claude/yotamake/version says ${installed}, plugin.json says ${plugin}; run ./plugin/install.sh .`);
  }
  const escaped = plugin.replace(/\./g, '\\.');
  if (!new RegExp(`^## ${escaped}(?![\\w.])`, 'm').test(read('CHANGELOG.md'))) {
    fail('version', `CHANGELOG.md has no "## ${plugin}" entry; the bump commit adds it (or renames "## Unreleased")`);
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

/** README.md's eval table as a Map: case -> the skills its Skills cell names. */
function evalRows() {
  return new Map(
    [...read('README.md').matchAll(/^\| (\d\d-[\w-]+) \| ([^|]*) \|/gm)].map((m) => [
      m[1],
      [...m[2].matchAll(/`([a-z][a-z-]*)`/g)].map((s) => s[1]),
    ])
  );
}

function checkEvals() {
  const cases = new Set(evalCases());
  const rows = evalRows();
  const skills = new Set(skillFiles().map(([name]) => name));
  for (const c of cases) if (!rows.has(c)) fail('evals', `README.md's eval table has no row for ${c}`);
  for (const [r, named] of rows) {
    if (!cases.has(r)) fail('evals', `README.md's eval table lists ${r}, not in plugin/evals/`);
    if (!named.length) fail('evals', `README.md's eval table row ${r} names no skill`);
    for (const s of named) {
      if (!skills.has(s)) fail('evals', `README.md's eval table row ${r} names ${s}, not in plugin/skills/`);
    }
  }
}

/** The skills that have a card (class="card skill" id="<name>") in site/skills.html. */
const siteCards = () =>
  new Set([...read('site/skills.html').matchAll(/class="card skill" id="([^"]+)"/g)].map((m) => m[1]));

/** site/skills.html has one card per skill, and no other. */
function checkSiteSkills() {
  const skills = new Set(skillFiles().map(([name]) => name));
  const cards = siteCards();
  for (const s of skills) if (!cards.has(s)) fail('site skills', `site/skills.html has no card for plugin/skills/${s}`);
  for (const c of cards) if (!skills.has(c)) fail('site skills', `site/skills.html has a card for "${c}", not in plugin/skills/`);
}

/**
 * The eval cases that cover the changed paths, worked out from the eval table's Skills
 * column. Prints a note to stderr; prints nothing when no case is affected.
 */
function evalsFor(changed) {
  const casesOf = new Map(); // skill -> the cases that list it
  for (const [c, named] of evalRows()) for (const s of named) casesOf.set(s, [...(casesOf.get(s) ?? []), c]);
  const skillText = skillFiles().map(([name, file]) => [name, read(file)]);
  const cases = new Set();
  const uncovered = new Set();
  const forSkill = (skill) => {
    if (!casesOf.has(skill)) uncovered.add(skill);
    for (const c of casesOf.get(skill) ?? []) cases.add(c);
  };
  for (const p of changed) {
    let m;
    if ((m = p.match(/^plugin\/skills\/([^/]+)\//))) {
      forSkill(m[1]);
    } else if (p.startsWith('plugin/reference/')) {
      // A reference file reaches a case through the skills that read it.
      const ref = p.slice('plugin/'.length);
      const readers = skillText.filter(([, text]) => text.includes(ref));
      if (!readers.length) uncovered.add(p);
      readers.forEach(([name]) => forSkill(name));
    } else if ((m = p.match(/^plugin\/evals\/(\d\d-[^/]+)\//))) {
      cases.add(m[1]);
    } else if (p.startsWith('plugin/evals/_graders/')) {
      for (const c of evalCases()) if (existsSync(path.join(ROOT, `plugin/evals/${c}/graders/${path.basename(p)}`))) cases.add(c);
    } else if (/^plugin\/(hooks\/|install\.sh|template\/|evals\/_fixture\/)/.test(p)) {
      // Every case installs the harness from these.
      evalCases().forEach((c) => cases.add(c));
    } else if (p.startsWith('plugin/') && !p.startsWith('plugin/evals/')) {
      // e.g. the output style, plugin.json, plugin/README.md: no case reads them.
      uncovered.add(p);
    }
  }
  if (cases.size) {
    console.error(`note: eval cases that cover this change (they cost money; ask before running): ` +
      [...cases].sort().join(', '));
  }
  if (uncovered.size) console.error(`note: no eval case covers ${[...uncovered].sort().join(', ')}`);
}

/**
 * Prints, as a note, the site pages that mention a changed skill, hook or the installer
 * (CLAUDE.md, "Site pages"). Prints nothing when no page does.
 */
function pagesFor(changed) {
  const wanted = new Map(); // what to report -> the strings that show a page mentions it
  for (const p of changed) {
    let m;
    if ((m = p.match(/^plugin\/skills\/([^/]+)\//))) {
      const s = m[1];
      wanted.set(s, [`skills.html#${s}"`, `/yotamake:${s}`, `<code>${s}</code>`]);
    } else if (p.startsWith('plugin/hooks/')) {
      wanted.set('hooks', [...(wanted.get('hooks') ?? ['id="hooks"']), path.basename(p)]);
    } else if (p === 'plugin/install.sh' || p.startsWith('plugin/template/')) {
      wanted.set('install', ['install.sh']);
    }
  }
  const cards = siteCards();
  const mentions = [];
  for (const page of readdirSync(path.join(ROOT, 'site')).filter((f) => f.endsWith('.html')).sort()) {
    const source = read(`site/${page}`);
    const what = [...wanted]
      .filter(([name, signs]) => signs.some((x) => source.includes(x)) || (page === 'skills.html' && cards.has(name)))
      .map(([name]) => name);
    if (what.length) mentions.push(`site/${page} (${what.sort().join(', ')})`);
  }
  if (mentions.length) console.error(`note: site pages that mention this change; check they still match: ${mentions.join(', ')}`);
}

/** "## 3. Design and reuse — before any edit" -> "Design and reuse". */
const stepName = (heading) => heading.replace(/^\d+\.\s*/, '').replace(/\s+—.*$/, '').trim();

function checkStepRefs() {
  const steps = new Map(skillFiles().map(([name, file]) => [
    name,
    new Set([...read(file).matchAll(/^## (.+)$/gm)].map((m) => stepName(m[1]))),
  ]));
  // Every doc and script under plugin/ (bar the evals), plus the root docs.
  const files = listedFiles('plugin/*.md', 'plugin/*.sh', 'README.md', 'CLAUDE.md')
    .filter((f) => !f.startsWith('plugin/evals/'));
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

/** Each shared grader as [source path, [paths of the case graders with its name]]. */
function sharedGraders() {
  return readdirSync(path.join(ROOT, 'plugin/evals/_graders')).map((name) => [
    `plugin/evals/_graders/${name}`,
    evalCases()
      .map((c) => `plugin/evals/${c}/graders/${name}`)
      .filter((f) => existsSync(path.join(ROOT, f))),
  ]);
}

function checkSharedGraders() {
  for (const [source, copies] of sharedGraders()) {
    if (!copies.length) fail('eval graders', `${source} is used by no case`);
    for (const copy of copies) {
      if (read(copy) !== read(source)) {
        fail('eval graders', `${copy} differs from ${source}; run node scripts/consistency.mjs ` +
          'sync-graders, or give a deliberate variant another name');
      }
    }
  }
}

function syncGraders() {
  for (const [source, copies] of sharedGraders()) {
    for (const copy of copies) {
      if (read(copy) !== read(source)) {
        writeFileSync(path.join(ROOT, copy), read(source));
        console.log(`updated ${copy}`);
      }
    }
  }
}

function checkPortableSed() {
  const files = listedFiles('*.sh', 'scripts/check', 'plugin/template/scripts/check', '*/pre-commit');
  for (const file of files) {
    read(file).split('\n').forEach((line, i) => {
      if (line.trimStart().startsWith('#')) return;
      // Each command in the line; in a sed command, an -i (alone or in a flag group) or
      // --in-place with no suffix is GNU-only.
      const bare = line.split(/\|\||&&|[|;]/).some((cmd) => {
        const words = cmd.trim().split(/\s+/);
        return words[0] === 'sed' && words.some((w) => /^-[a-zA-Z]*i$/.test(w) || w === '--in-place');
      });
      if (bare) {
        fail('portable sed', `${file}:${i + 1} uses sed -i without a suffix; use sed -i.bak and remove the .bak`);
      }
    });
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
} else if (process.argv[2] === 'sync-graders') {
  syncGraders();
} else if (process.argv[2] === 'evals-for') {
  evalsFor(readFileSync(0, 'utf8').split('\n').filter(Boolean));
} else if (process.argv[2] === 'pages-for') {
  pagesFor(readFileSync(0, 'utf8').split('\n').filter(Boolean));
} else {
  checkVersion();
  checkSections();
  checkLabels();
  checkEvals();
  checkSiteSkills();
  checkStepRefs();
  checkSharedGraders();
  checkPortableSed();
  checkHarnessCopies();
}

for (const p of problems) console.error(p);
process.exit(problems.length ? 1 : 0);
