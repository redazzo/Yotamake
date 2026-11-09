# Stale-docs check: design (not built)

Written 2026-10-29 in session S9 of the `harness-next` effort. Status: design only. Build it
when the trigger at the end holds.

## The problem

The docs linter checks links and front-matter, not truth. A reference doc says `updated:` and
`owns: [subject, …]`, but subjects are names, not code paths. So nothing notices when the
code a doc describes changes and the doc does not.

## What the check does

For each reference doc, it finds the commits that changed the doc's code after its
`updated:` date, and reports them. It is a report for a person (or Claude) to read, not a
gate.

```
docs/reference/ai-pipeline.md  updated 2026-08-13  34 commits since
  6ff6ddd3 feat(prompts): shorter summary paragraphs …
  758dc7bc feat(prompts): students in a lecture or tutorial are not participants
  … (newest 5)
```

Sorted by commit count, highest first. Exit code 0 always.

## How a doc maps to code

Three options were considered:

1. **Paths the doc already cites in backticks.** No new field. Measured below. It works, but
   docs mention files in passing, and a commit to such a file flags the doc.
2. **A new `covers:` front-matter list of globs**, e.g.
   `covers: [services/ai-worker/src/**, packages/shared/src/prompts/**]`. The author says what
   the doc is about. More precise, and the linter can check each glob matches at least one
   file, so a rename is caught.
3. A table mapping each `owns:` subject to globs. Same precision as 2, but kept apart from the
   doc, so it drifts.

**Recommendation: 2, with 1 as the fallback** for a doc that has no `covers:`. Option 1 costs
nothing to adopt, so it gives a useful report on day one.

## Rules that cut noise

Measured on a real application repository (see below). Each rule removed false positives:

- Count files only. Drop directories (`packages/client/src/`), anything under `docs/`, and
  `package.json` (bumped by every release commit). Directories and `package.json` were most of
  the noise: `pwa.md` was flagged by 171 commits, all version bumps.
- Skip merge commits.
- **Skip a commit that also changed any doc in the reference folder.** Its author updated the
  owning doc, which may not be this one. Example: `d9333620` changed `VideoContext.tsx` and
  updated `central-view-panel.md`, the doc that owns the change. Without this rule it also
  flagged three docs that only mention `VideoContext.tsx`.
- Compare against the end of the `updated:` day. Commits later that same day are missed. That
  is a known gap, kept because `updated:` has no time.

## Measurements

Prototype (below) run on that repository, 14 reference docs, full history (1,750
commits). "Flagged" means at least one commit.

| As of | Rules | Flagged |
|---|---|---|
| 2026-10-29 | cited paths, dirs included | 9 / 14 |
| 2026-10-29 | all rules above | 2 / 14 |
| 2026-10-01 | all rules above | 9 / 14 |
| 2026-09-01 | all rules above | 4 / 14 |

The 2026-10-29 numbers are low partly because most docs were swept on 2026-10-26.

**How many flags are real: a quick look, not a careful one.** I read the diff and the doc text
for 5 flags raised under all the rules.

- Real: 1, borderline. `pwa.md` says to replace `public/logo.svg` when changing the logo, but
  `a673e5bb` added `logo_mobile.svg` beside it.
- Not real: 4. Each commit changed a file the doc mentions in passing (a type signature in
  `spans.ts`; `SYSTEM_CATALOGUES` in a doc that never names it; deleted `Database` types in a
  doc whose "Database Layer" is about SQL; the Watch and Learn flashcard trigger in the
  notifications doc, which covers the SSE events, not what starts the job).
- Not judged: docs flagged by many commits, such as `ai-pipeline.md` (34) and `backend.md`
  (19) as of 2026-10-01. Both were rewritten by the 2026-10-26 sweep, so the flags were
  probably right, but I did not check each commit.

So, as best I can tell: a single-commit flag is usually noise, and a many-commit flag is
usually real. That is why it is a sorted report, not a gate. `covers:` should cut the
single-commit noise, since passing mentions would no longer count. That is untested.

## Where it runs

- **Not in `scripts/check`.** False positives would block commits for no reason.
- `scripts/docs/stale-docs.mjs`, a managed file like `lint-docs.mjs`.
- The `multi-session` close-out runs it, and fixes what it reports in the docs the effort
  touched.
- `release-check` runs it and lists the top entries, as a note before the deploy.
- It needs full history. A shallow clone gives nonsense (every doc flagged by the one commit
  there is), so the script refuses to run in one and says why. CI would need
  `fetch-depth: 0`.

## Build plan, when triggered

1. `scripts/docs/stale-docs.mjs` in `plugin/template/`, managed, with the rules above.
2. `covers:` in the front-matter of each `plugin/template/docs/reference/` doc, and a linter
   rule: every glob must match a file.
3. Wire into `multi-session` close-out and `release-check`.
4. An eval case: a fixture whose doc's covered file changed after `updated:`; the close-out
   should update the doc.
5. Re-measure on video-vault with `covers:` filled in. Build only if most single-commit flags
   are real.

**Trigger to build:** a reference doc is found wrong in use, and this check would have
flagged it.

## Prototype

What produced the numbers above. Run from a repo root: `node stale-docs.mjs [ref]`.

```js
// Cited files only (no dirs, docs/, package.json); skip commits that touched any doc in the dir.
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync } from 'node:fs';
const dir = 'docs/reference', ref = process.argv[2] || 'HEAD';
const git = (...a) => execFileSync('git', a, { encoding: 'utf8', maxBuffer: 1 << 28 });
const files = new Set(git('ls-files').split('\n').filter(Boolean));
let flagged = 0, total = 0;
for (const name of readdirSync(dir).filter(n => n.endsWith('.md') && n !== 'README.md')) {
  total++;
  const text = readFileSync(`${dir}/${name}`, 'utf8');
  const updated = (text.match(/^updated:\s*(\S+)/m) || [])[1];
  if (!updated) continue;
  const paths = [...new Set([...text.matchAll(/`([A-Za-z0-9_./@-]+)`/g)].map(m => m[1].replace(/^@\//, ''))
    .filter(p => !/^docs\/|package\.json$/.test(p)).map(p => files.has(p) ? p : files.has(`packages/client/src/${p}`) ? `packages/client/src/${p}` : null).filter(Boolean))];
  if (!paths.length) continue;
  const hits = git('log', '--no-merges', `--since=${updated}T23:59:59`, '--format=%h', ref, '--', ...paths).split('\n').filter(Boolean)
    .filter(h => !git('show', '--name-only', '--format=', h).split('\n').some(f => f.startsWith(`${dir}/`)));
  if (hits.length) { flagged++; console.log(`${name} (updated ${updated}): ${hits.length} commit(s): ${hits.slice(0, 5).map(h => git('log', '-1', '--format=%h %s', h).trim()).join(' | ')}`); }
}
console.log(`flagged ${flagged}/${total}`);
```

The `packages/client/src/` prefix resolves video-vault's `@/` alias. A built version would
read aliases from config, or rely on `covers:`.
