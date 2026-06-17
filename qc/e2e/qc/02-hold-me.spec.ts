import { test } from '@playwright/test';
import { boot, tap, shotter, NAV } from './_helpers';

test('Hold Me For Five Minutes sanctuary', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await boot(page);

  await tap(page, NAV.bottomNav.holdMe);
  await page.waitForTimeout(2500);
  await shot(page, 'hold-me-soul');

  await page.waitForTimeout(3500);
  await shot(page, 'hold-me-supportive-message');
});
