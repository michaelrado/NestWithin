import { test } from '@playwright/test';
import { waitForApp, enableA11y, tap, shotter, NAV } from './_helpers';

test('Onboarding — splash & home', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await page.goto('/', { waitUntil: 'load' });
  await waitForApp(page);
  await shot(page, 'splash');

  await enableA11y(page);
  try {
    await page.getByRole('button', { name: 'Enter the Nest' }).click({ timeout: 8000 });
  } catch {
    await tap(page, NAV.enterNestFallback);
  }
  await page.waitForTimeout(2500);
  await shot(page, 'home-what-do-you-need');
});
