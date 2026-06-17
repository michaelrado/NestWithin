import { test } from '@playwright/test';
import { boot, gotoLogin, login, tap, scrollDown, shotter, NAV } from './_helpers';

// Logs in with a real test user and reviews the unlocked experience.
// Provide QC_TEST_EMAIL / QC_TEST_PASSWORD (an existing account); otherwise skipped.
test('Signed-in test user — unlocked experience', async ({ page }, testInfo) => {
  const email = process.env.QC_TEST_EMAIL;
  const password = process.env.QC_TEST_PASSWORD;
  test.skip(!email || !password, 'set QC_TEST_EMAIL / QC_TEST_PASSWORD to run');
  const shot = shotter(testInfo);

  await boot(page);
  await gotoLogin(page);
  await shot(page, 'login-form');

  await login(page, email!, password!);
  await shot(page, 'signed-in-membership'); // member card, benefits unlocked
  await scrollDown(page, 520);
  await shot(page, 'signed-in-unlocked-events');

  // Back to Home, open a category — every practice is now unlocked.
  await tap(page, { x: 28, y: 28 }); // back from membership
  await tap(page, NAV.bottomNav.nest);
  await tap(page, NAV.needs.calm);
  await shot(page, 'need-all-unlocked');

  // Open a previously-locked practice to confirm access.
  await tap(page, { x: 206, y: 450 });
  await page.waitForTimeout(2500);
  await shot(page, 'previously-locked-practice-now-playable');
});
