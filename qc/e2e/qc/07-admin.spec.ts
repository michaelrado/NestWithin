import { test } from '@playwright/test';
import { shotter } from './_helpers';

// The /nirvana admin console is a plain HTML page (not Flutter), so normal DOM
// selectors work. Provide QC_ADMIN_PASSWORD to also capture the dashboard.
test('Admin console /nirvana', async ({ page }, testInfo) => {
  const shot = shotter(testInfo);
  await page.goto('/nirvana', { waitUntil: 'load' });
  await page.waitForTimeout(800);
  await shot(page, 'admin-login');

  const pw = process.env.QC_ADMIN_PASSWORD;
  if (pw) {
    await page.fill('#pw', pw); // master-password path (email left blank)
    await page.getByRole('button', { name: 'Enter' }).click();
    await page.waitForTimeout(2000);
    await shot(page, 'admin-dashboard');
    await page.mouse.wheel(0, 700);
    await page.waitForTimeout(800);
    await shot(page, 'admin-users');
  }
});
