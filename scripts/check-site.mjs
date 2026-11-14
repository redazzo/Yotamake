#!/usr/bin/env node
/**
 * Checks the links in the landing site, site/ (published to GitHub Pages by
 * .github/workflows/pages.yml). That skills.html has a card for every skill is a
 * consistency rule (scripts/consistency.mjs, "site skills").
 *
 * Rules:
 *   - local links: every relative href or src in site/*.html names a file in site/, and
 *     every #fragment names an id on the target page.
 *   - repo links: every https://github.com/redazzo/Yotamake/blob/main/<path> link names a
 *     file in this repository, and a #fragment on a Markdown file names one of its headings.
 *
 * Exit 0 when every rule holds, 1 otherwise.
 */

import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SITE = path.join(ROOT, 'site');
const REPO_BLOB = 'https://github.com/redazzo/Yotamake/blob/main/';
const problems = [];
const fail = (rule, message) => problems.push(`${rule}: ${message}`);

const pages = readdirSync(SITE).filter((f) => f.endsWith('.html'));
const html = Object.fromEntries(pages.map((p) => [p, readFileSync(path.join(SITE, p), 'utf8')]));
const ids = Object.fromEntries(
  pages.map((p) => [p, new Set([...html[p].matchAll(/\sid="([^"]+)"/g)].map((m) => m[1]))])
);
const linksOf = (source) => [...source.matchAll(/\s(?:href|src)="([^"]+)"/g)].map((m) => m[1]);

/** GitHub's anchor for a Markdown heading: lowercase, punctuation dropped, spaces to dashes. */
const slug = (heading) =>
  heading.trim().toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu, '').replace(/\s/g, '-');

/** The heading anchors of a Markdown file in the repository, read once per file. */
const anchorCache = new Map();
function markdownAnchors(file) {
  if (!anchorCache.has(file)) {
    const source = readFileSync(path.join(ROOT, file), 'utf8').replace(/```[\s\S]*?```/g, '');
    anchorCache.set(file, new Set([...source.matchAll(/^#{1,6}\s+(.+)$/gm)].map((m) => slug(m[1]))));
  }
  return anchorCache.get(file);
}

for (const [page, source] of Object.entries(html)) {
  for (const link of linksOf(source)) {
    if (link.startsWith(REPO_BLOB)) {
      const [file, fragment] = link.slice(REPO_BLOB.length).split('#');
      const full = path.join(ROOT, file);
      if (!existsSync(full) || !statSync(full).isFile()) {
        fail('repo links', `${page}: ${link} names ${file}, which does not exist`);
      } else if (fragment && file.endsWith('.md') && !markdownAnchors(file).has(fragment)) {
        fail('repo links', `${page}: ${link} names #${fragment}, which is not a heading in ${file}`);
      }
      continue;
    }
    if (/^(https?:|mailto:)/.test(link)) continue;

    const [file, fragment] = link.split('#');
    const target = file || page;
    if (!existsSync(path.join(SITE, target))) {
      fail('local links', `${page}: ${link} names site/${target}, which does not exist`);
    } else if (fragment && target.endsWith('.html') && !ids[target]?.has(fragment)) {
      fail('local links', `${page}: ${link} names #${fragment}, which is not an id on ${target}`);
    }
  }
}

for (const p of problems) console.error(p);
process.exit(problems.length ? 1 : 0);
