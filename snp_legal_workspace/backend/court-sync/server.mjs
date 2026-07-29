/**
 * SNP Legal Workspace — Court Sync gateway (dev / reference implementation)
 *
 * Zero external dependencies (Node 18+ http module only).
 *
 * Production must:
 *  - Authenticate Bearer JWTs
 *  - Rate-limit per advocate
 *  - Talk to eCourts / NJDG / High Court adapters server-side only
 *  - Roll out supported courts incrementally
 *
 * Mobile clients call these endpoints — they never scrape court portals.
 *
 * Run:  node server.mjs
 * Port: process.env.PORT || 8080
 */

import http from 'node:http';
import { URL } from 'node:url';

const PORT = Number(process.env.PORT || 8080);

const SUPPORTED_COURTS = [
  {
    id: 'ecourts-delhi-district',
    name: 'Delhi District Courts (eCourts)',
    state: 'Delhi',
    source: 'ecourts',
  },
  {
    id: 'ecourts-mumbai-city',
    name: 'Mumbai City Civil & Sessions (eCourts)',
    state: 'Maharashtra',
    source: 'ecourts',
  },
  {
    id: 'hc-delhi',
    name: 'Delhi High Court',
    state: 'Delhi',
    source: 'high_court',
    high_court_code: 'DHC',
  },
];

const CNR_RE = /^[A-Z0-9]{16}$/;

function normalizeCnr(raw) {
  return String(raw || '')
    .replace(/[\s-]/g, '')
    .toUpperCase();
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

function requireAuth(req, res) {
  const h = req.headers.authorization || '';
  if (!h.startsWith('Bearer ') || h.length < 20) {
    json(res, 401, { message: 'Unauthorized', code: 'unauthorized' });
    return false;
  }
  // Production: verify JWT signature, expiry, and advocate subject.
  return true;
}

function isSupportedCnr(cnr) {
  return cnr.startsWith('DL') || cnr.startsWith('MH');
}

function fetchMockStatus(cnr) {
  if (!isSupportedCnr(cnr)) {
    return { unsupported: true };
  }
  if (cnr.endsWith('000000000000')) {
    return { found: false };
  }

  const next = new Date();
  next.setDate(next.getDate() + 14);

  return {
    found: true,
    cnr,
    source: cnr.startsWith('DL') && cnr.includes('HC') ? 'high_court' : 'ecourts',
    fetched_at: new Date().toISOString(),
    case_type: 'Civil',
    filing_number: 'F-DEMO-001',
    registration_number: 'R-DEMO-001',
    petitioner: 'Demo Petitioner',
    respondent: 'Demo Respondent',
    stage: 'Hearing',
    court_name: cnr.startsWith('DL')
      ? 'District Court, Delhi'
      : 'City Civil Court, Mumbai',
    district: cnr.startsWith('DL') ? 'Central' : 'Mumbai',
    state: cnr.startsWith('DL') ? 'Delhi' : 'Maharashtra',
    next_hearing: {
      date: next.toISOString().slice(0, 10),
      purpose: 'Arguments',
      court_room: '12',
      judge_name: null,
      business_date: null,
    },
    message: 'Demo snapshot — replace with live court gateway in production.',
  };
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

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const { pathname } = url;
  const method = req.method || 'GET';

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (pathname === '/health') {
    json(res, 200, { status: 'ok', service: 'snp-court-sync' });
    return;
  }

  if (!requireAuth(req, res)) return;

  if (method === 'GET' && pathname === '/court-sync/supported-courts') {
    json(res, 200, { courts: SUPPORTED_COURTS });
    return;
  }

  const cnrMatch = pathname.match(/^\/court-sync\/cnr\/([^/]+)$/);
  if (method === 'GET' && cnrMatch) {
    const cnr = normalizeCnr(decodeURIComponent(cnrMatch[1]));
    if (!CNR_RE.test(cnr)) {
      json(res, 400, {
        message: 'Invalid CNR format. Expected 16 alphanumeric characters.',
        code: 'invalid_cnr',
      });
      return;
    }
    const result = fetchMockStatus(cnr);
    if (result.unsupported) {
      json(res, 422, {
        message:
          'This court is not yet onboarded for automatic sync. Enter hearing dates manually.',
        code: 'unsupported_court',
      });
      return;
    }
    if (!result.found) {
      json(res, 404, { message: 'No case found for this CNR.', code: 'not_found' });
      return;
    }
    json(res, 200, result);
    return;
  }

  if (method === 'POST' && pathname === '/court-sync/refresh') {
    const body = await readBody(req);
    if (body === null) {
      json(res, 400, { message: 'Invalid JSON body', code: 'bad_request' });
      return;
    }
    const cnr = normalizeCnr(body.cnr);
    if (!CNR_RE.test(cnr)) {
      json(res, 400, {
        message: 'Invalid CNR format. Expected 16 alphanumeric characters.',
        code: 'invalid_cnr',
      });
      return;
    }
    const result = fetchMockStatus(cnr);
    if (result.unsupported) {
      json(res, 422, {
        message:
          'This court is not yet onboarded for automatic sync. Enter hearing dates manually.',
        code: 'unsupported_court',
      });
      return;
    }
    if (!result.found) {
      json(res, 404, { message: 'Case not found.', code: 'not_found' });
      return;
    }
    json(res, 200, result);
    return;
  }

  json(res, 404, { message: 'Not found', code: 'not_found' });
});

server.listen(PORT, () => {
  console.log(`SNP Court Sync listening on :${PORT}`);
});
