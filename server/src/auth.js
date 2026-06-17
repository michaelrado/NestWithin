import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

import { db } from './db.js';

const SECRET = process.env.JWT_SECRET || 'dev-insecure-secret-change-me';
const TTL = '60d';

export const hash = (pw) => bcrypt.hash(pw, 10);
export const verify = (pw, h) => (h ? bcrypt.compare(pw, h) : Promise.resolve(false));

export const signToken = (user) =>
  jwt.sign({ uid: user.id, email: user.email }, SECRET, { expiresIn: TTL });

export const signAdmin = () => jwt.sign({ admin: true }, SECRET, { expiresIn: '7d' });

/// Express middleware: require a valid user Bearer token; attaches req.uid.
/// Also rejects tokens belonging to a disabled account.
export function requireAuth(req, res, next) {
  const token = bearer(req);
  if (!token) return res.status(401).json({ error: 'auth_required' });
  try {
    const payload = jwt.verify(token, SECRET);
    const user = db.prepare('SELECT disabled FROM users WHERE id = ?').get(payload.uid);
    if (!user) return res.status(401).json({ error: 'invalid_token' });
    if (user.disabled) return res.status(403).json({ error: 'account_disabled' });
    req.uid = payload.uid;
    next();
  } catch {
    res.status(401).json({ error: 'invalid_token' });
  }
}

/// Express middleware: require a valid admin token.
export function requireAdmin(req, res, next) {
  const token = bearer(req);
  if (!token) return res.status(401).json({ error: 'admin_auth_required' });
  try {
    const payload = jwt.verify(token, SECRET);
    if (!payload.admin) return res.status(403).json({ error: 'not_admin' });
    next();
  } catch {
    res.status(401).json({ error: 'invalid_token' });
  }
}

function bearer(req) {
  const header = req.headers.authorization || '';
  return header.startsWith('Bearer ') ? header.slice(7) : null;
}
