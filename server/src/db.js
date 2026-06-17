import Database from 'better-sqlite3';
import { randomUUID } from 'node:crypto';

const DB_PATH = process.env.NEST_DB || '/var/lib/nest-api/nest.db';

export const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT,
    referral      TEXT,
    rating        INTEGER,
    anonymous     INTEGER NOT NULL DEFAULT 0,
    email_verified INTEGER NOT NULL DEFAULT 0,
    is_demo       INTEGER NOT NULL DEFAULT 0,
    disabled      INTEGER NOT NULL DEFAULT 0,
    is_admin      INTEGER NOT NULL DEFAULT 0,
    created_at    TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS tokens (
    token      TEXT PRIMARY KEY,
    user_id    INTEGER NOT NULL,
    kind       TEXT NOT NULL,            -- 'verify' | 'reset'
    expires_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS activity (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    practice_id TEXT NOT NULL,
    kind        TEXT,
    seconds     INTEGER DEFAULT 0,
    created_at  TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE INDEX IF NOT EXISTS idx_activity_practice ON activity(practice_id);
  CREATE INDEX IF NOT EXISTS idx_activity_user ON activity(user_id);
`);

// Lightweight migrations for databases created before a column existed.
function ensureColumn(table, col, def) {
  const cols = db.prepare(`PRAGMA table_info(${table})`).all();
  if (!cols.some((c) => c.name === col)) {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${col} ${def}`);
  }
}
ensureColumn('users', 'disabled', 'INTEGER NOT NULL DEFAULT 0');
ensureColumn('users', 'is_admin', 'INTEGER NOT NULL DEFAULT 0');

export function newToken(userId, kind, ttlHours) {
  const token = randomUUID().replace(/-/g, '');
  const expires = new Date(Date.now() + ttlHours * 3600 * 1000).toISOString();
  db.prepare(
    'INSERT INTO tokens (token, user_id, kind, expires_at) VALUES (?, ?, ?, ?)',
  ).run(token, userId, kind, expires);
  return token;
}

export function consumeToken(token, kind) {
  const row = db
    .prepare('SELECT * FROM tokens WHERE token = ? AND kind = ?')
    .get(token, kind);
  if (!row) return null;
  db.prepare('DELETE FROM tokens WHERE token = ?').run(token);
  if (new Date(row.expires_at).getTime() < Date.now()) return null;
  return row.user_id;
}

/// Seed a handful of demo members + activity so the community stats look alive
/// before real users arrive. Idempotent — only runs when there are no members.
export function seedDemo() {
  const count = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;
  if (count > 0) return;

  const demoUsers = [
    ['Maya R.', 'maya@example.com', 0, 142, 'box-breath'],
    ['(hidden)', 'a1@example.com', 1, 128, 'soundbath'],
    ['Theo K.', 'theo@example.com', 0, 119, 'four78'],
    ['Priya S.', 'priya@example.com', 0, 104, 'bodyscan'],
    ['(hidden)', 'a2@example.com', 1, 97, 'grounding'],
    ['Jordan M.', 'jordan@example.com', 0, 85, 'coherent'],
    ['Lena V.', 'lena@example.com', 0, 78, 'gratitude'],
    ['Sam W.', 'sam@example.com', 0, 64, 'sigh'],
  ];

  const insertUser = db.prepare(
    `INSERT INTO users (name, email, anonymous, email_verified, is_demo, created_at)
     VALUES (?, ?, ?, 1, 1, ?)`,
  );
  const insertActivity = db.prepare(
    `INSERT INTO activity (user_id, practice_id, kind, seconds, created_at)
     VALUES (?, ?, 'seed', 0, ?)`,
  );
  const now = new Date().toISOString();

  const tx = db.transaction(() => {
    for (const [name, email, anon, n, fav] of demoUsers) {
      const { lastInsertRowid } = insertUser.run(name, email, anon, now);
      // log `n` sessions, biased toward the favorite practice
      for (let i = 0; i < n; i++) {
        const pid = i % 3 === 0 ? fav : favPool[i % favPool.length];
        insertActivity.run(lastInsertRowid, pid, now);
      }
    }
  });
  tx();
}

const favPool = [
  'box-breath',
  'grounding',
  'soundbath',
  'four78',
  'bodyscan',
  'gratitude',
  'coherent',
  'lovingkindness',
  'sigh',
  'intention',
  'restore',
  'shake',
];
