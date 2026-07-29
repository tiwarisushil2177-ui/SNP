/**
 * Compliance: export, erase, retention, consents
 */
import fs from 'node:fs';
import crypto from 'node:crypto';

export function makeCompliance(ctx) {
  const {
    filePath, readJson, writeJson, userData, saveUserData,
    usersDb, saveUsers, json, requireAuth, audit,
  } = ctx;

  const DEFAULT_RETENTION = {
    cases_days: 2555, clients_days: 2555, documents_days: 2555,
    invoices_days: 2555, intakes_days: 1095, audit_days: 2555,
    auto_purge: false, updated_at: null,
  };

  function getRetention(userId) {
    const r = readJson(filePath('users', userId, 'retention.json'), null);
    return r ? { ...DEFAULT_RETENTION, ...r } : { ...DEFAULT_RETENTION };
  }
  function saveRetention(userId, policy) {
    writeJson(filePath('users', userId, 'retention.json'), policy);
  }
  function stores() {
    return ['cases', 'clients', 'documents', 'invoices', 'intakes', 'audit', 'breach_reports'];
  }
  function buildExport(user) {
    const data = {};
    for (const s of stores()) data[s] = userData(user.id, s);
    return {
      export_version: '1.0',
      exported_at: new Date().toISOString(),
      subject: {
        user_id: user.id, email: user.email, full_name: user.full_name,
        bar_council_id: user.bar_council_id, practice_state: user.practice_state,
        phone: user.phone, created_at: user.created_at, consents: user.consents || [],
      },
      retention: getRetention(user.id),
      stores: data,
      notice: 'SNP data subject export \u2014 confidential.',
    };
  }
  function eraseUserData(userId) {
    for (const s of stores()) {
      if (s === 'audit') {
        saveUserData(userId, 'audit', [{
          id: crypto.randomUUID(), action: 'compliance.erase',
          meta: { note: 'erased' }, severity: 'critical', at: new Date().toISOString(),
        }]);
        continue;
      }
      saveUserData(userId, s, []);
    }
    const retPath = filePath('users', userId, 'retention.json');
    if (fs.existsSync(retPath)) fs.unlinkSync(retPath);
  }
  function purgeByRetention(userId) {
    const policy = getRetention(userId);
    if (!policy.auto_purge) return { purged: {}, note: 'auto_purge false' };
    const now = Date.now();
    const purged = {};
    const map = {
      cases: policy.cases_days, clients: policy.clients_days,
      documents: policy.documents_days, invoices: policy.invoices_days,
      intakes: policy.intakes_days,
    };
    for (const [store, days] of Object.entries(map)) {
      const cutoff = now - days * 86400000;
      const items = userData(userId, store);
      const kept = items.filter((item) => {
        const t = Date.parse(item.updated_at || item.created_at || item.at || 0);
        return !t || t >= cutoff;
      });
      purged[store] = items.length - kept.length;
      saveUserData(userId, store, kept);
    }
    return { purged, policy };
  }

  async function handle(req, res, method, pathname, readBody) {
    if (method === 'GET' && pathname === '/compliance/consents') {
      const user = requireAuth(req, res);
      if (!user) return true;
      json(res, 200, { consents: user.consents || [], current_policy_version: '1.0' });
      return true;
    }
    if (method === 'GET' && pathname === '/compliance/export') {
      const user = requireAuth(req, res);
      if (!user) return true;
      audit(user.id, 'compliance.export', { severity: 'high' }, req);
      json(res, 200, buildExport(user));
      return true;
    }
    if (method === 'POST' && pathname === '/compliance/erase') {
      const user = requireAuth(req, res);
      if (!user) return true;
      const body = await readBody(req);
      if (body?.confirm !== 'ERASE_MY_DATA') {
        json(res, 400, { message: 'Send { confirm: ERASE_MY_DATA }', code: 'confirm_required' });
        return true;
      }
      audit(user.id, 'compliance.erase_requested', { severity: 'critical' }, req);
      eraseUserData(user.id);
      const db = usersDb();
      const idx = db.users.findIndex((u) => u.id === user.id);
      if (idx >= 0) {
        db.users[idx] = {
          ...db.users[idx], full_name: '[erased]', phone: null,
          bar_council_id: null, practice_state: null, consents: [],
          erased_at: new Date().toISOString(),
          password_hash: crypto.randomBytes(64).toString('hex'),
          salt: crypto.randomBytes(16).toString('hex'),
        };
        saveUsers(db);
      }
      audit(user.id, 'compliance.erase_completed', { severity: 'critical' }, req);
      json(res, 200, { ok: true, message: 'Data erased. Credentials invalidated.' });
      return true;
    }
    if (method === 'GET' && pathname === '/compliance/retention') {
      const user = requireAuth(req, res);
      if (!user) return true;
      json(res, 200, getRetention(user.id));
      return true;
    }
    if (method === 'PUT' && pathname === '/compliance/retention') {
      const user = requireAuth(req, res);
      if (!user) return true;
      const body = await readBody(req);
      if (!body || typeof body !== 'object') {
        json(res, 400, { message: 'Invalid body' });
        return true;
      }
      const next = { ...getRetention(user.id), ...body, updated_at: new Date().toISOString() };
      for (const k of ['cases_days', 'clients_days', 'documents_days', 'invoices_days', 'intakes_days', 'audit_days']) {
        if (body[k] != null) next[k] = Math.max(30, Number(body[k]) || next[k]);
      }
      if (typeof body.auto_purge === 'boolean') next.auto_purge = body.auto_purge;
      saveRetention(user.id, next);
      audit(user.id, 'compliance.retention_updated', { policy: next, severity: 'high' }, req);
      json(res, 200, next);
      return true;
    }
    if (method === 'POST' && pathname === '/compliance/retention/purge') {
      const user = requireAuth(req, res);
      if (!user) return true;
      const result = purgeByRetention(user.id);
      audit(user.id, 'compliance.retention_purge', { result, severity: 'high' }, req);
      json(res, 200, result);
      return true;
    }
    return false;
  }
  return { handle };
}
