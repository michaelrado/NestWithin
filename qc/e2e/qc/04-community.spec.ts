import { test } from '@playwright/test';
import { boot, tap, scrollDown, shotter, NAV } from './_helpers';

test('Together — community stats & reflections', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await boot(page);

  await tap(page, NAV.bottomNav.together);
  await shot(page, 'community-top');

  await scrollDown(page, 420);
  await shot(page, 'community-popular-and-leaderboard');

  await scrollDown(page, 460);
  await shot(page, 'community-reflections');
});
