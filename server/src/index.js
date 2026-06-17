import express from 'express';
import cors from 'cors';

import { db, newToken, consumeToken, seedDemo } from './db.js';
import { hash, verify, signToken, requireAuth } from './auth.js';
import { sendVerifyEmail, sendResetEmail, mailConfigured } from './mail.js';

const PORT = process.env.PORT || 8091;
const APP_URL = process.env.APP_URL || 'https://nestwithin.mrrado.com';

seedDemo();

const app = express();
app.use(express.json());
app.use(cors({ origin: true })); // tighten to APP_URL in prod if desired

const emailOk = (e) => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(e || '');
const publicUser = (u) => ({
  id: u.id,
  name: u.name,
  email: u.email,
  referral: u.referral,
  rating: u.rating,
  anonymous: !!u.anonymous,
  emailVerified: !!u.email_verified,
  joinedAt: u.created_at,
});

app.get('/api/health', (_req, res) =>
  res.json({ ok: true, mail: mailConfigured() ? 'live' : 'stub' }),
);

// ── Auth ───────────────────────────────────────────────────────────────────
app.post('/api/auth/signup', async (req, res) => {
  const { name, email, password, referral, rating, anonymous } = req.body || {};
  if (!name || !name.trim()) return res.status(400).json({ error: 'name_required' });
  if (!emailOk(email)) return res.status(400).json({ error: 'invalid_email' });
  if (!password || password.length < 8)
    return res.status(400).json({ error: 'weak_password' });

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase());
  if (existing) return res.status(409).json({ error: 'email_taken' });

  const info = db
    .prepare(
      `INSERT INTO users (name, email, password_hash, referral, rating, anonymous, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    )
    .run(
      name.trim(),
      email.toLowerCase(),
      await hash(password),
      referral || '',
      Number(rating) || 0,
      anonymous ? 1 : 0,
      new Date().toISOString(),
    );

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(info.lastInsertRowid);
  const token = newToken(user.id, 'verify', 72);
  try {
    await sendVerifyEmail(user.email, user.name, token);
  } catch (e) {
    console.error('verify email failed:', e.message);
  }
  res.json({ token: signToken(user), user: publicUser(user) });
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get((email || '').toLowerCase());
  if (!user || !(await verify(password, user.password_hash)))
    return res.status(401).json({ error: 'bad_credentials' });
  res.json({ token: signToken(user), user: publicUser(user) });
});

app.get('/api/auth/verify', (req, res) => {
  const uid = consumeToken(req.query.token, 'verify');
  if (!uid) return res.status(400).send('This confirmation link is invalid or expired.');
  db.prepare('UPDATE users SET email_verified = 1 WHERE id = ?').run(uid);
  res.redirect(`${APP_URL}/?verified=1`);
});

app.post('/api/auth/request-reset', async (req, res) => {
  const { email } = req.body || {};
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get((email || '').toLowerCase());
  // Always 200 so we don't leak which emails exist.
  if (user) {
    const token = newToken(user.id, 'reset', 1);
    try {
      await sendResetEmail(user.email, user.name, token);
    } catch (e) {
      console.error('reset email failed:', e.message);
    }
  }
  res.json({ ok: true });
});

app.post('/api/auth/reset', async (req, res) => {
  const { token, password } = req.body || {};
  if (!password || password.length < 8) return res.status(400).json({ error: 'weak_password' });
  const uid = consumeToken(token, 'reset');
  if (!uid) return res.status(400).json({ error: 'invalid_token' });
  db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(await hash(password), uid);
  res.json({ ok: true });
});

// ── Profile ──────────────────────────────────────────────────────────────--
app.get('/api/me', requireAuth, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.uid);
  if (!user) return res.status(404).json({ error: 'not_found' });
  res.json({ user: publicUser(user) });
});

app.patch('/api/me', requireAuth, (req, res) => {
  const { anonymous, name } = req.body || {};
  if (anonymous !== undefined)
    db.prepare('UPDATE users SET anonymous = ? WHERE id = ?').run(anonymous ? 1 : 0, req.uid);
  if (name && name.trim())
    db.prepare('UPDATE users SET name = ? WHERE id = ?').run(name.trim(), req.uid);
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.uid);
  res.json({ user: publicUser(user) });
});

// ── Activity sync ────────────────────────────────────────────────────────--
app.post('/api/activity', requireAuth, (req, res) => {
  const { practiceId, kind, seconds } = req.body || {};
  if (!practiceId) return res.status(400).json({ error: 'practiceId_required' });
  db.prepare(
    `INSERT INTO activity (user_id, practice_id, kind, seconds, created_at)
     VALUES (?, ?, ?, ?, ?)`,
  ).run(req.uid, practiceId, kind || '', Number(seconds) || 0, new Date().toISOString());
  res.json({ ok: true });
});

// ── Community stats ──────────────────────────────────────────────────────--
app.get('/api/stats/popular', (_req, res) => {
  const rows = db
    .prepare(
      `SELECT practice_id AS practiceId, COUNT(*) AS count
       FROM activity GROUP BY practice_id ORDER BY count DESC LIMIT 8`,
    )
    .all();
  res.json({ activities: rows });
});

app.get('/api/stats/active-users', (_req, res) => {
  const rows = db
    .prepare(
      `SELECT u.id, u.name, u.anonymous,
              COUNT(a.id) AS practices,
              (SELECT practice_id FROM activity WHERE user_id = u.id
                 GROUP BY practice_id ORDER BY COUNT(*) DESC LIMIT 1) AS favorite
       FROM users u JOIN activity a ON a.user_id = u.id
       GROUP BY u.id ORDER BY practices DESC LIMIT 10`,
    )
    .all();
  const users = rows.map((r) => ({
    display: r.anonymous ? 'Anonymous' : r.name,
    practices: r.practices,
    favoritePracticeId: r.favorite || 'box-breath',
    anonymous: !!r.anonymous,
  }));
  res.json({ users });
});

app.listen(PORT, '127.0.0.1', () =>
  console.log(`nest-api listening on 127.0.0.1:${PORT} (mail: ${mailConfigured() ? 'live' : 'stub'})`),
);
