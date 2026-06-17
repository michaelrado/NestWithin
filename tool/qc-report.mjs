#!/usr/bin/env node
/**
 * QC report generator for The Nest. Turns the Playwright JSON report into:
 *   <runDir>/videos/<spec>--<test>.webm   (copied + renamed from qc-test-results)
 *   <runDir>/RESULTS.md                    (every test, status, duration, links)
 * Screenshots are written by the specs' shot() helper into
 *   <runDir>/screenshots/<spec>/NN-label.png
 *
 * Usage: qc-report.mjs <runDir> <version> <build> <target>
 * Adapted from FairGames' scripts/qc-report.mjs.
 */
import fs from 'node:fs';
import path from 'node:path';

const [runDir, version, build, target] = process.argv.slice(2);
const reportFile = path.join(runDir, 'playwright-report.json');
if (!fs.existsSync(reportFile)) {
  console.error(`qc-report: missing ${reportFile}`);
  process.exit(1);
}
const report = JSON.parse(fs.readFileSync(reportFile, 'utf8'));
const slug = (s) =>
  s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 80);

const rows = [];
function walk(suite, specFile) {
  const file = suite.file ?? specFile;
  for (const child of suite.suites ?? []) walk(child, file);
  for (const spec of suite.specs ?? []) {
    for (const t of spec.tests ?? []) {
      const r = t.results?.[t.results.length - 1] ?? {};
      rows.push({
        spec: path.basename(spec.file ?? file ?? 'unknown').replace(/\.spec\.ts$/, ''),
        title: spec.title,
        status: r.status ?? 'skipped',
        durationMs: r.duration ?? 0,
        videoSrc: (r.attachments ?? []).find((a) => a.name === 'video')?.path ?? null,
        error: r.error?.message?.split('\n')[0] ?? null,
      });
    }
  }
}
for (const s of report.suites ?? []) walk(s);

const videosDir = path.join(runDir, 'videos');
fs.mkdirSync(videosDir, { recursive: true });
for (const row of rows) {
  if (row.videoSrc && fs.existsSync(row.videoSrc)) {
    const dest = path.join(videosDir, `${row.spec}--${slug(row.title)}.webm`);
    fs.copyFileSync(row.videoSrc, dest);
    row.video = path.relative(runDir, dest);
  }
}

const shotsDir = path.join(runDir, 'screenshots');
const shotIndex = {};
if (fs.existsSync(shotsDir)) {
  for (const d of fs.readdirSync(shotsDir)) {
    const full = path.join(shotsDir, d);
    if (fs.statSync(full).isDirectory()) shotIndex[d] = fs.readdirSync(full).sort();
  }
}

const counts = rows.reduce((m, r) => ((m[r.status] = (m[r.status] ?? 0) + 1), m), {});
const fmtDur = (ms) => (ms >= 1000 ? `${(ms / 1000).toFixed(1)}s` : `${ms}ms`);
const icon = (s) => (s === 'passed' ? '✅' : s === 'skipped' ? '⏭️' : '❌');
const stamp = path.basename(runDir);

let md = `# The Nest — QC Results — v${version} (build ${build})

- **Run:** \`${stamp}\`
- **Target:** ${target}
- **Totals:** ${rows.length} tests — ${counts.passed ?? 0} ✅ · ${counts.failed ?? 0} ❌ · ${counts.skipped ?? 0} ⏭️

| Feature | Test | Status | Time | Video |
|---|---|---|---|---|
`;
for (const r of rows) {
  md += `| ${r.spec} | ${r.title} | ${icon(r.status)} ${r.status} | ${fmtDur(r.durationMs)} | ${r.video ? `[video](${r.video})` : '—'} |\n`;
  if (r.error) md += `| | ↳ ${r.error.replace(/\|/g, '\\|')} | | | |\n`;
}

md += `\n## Screenshots\n`;
for (const spec of Object.keys(shotIndex).sort()) {
  md += `\n### ${spec}\n`;
  for (const f of shotIndex[spec]) {
    md += `- ![${f}](screenshots/${spec}/${f})\n`;
  }
}

fs.writeFileSync(path.join(runDir, 'RESULTS.md'), md);
console.log(
  `qc-report: ${rows.length} tests (${counts.passed ?? 0} passed, ${counts.failed ?? 0} failed) → RESULTS.md`,
);
