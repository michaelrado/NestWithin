import { test } from '@playwright/test';
import { boot, tap, shotter, NAV } from './_helpers';

// Guest gating: a category shows the first 2 activities free and locks the rest;
// tapping a locked one prompts account creation.
test('Locked features (guest gating)', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await boot(page);

  await tap(page, NAV.needs.calm); // Calm Me: 2 free + 2 locked + unlock banner
  await shot(page, 'need-with-locked-practices');

  // 3rd row is the first locked practice → should open the signup prompt.
  await tap(page, { x: 206, y: 450 });
  await page.waitForTimeout(1400);
  await shot(page, 'signup-prompt-from-locked-practice');
});
