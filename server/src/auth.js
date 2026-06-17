import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET || 'dev-insecure-secret-change-me';
const TTL = '60d';

export const hash = (pw) => bcrypt.hash(pw, 10);
export const verify = (pw, h) => (h ? bcrypt.compare(pw, h) : Promise.resolve(false));

export const signToken = (user) =>
  jwt.sign({ uid: user.id, email: user.email }, SECRET, { expiresIn: TTL });

/// Express middleware: require a valid Bearer token; attaches req.uid.
export function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'auth_required' });
  try {
    const payload = jwt.verify(token, SECRET);
    req.uid = payload.uid;
    next();
  } catch {
    res.status(401).json({ error: 'invalid_token' });
  }
}
