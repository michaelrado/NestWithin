import { test } from '@playwright/test';
import { boot, tap, clickButton, shotter, NAV } from './_helpers';

// Captures the signup and login screens. We do NOT submit — QC shouldn't create
// real accounts on each run; the screens themselves are the evidence.
test('Account — signup & login screens', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await boot(page);

  await tap(page, NAV.bottomNav.studio);
  const toMembership =
    (await clickButton(page, /become a member/i)) ||
    (await clickButton(page, /manage membership/i));
  if (!toMembership) await tap(page, { x: 110, y: 300 });
  await page.waitForTimeout(1200);

  // From the membership hub, open signup.
  const toSignup =
    (await clickButton(page, /create (your )?account/i)) ||
    (await clickButton(page, /get started/i));
  await page.waitForTimeout(1200);
  await shot(page, toSignup ? 'signup-form' : 'membership-or-signup');

  // Switch to the sign-in screen.
  const toLogin = await clickButton(page, /already have an account/i);
  await page.waitForTimeout(1000);
  if (toLogin) await shot(page, 'login-form');
});
