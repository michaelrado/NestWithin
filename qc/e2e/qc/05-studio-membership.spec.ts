import { test } from '@playwright/test';
import { boot, tap, clickButton, scrollDown, shotter, NAV } from './_helpers';

test('Studio & membership hub', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await boot(page);

  await tap(page, NAV.bottomNav.studio);
  await shot(page, 'studio-the-nest');

  // "Become a member" (guest) or "Manage membership" (member)
  const opened =
    (await clickButton(page, /become a member/i)) ||
    (await clickButton(page, /manage membership/i));
  if (!opened) await tap(page, { x: 110, y: 300 }); // banner button fallback
  await page.waitForTimeout(1500);
  await shot(page, 'membership-your-nest');

  await scrollDown(page, 460);
  await shot(page, 'membership-accomplishments');

  await scrollDown(page, 520);
  await shot(page, 'membership-benefits-events');
});
