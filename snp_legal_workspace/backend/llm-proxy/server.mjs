import http from 'node:http';
import { URL } from 'node:url';

const PORT = Number(process.env.PROXY_PORT || 8081);
const LLM_BASE = (process.env.LLM_BASE_URL || 'https://api.openai.com/v1').replace(/\/$/, '');
const LLM_KEY = process.env.LLM_API_KEY || '';
const LLM_MODEL = process.env.LLM_MODEL || 'gpt-4o-mini';
const PROXY_BEARER = process.env.PROXY_BEARER || '';

function json(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
    'Cache-Control': 'no-store',
  });
  res.end(payload);
}

function authOk(req) {
  if (!PROXY_BEARER) return false;
  return (req.headers.authorization || '') === `Bearer ${PROXY_BEARER}`;
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
  const method = req.method || 'GET';
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  if (url.pathname === '/health') {
    json(res, 200, {
      status: 'ok',
      service: 'snp-llm-proxy',
      upstreamConfigured: Boolean(LLM_KEY),
      proxyAuthConfigured: Boolean(PROXY_BEARER),
    });
    return;
  }
  if (method === 'POST' && url.pathname === '/v1/chat/completions') {
    if (!authOk(req)) {
      json(res, 401, { message: 'Unauthorized', code: 'unauthorized' });
      return;
    }
    if (!LLM_KEY) {
      json(res, 503, { message: 'LLM_API_KEY not configured', code: 'not_configured' });
      return;
    }
    const body = await readBody(req);
    if (body === null) {
      json(res, 400, { message: 'Invalid JSON', code: 'bad_request' });
      return;
    }
    const payload = {
      model: body.model || LLM_MODEL,
      temperature: body.temperature ?? 0.3,
      messages: body.messages || [],
    };
    try {
      const upstream = await fetch(`${LLM_BASE}/chat/completions`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${LLM_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(60000),
      });
      const text = await upstream.text();
      res.writeHead(upstream.status, {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
      });
      res.end(text);
    } catch (e) {
      json(res, 502, {
        message: 'Upstream LLM error',
        detail: String(e.message || e),
        code: 'upstream_error',
      });
    }
    return;
  }
  json(res, 404, { message: 'Not found' });
});

server.listen(PORT, () => {
  console.log(`SNP LLM proxy on :${PORT}`);
});
