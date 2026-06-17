import { Page, TestInfo, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

/// Tap targets at the locked 412x915 viewport (logical CSS px == Flutter px).
/// Measured from reference screenshots; update if the layout changes.
export const NAV = {
  enterNestFallback: { x: 206, y: 835 },
  needs: {
    calm: { x: 106, y: 292 },
    sleep: { x: 306, y: 292 },
    stress: { x: 106, y: 392 },
    mood: { x: 306, y: 392 },
    focus: { x: 106, y: 492 },
    reconnect: { x: 306, y: 492 },
    energy: { x: 106, y: 596 },
    supported: { x: 306, y: 596 },
  },
  firstPractice: { x: 206, y: 300 }, // first row on a Need screen
  bottomNav: {
    nest: { x: 40, y: 880 },
    today: { x: 132, y: 880 },
    holdMe: { x: 206, y: 856 }, // centre heart FAB
    together: { x: 286, y: 880 },
    studio: { x: 378, y: 880 },
  },
};

const runDir = process.env.QC_RUN_DIR || path.join(process.cwd(), 'qc-local');

/// Force Flutter web to build its accessibility tree (off-screen placeholder).
export async function enableA11y(page: Page) {
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (el) {
      for (const t of ['mousedown', 'mouseup', 'click']) {
        el.dispatchEvent(new MouseEvent(t, { bubbles: true, cancelable: true }));
      }
    }
  });
  await page.waitForTimeout(800);
}

/// Wait for the Flutter engine's first frame (our index.html removes the
/// #nest-splash overlay on `flutter-first-frame`).
export async function waitForApp(page: Page) {
  await page
    .waitForFunction(() => !document.getElementById('nest-splash'), null, { timeout: 30_000 })
    .catch(() => {});
  await page.waitForTimeout(1500);
}

export async function tap(page: Page, p: { x: number; y: number }) {
  await page.mouse.click(p.x, p.y);
  await page.waitForTimeout(1200);
}

/// Try to click a labelled button via the semantics tree (FilledButton/
/// TextButton expose their text). Returns false instead of throwing so a spec
/// can still capture whatever screen is shown.
export async function clickButton(page: Page, name: string | RegExp): Promise<boolean> {
  await enableA11y(page);
  try {
    await page.getByRole('button', { name }).first().click({ timeout: 6000 });
    await page.waitForTimeout(1800);
    return true;
  } catch {
    return false;
  }
}

/// Scroll the Flutter canvas (wheel events are handled by the framework).
export async function scrollDown(page: Page, dy = 380) {
  await page.mouse.move(206, 460);
  await page.mouse.wheel(0, dy);
  await page.waitForTimeout(900);
}

/// Go to the app, cross the splash, and land on Home.
export async function boot(page: Page) {
  await page.goto('/', { waitUntil: 'load' });
  await waitForApp(page);
  await enableA11y(page);
  try {
    await page.getByRole('button', { name: 'Enter the Nest' }).click({ timeout: 8000 });
  } catch {
    await tap(page, NAV.enterNestFallback); // semantics fallback
  }
  await page.waitForTimeout(2500);
}

/// Returns a labeled-screenshot helper that writes
/// <runDir>/screenshots/<spec>/NN-label.png and asserts the file exists.
export function shotter(testInfo: TestInfo) {
  const spec = path
    .basename(testInfo.file)
    .replace(/\.spec\.ts$/, '');
  const dir = path.join(runDir, 'screenshots', spec);
  fs.mkdirSync(dir, { recursive: true });
  let n = 0;
  return async function shot(page: Page, label: string) {
    n += 1;
    const slug = label.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    const file = path.join(dir, `${String(n).padStart(2, '0')}-${slug}.png`);
    await page.screenshot({ path: file });
    expect(fs.existsSync(file), `screenshot written: ${file}`).toBeTruthy();
    return file;
  };
}
