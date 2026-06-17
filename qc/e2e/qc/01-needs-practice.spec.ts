import { test } from '@playwright/test';
import { boot, tap, shotter, NAV } from './_helpers';

test('Needs & practice player (3D soul + audio)', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await boot(page);

  await tap(page, NAV.needs.calm);
  await shot(page, 'need-calm-me');

  await tap(page, NAV.firstPractice);
  await page.waitForTimeout(2500); // soul orb + ambient bed start
  await shot(page, 'practice-player');

  await page.waitForTimeout(3000);
  await shot(page, 'practice-breathing-soul');
});
