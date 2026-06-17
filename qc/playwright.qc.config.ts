import { defineConfig, devices } from '@playwright/test';
import path from 'node:path';

/**
 * QC walkthrough config for The Nest — drives the deployed Flutter web app and
 * records video + labeled screenshots for every screen/feature.
 *
 *   Live (default): ./tool/run-qc.sh
 *   Other env:      QC_BASE_URL=https://staging... ./tool/run-qc.sh
 *
 * The app renders to a canvas, so navigation is by fixed-viewport tap
 * coordinates (see e2e/qc/_helpers.ts) at the locked 412x915 viewport.
 * Artifacts land in QC_RUN_DIR (set by tool/run-qc.sh to
 * qc/<version>-b<build>_<date>); screenshots are written by the shot() helper.
 */
const runDir = process.env.QC_RUN_DIR || path.join(process.cwd(), 'qc-local');

export default defineConfig({
  testDir: './e2e/qc',
  timeout: 120_000,
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [
    ['list'],
    ['json', { outputFile: `${runDir}/playwright-report.json` }],
  ],
  outputDir: './qc-test-results',
  use: {
    baseURL: process.env.QC_BASE_URL || 'https://nestwithin.mrrado.com',
    video: { mode: 'on', size: { width: 412, height: 915 } },
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    navigationTimeout: 60_000,
    actionTimeout: 20_000,
    viewport: { width: 412, height: 915 },
    deviceScaleFactor: 1,
  },
  projects: [
    { name: 'nest-qc', use: { ...devices['Desktop Chrome'], viewport: { width: 412, height: 915 } } },
  ],
});
