import express from 'express';
import cors from 'cors';
import { timingSafeEqual } from 'node:crypto';

import { db, newToken, consumeToken, seedDemo } from './db.js';
import { hash, verify, signToken, signAdmin, requireAuth, requireAdmin } from './auth.js';
import { sendVerifyEmail, sendResetEmail, mailConfigured } from './mail.js';
import { ADMIN_HTML } from './admin.js';

const PORT = process.env.PORT || 8091;
const APP_URL = process.env.APP_URL || 'https://nestwithin.mrrado.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';

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
  if (user.disabled) return res.status(403).json({ error: 'account_disabled' });
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

// ── Admin console (/nirvana) ─────────────────────────────────────────────--
app.get(['/nirvana', '/nirvana/'], (_req, res) => res.type('html').send(ADMIN_HTML));

app.post('/api/admin/login', (req, res) => {
  if (!ADMIN_PASSWORD) return res.status(503).json({ error: 'admin_not_configured' });
  const given = Buffer.from(String((req.body || {}).password || ''));
  const expected = Buffer.from(ADMIN_PASSWORD);
  const ok = given.length === expected.length && timingSafeEqual(given, expected);
  if (!ok) return res.status(401).json({ error: 'bad_password' });
  res.json({ token: signAdmin() });
});

app.get('/api/admin/stats', requireAdmin, (_req, res) => {
  const one = (sql) => db.prepare(sql).get().n;
  res.json({
    signupsTotal: one('SELECT COUNT(*) n FROM users WHERE is_demo = 0'),
    signups7d: one(
      "SELECT COUNT(*) n FROM users WHERE is_demo = 0 AND created_at >= datetime('now','-7 days')",
    ),
    signupsToday: one(
      "SELECT COUNT(*) n FROM users WHERE is_demo = 0 AND date(created_at) = date('now')",
    ),
    disabledCount: one('SELECT COUNT(*) n FROM users WHERE disabled = 1'),
    totalSessions: one('SELECT COUNT(*) n FROM activity'),
    topUsers: db
      .prepare(
        `SELECT u.id, u.name, u.anonymous, u.is_demo, COUNT(a.id) AS sessions
         FROM users u JOIN activity a ON a.user_id = u.id
         GROUP BY u.id ORDER BY sessions DESC LIMIT 10`,
      )
      .all(),
    popular: db
      .prepare(
        `SELECT practice_id AS practiceId, COUNT(*) AS count
         FROM activity GROUP BY practice_id ORDER BY count DESC LIMIT 10`,
      )
      .all(),
  });
});

app.get('/api/admin/users', requireAdmin, (_req, res) => {
  const users = db
    .prepare(
      `SELECT u.id, u.name, u.email, u.referral, u.rating, u.anonymous,
              u.email_verified, u.disabled, u.is_demo, u.created_at,
              (SELECT COUNT(*) FROM activity a WHERE a.user_id = u.id) AS sessions
       FROM users u ORDER BY u.is_demo ASC, u.created_at DESC`,
    )
    .all();
  res.json({ users });
});

app.post('/api/admin/users/:id/disable', requireAdmin, (req, res) => {
  const id = Number(req.params.id);
  const user = db.prepare('SELECT is_demo FROM users WHERE id = ?').get(id);
  if (!user) return res.status(404).json({ error: 'not_found' });
  if (user.is_demo) return res.status(400).json({ error: 'cannot_modify_demo' });
  db.prepare('UPDATE users SET disabled = ? WHERE id = ?').run(
    (req.body || {}).disabled ? 1 : 0,
    id,
  );
  res.json({ ok: true });
});

app.listen(PORT, '127.0.0.1', () =>
  console.log(`nest-api listening on 127.0.0.1:${PORT} (mail: ${mailConfigured() ? 'live' : 'stub'})`),
);
