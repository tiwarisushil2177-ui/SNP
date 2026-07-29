/**
 * SNP Legal Workspace — Court Sync gateway
 * Mobile clients never scrape eCourts; adapters run server-side only.
 * Run: node server.mjs
 */
import http from 'node:http';
import { URL } from 'node:url';
import {
  lookupViaAdapters,
  listAdapters,
  adapterHealth,
} from './adapters/registry.mjs';

const PORT = Number(process.env.PORT || 8080);
const CNR_RE = /^[A-Z0-9]{16}$/;

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

function normalizeCnr(raw) {
  return String(raw || '').replace(/[\s-]/g, '').toUpperCase();
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
  return true;
}

function fetchMockStatus(cnr) {
  if (!(cnr.startsWith('DL') || cnr.startsWith('MH'))) {
    return { unsupported: true };
  }
  if (cnr.endsWith('000000000000')) return { found: false };
  const next = new Date();
  next.setDate(next.getDate() + 14);
  return {
    found: true,
    cnr,
    source: 'mock',
    fetched_at: new Date().toISOString(),
    case_type: 'Civil',
    petitioner: 'Demo Petitioner',
    respondent: 'Demo Respondent',
    stage: 'Hearing',
    court_name: cnr.startsWith('DL')
      ? 'District Court, Delhi'
      : 'City Civil Court, Mumbai',
    next_hearing: {
      date: next.toISOString().slice(0, 10),
      purpose: 'Arguments',
      court_room: '12',
    },
    message: 'Fallback mock — prefer adapter result when available.',
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

async function resolveCnr(cnr) {
  const adapted = await lookupViaAdapters(cnr);
  if (adapted) {
    return { found: true, unsupported: false, ...adapted };
  }
  return fetchMockStatus(cnr);
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
    const adapters = await adapterHealth();
    json(res, 200, {
      status: 'ok',
      service: 'snp-court-sync',
      adapters,
      registry: listAdapters(),
    });
    return;
  }

  if (!requireAuth(req, res)) return;

  if (method === 'GET' && pathname === '/court-sync/supported-courts') {
    json(res, 200, { courts: SUPPORTED_COURTS, adapters: listAdapters() });
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
    const result = await resolveCnr(cnr);
    if (result.unsupported) {
      json(res, 422, {
        message:
          'This court is not yet onboarded for automatic sync. Enter hearing dates manually.',
        code: 'unsupported_court',
      });
      return;
    }
    if (result.found === false) {
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
    const result = await resolveCnr(cnr);
    if (result.unsupported) {
      json(res, 422, {
        message:
          'This court is not yet onboarded for automatic sync. Enter hearing dates manually.',
        code: 'unsupported_court',
      });
      return;
    }
    if (result.found === false) {
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
