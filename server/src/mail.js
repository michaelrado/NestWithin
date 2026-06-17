// Mailgun sender. If MAILGUN_API_KEY is unset, runs in STUB mode: it logs the
// message instead of sending, so the whole flow works before credentials land.

const FROM = process.env.MAIL_FROM || 'The Nest <no-reply@nestwithin.mrrado.com>';
const PUBLIC_URL = process.env.PUBLIC_URL || 'https://nestwithin.mrrado.com';
const APP_URL = process.env.APP_URL || 'https://nestwithin.mrrado.com';

export const mailConfigured = () => Boolean(process.env.MAILGUN_API_KEY);

async function send(to, subject, html) {
  if (!mailConfigured()) {
    console.log(`[mail:stub] to=${to} subject="${subject}"`);
    console.log(html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim());
    return { stub: true };
  }
  const host =
    (process.env.MAILGUN_REGION || 'US').toUpperCase() === 'EU'
      ? 'api.eu.mailgun.net'
      : 'api.mailgun.net';
  const domain = process.env.MAILGUN_DOMAIN;
  const auth = Buffer.from(`api:${process.env.MAILGUN_API_KEY}`).toString('base64');
  const body = new URLSearchParams({ from: FROM, to, subject, html });
  const res = await fetch(`https://${host}/v3/${domain}/messages`, {
    method: 'POST',
    headers: { Authorization: `Basic ${auth}` },
    body,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Mailgun ${res.status}: ${text}`);
  }
  return res.json();
}

const shell = (title, body) => `
  <div style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#2B3A52">
    <h2 style="color:#34527F">${title}</h2>
    ${body}
    <p style="color:#5C6B82;font-size:13px;margin-top:28px">With care,<br>The Nest 🌿</p>
  </div>`;

export function sendVerifyEmail(to, name, token) {
  const link = `${PUBLIC_URL}/api/auth/verify?token=${token}`;
  return send(
    to,
    'Confirm your email — The Nest',
    shell(
      `Welcome to the Nest, ${name.split(' ')[0]}`,
      `<p>Please confirm your email to finish setting up your account.</p>
       <p><a href="${link}" style="display:inline-block;background:#4A72B0;color:#fff;padding:12px 22px;border-radius:24px;text-decoration:none">Confirm email</a></p>
       <p style="color:#5C6B82;font-size:13px">Or paste this link: ${link}</p>`,
    ),
  );
}

export function sendResetEmail(to, name, token) {
  const link = `${APP_URL}/?reset=${token}`;
  return send(
    to,
    'Reset your password — The Nest',
    shell(
      'Reset your password',
      `<p>We received a request to reset your password. This link expires in 1 hour.</p>
       <p><a href="${link}" style="display:inline-block;background:#4A72B0;color:#fff;padding:12px 22px;border-radius:24px;text-decoration:none">Choose a new password</a></p>
       <p style="color:#5C6B82;font-size:13px">If you didn’t ask for this, you can safely ignore it.</p>`,
    ),
  );
}
