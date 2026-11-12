#!/usr/bin/env node
/**
 * Summarises what the saved eval runs cost.
 *
 *   node scripts/eval-costs.mjs                 every run under plugin/evals/results/
 *   node scripts/eval-costs.mjs <results dir>   one run: a folder holding
 *                                               aggregate-result.json (a path, or its
 *                                               name under plugin/evals/results/)
 *
 * `claude plugin eval` saves each run as plugin/evals/results/<timestamp>/
 * aggregate-result.json (git-ignored). This prints one row per case and arm ("with" the
 * plugin, or "without" it in a baseline run): runs, how many passed, pass rate, and the
 * mean cost, turns and seconds per run. Runs that ended in an error count against the pass
 * rate but are left out of the means, and the Err column counts them. Cost leaves out the
 * judge's cost. The results hold no token counts. Last, it names the Claude Code and plugin
 * versions the runs cover.
 *
 * Exit 0, or 1 when there are no results to read.
 */

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const RESULTS = path.join(ROOT, 'plugin/evals/results');
const FILE = 'aggregate-result.json';

/** The aggregate-result.json files to read. */
function resultFiles(arg) {
  if (arg) {
    const dir = existsSync(arg) ? path.resolve(arg) : path.join(RESULTS, arg);
    const file = path.join(dir, FILE);
    if (!existsSync(file)) {
      console.error(`eval-costs: no ${FILE} in ${dir}`);
      process.exit(1);
    }
    return [file];
  }
  if (!existsSync(RESULTS)) return [];
  return readdirSync(RESULTS)
    .sort()
    .map((d) => path.join(RESULTS, d, FILE))
    .filter((f) => existsSync(f));
}

const files = resultFiles(process.argv[2]);
if (files.length === 0) {
  console.error(`eval-costs: no saved results under ${path.relative(ROOT, RESULTS)}/`);
  process.exit(1);
}

const rows = new Map(); // "case\0arm" -> { name, arm, runs: [] }
const claudeVersions = new Set();
const pluginVersions = new Set();
const dates = [];

for (const file of files) {
  const result = JSON.parse(readFileSync(file, 'utf8'));
  if (result.claudeVersion) claudeVersions.add(result.claudeVersion);
  for (const p of result.suite?.plugins ?? []) if (p.version) pluginVersions.add(p.version);
  if (result.startedAt) dates.push(result.startedAt.slice(0, 10));
  for (const c of result.cases ?? []) {
    for (const [arm, runs] of Object.entries(c.arms ?? {})) {
      if (!Array.isArray(runs) || runs.length === 0) continue;
      const key = `${c.name}\0${arm}`;
      const row = rows.get(key) ?? rows.set(key, { name: c.name, arm, runs: [] }).get(key);
      row.runs.push(...runs);
    }
  }
}

/** Mean of a numeric field over the runs that have it; NaN when none do. */
const mean = (runs, field) => {
  const values = runs.map((r) => r[field]).filter((v) => typeof v === 'number');
  return values.length ? values.reduce((sum, v) => sum + v, 0) / values.length : NaN;
};
const fixed = (n, digits) => (Number.isNaN(n) ? '-' : n.toFixed(digits));

const table = [['Case', 'Arm', 'Runs', 'Passed', 'Rate', 'Err', 'Cost $', 'Turns', 'Secs']];
for (const { name, arm, runs } of [...rows.values()].sort(
  (a, b) => a.name.localeCompare(b.name) || a.arm.localeCompare(b.arm),
)) {
  const clean = runs.filter((r) => !r.error);
  const passed = runs.filter((r) => r.passed).length;
  table.push([
    name,
    arm,
    String(runs.length),
    String(passed),
    `${Math.round((100 * passed) / runs.length)}%`,
    String(runs.length - clean.length),
    fixed(mean(clean, 'costUsd'), 2),
    fixed(mean(clean, 'turns'), 0),
    fixed(mean(clean, 'durationSeconds'), 0),
  ]);
}

const widths = table[0].map((_, i) => Math.max(...table.map((row) => row[i].length)));
for (const row of table) {
  // Text columns left-aligned, numbers right-aligned.
  console.log(row.map((cell, i) => (i < 2 ? cell.padEnd(widths[i]) : cell.padStart(widths[i]))).join('  '));
}

dates.sort();
const byVersion = (a, b) => a.localeCompare(b, undefined, { numeric: true });
const list = (set) => [...set].sort(byVersion).join(', ') || 'unknown';
console.log('');
console.log(`${files.length} result file(s), ${dates[0] ?? '?'} to ${dates.at(-1) ?? '?'}`);
console.log(`Claude Code: ${list(claudeVersions)}`);
console.log(`Plugin: ${list(pluginVersions)}`);
