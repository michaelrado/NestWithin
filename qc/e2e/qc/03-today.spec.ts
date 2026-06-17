import { test } from '@playwright/test';
import { boot, tap, scrollDown, shotter, NAV } from './_helpers';

test('Today — daily check-in & Nest Prescription', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await boot(page);

  await tap(page, NAV.bottomNav.today);
  await shot(page, 'today-check-in');

  // tap the first mood in the "How are you arriving today?" grid
  await tap(page, { x: 88, y: 470 });
  await shot(page, 'today-after-check-in');

  await scrollDown(page, 420);
  await shot(page, 'today-prescription-stats');
});
