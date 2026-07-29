import http from 'node:http';
import { URL } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.API_PORT || 8090);
const SECRET = process.env.JWT_SECRET || 'snp-dev-secret-change-in-production';
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');

fs.mkdirSync(DATA_DIR, { recursive: true });

function filePath(...parts) {
  return path.join(DATA_DIR, ...parts);
}
function readJson(fp, fallback) {
  try {
    if (!fs.existsSync(fp)) return fallback;
    return JSON.parse(fs.readFileSync(fp, 'utf8'));
  } catch {
    return fallback;
  }
}
function writeJson(fp, data) {
  fs.mkdirSync(path.dirname(fp), { recursive: true });
  fs.writeFileSync(fp, JSON.stringify(data, null, 2), 'utf8');
}
function usersDb() {
  return readJson(filePath('users.json'), { users: [] });
}
function saveUsers(db) {
  writeJson(filePath('users.json'), db);
}
function userData(userId, store) {
  return readJson(filePath('users', userId, `${store}.json`), []);
}
function saveUserData(userId, store, items) {
  writeJson(filePath('users', userId, `${store}.json`), items);
}
function hashPassword(password, salt) {
  return crypto.scryptSync(password, salt, 64).toString('hex');
}
function issueToken(user) {
  const payload = {
    sub: user.id,
    email: user.email,
    exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 7,
  };
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return `${body}.${sig}`;
}
function verifyToken(token) {
  if (!token || !token.includes('.')) return null;
  const [body, sig] = token.split('.');
  const expect = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (sig !== expect) return null;
  try {
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (payload.exp < Math.floor(Date.now() / 1000)) return null;
    return payload;
  } catch {
    return null;
  }
}
function json(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
    'Cache-Control': 'no-store',
  });
  res.end(payload);
}
function audit(userId, action, meta = {}) {
  const logs = userData(userId, 'audit');
  logs.push({ id: crypto.randomUUID(), action, meta, at: new Date().toISOString() });
  saveUserData(userId, 'audit', logs.slice(-500));
}
async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}
function authUser(req) {
  const h = req.headers.authorization || '';
  if (!h.startsWith('Bearer ')) return null;
  const payload = verifyToken(h.slice(7));
  if (!payload) return null;
  const db = usersDb();
  return db.users.find((u) => u.id === payload.sub) || null;
}
function requireAuth(req, res) {
  const user = authUser(req);
  if (!user) {
    json(res, 401, { message: 'Unauthorized', code: 'unauthorized' });
    return null;
  }
  return user;
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const { pathname } = url;
  const method = req.method || 'GET';
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  if (method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  if (pathname === '/health') {
    json(res, 200, { status: 'ok', service: 'snp-api', isolation: 'per-user-files' });
    return;
  }
  if (method === 'POST' && pathname === '/auth/register') {
    const body = await readBody(req);
    if (!body?.email || !body?.password || !body?.full_name) {
      json(res, 400, { message: 'email, password, full_name required' });
      return;
    }
    if (String(body.password).length < 8) {
      json(res, 400, { message: 'Password must be at least 8 characters' });
      return;
    }
    const db = usersDb();
    const email = String(body.email).trim().toLowerCase();
    if (db.users.some((u) => u.email === email)) {
      json(res, 409, { message: 'An account with this email already exists.' });
      return;
    }
    const salt = crypto.randomBytes(16).toString('hex');
    const user = {
      id: crypto.randomUUID(),
      email,
      full_name: String(body.full_name).trim(),
      bar_council_id: body.bar_council_id || null,
      practice_state: body.practice_state || null,
      phone: body.phone || null,
      password_hash: hashPassword(String(body.password), salt),
      salt,
      created_at: new Date().toISOString(),
      consents: [],
    };
    db.users.push(user);
    saveUsers(db);
    fs.mkdirSync(filePath('users', user.id), { recursive: true });
    audit(user.id, 'account.created', { email });
    const access = issueToken(user);
    json(res, 201, {
      access_token: access,
      refresh_token: access,
      user_id: user.id,
      advocate_name: user.full_name,
    });
    return;
  }
  if (method === 'POST' && pathname === '/auth/login') {
    const body = await readBody(req);
    if (!body?.email || !body?.password) {
      json(res, 400, { message: 'email and password required' });
      return;
    }
    const db = usersDb();
    const email = String(body.email).trim().toLowerCase();
    const user = db.users.find((u) => u.email === email);
    if (!user) {
      json(res, 401, { message: 'Invalid email or password' });
      return;
    }
    if (hashPassword(String(body.password), user.salt) !== user.password_hash) {
      json(res, 401, { message: 'Invalid email or password' });
      return;
    }
    audit(user.id, 'auth.login', {});
    const access = issueToken(user);
    json(res, 200, {
      access_token: access,
      refresh_token: access,
      user_id: user.id,
      advocate_name: user.full_name,
    });
    return;
  }
  if (method === 'GET' && pathname === '/auth/me') {
    const user = requireAuth(req, res);
    if (!user) return;
    json(res, 200, {
      user_id: user.id,
      email: user.email,
      full_name: user.full_name,
      bar_council_id: user.bar_council_id,
      practice_state: user.practice_state,
      consents: user.consents || [],
    });
    return;
  }
  if (method === 'POST' && pathname === '/auth/logout') {
    const user = authUser(req);
    if (user) audit(user.id, 'auth.logout', {});
    json(res, 200, { ok: true });
    return;
  }
  if (method === 'POST' && pathname === '/compliance/consent') {
    const user = requireAuth(req, res);
    if (!user) return;
    const body = await readBody(req);
    const record = {
      id: crypto.randomUUID(),
      purpose: body?.purpose || 'processing_case_data',
      version: body?.version || '1.0',
      granted: body?.granted !== false,
      at: new Date().toISOString(),
    };
    const db = usersDb();
    const idx = db.users.findIndex((u) => u.id === user.id);
    if (idx >= 0) {
      db.users[idx].consents = [...(db.users[idx].consents || []), record];
      saveUsers(db);
    }
    audit(user.id, 'compliance.consent', record);
    json(res, 201, record);
    return;
  }
  if (method === 'GET' && pathname === '/compliance/audit') {
    const user = requireAuth(req, res);
    if (!user) return;
    json(res, 200, { logs: userData(user.id, 'audit').reverse() });
    return;
  }
  if (method === 'POST' && pathname === '/compliance/breach-report') {
    const user = requireAuth(req, res);
    if (!user) return;
    const body = await readBody(req);
    const report = {
      id: crypto.randomUUID(),
      summary: body?.summary || '',
      discovered_at: body?.discovered_at || new Date().toISOString(),
      reported_at: new Date().toISOString(),
      status: 'logged',
    };
    const reports = userData(user.id, 'breach_reports');
    reports.push(report);
    saveUserData(user.id, 'breach_reports', reports);
    audit(user.id, 'compliance.breach_report', { id: report.id });
    json(res, 201, report);
    return;
  }
  const resourceMatch = pathname.match(
    /^\/sync\/(cases|clients|documents|invoices|intakes)(?:\/([^/]+))?$/,
  );
  if (resourceMatch) {
    const user = requireAuth(req, res);
    if (!user) return;
    const store = resourceMatch[1];
    const itemId = resourceMatch[2];
    if (method === 'GET' && !itemId) {
      json(res, 200, { items: userData(user.id, store) });
      return;
    }
    if (method === 'GET' && itemId) {
      const item = userData(user.id, store).find((i) => i.id === itemId);
      if (!item) {
        json(res, 404, { message: 'Not found' });
        return;
      }
      json(res, 200, item);
      return;
    }
    if (method === 'POST' && !itemId) {
      const body = await readBody(req);
      if (!body || typeof body !== 'object') {
        json(res, 400, { message: 'Invalid body' });
        return;
      }
      const items = userData(user.id, store);
      const item = {
        ...body,
        id: body.id || crypto.randomUUID(),
        user_id: user.id,
        updated_at: new Date().toISOString(),
        created_at: body.created_at || new Date().toISOString(),
      };
      items.push(item);
      saveUserData(user.id, store, items);
      audit(user.id, `${store}.create`, { id: item.id });
      json(res, 201, item);
      return;
    }
    if ((method === 'PUT' || method === 'PATCH') && itemId) {
      const body = await readBody(req);
      const items = userData(user.id, store);
      const idx = items.findIndex((i) => i.id === itemId);
      if (idx < 0) {
        json(res, 404, { message: 'Not found' });
        return;
      }
      items[idx] = {
        ...items[idx],
        ...body,
        id: itemId,
        user_id: user.id,
        updated_at: new Date().toISOString(),
      };
      saveUserData(user.id, store, items);
      audit(user.id, `${store}.update`, { id: itemId });
      json(res, 200, items[idx]);
      return;
    }
    if (method === 'DELETE' && itemId) {
      saveUserData(
        user.id,
        store,
        userData(user.id, store).filter((i) => i.id !== itemId),
      );
      audit(user.id, `${store}.delete`, { id: itemId });
      json(res, 200, { ok: true });
      return;
    }
  }
  json(res, 404, { message: 'Not found', code: 'not_found' });
});

server.listen(PORT, () => {
  console.log(`SNP API listening on :${PORT}`);
});
