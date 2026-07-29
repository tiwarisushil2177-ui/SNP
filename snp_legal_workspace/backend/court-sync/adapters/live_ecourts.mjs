import { CourtAdapter, normalizeStatus } from './base.mjs';

function env(name, fallback = '') {
  return (process.env[name] || fallback).trim();
}

export class LiveEcourtsAdapter extends CourtAdapter {
  get courtId() {
    return 'ECOURTS_LIVE';
  }

  get displayName() {
    return 'eCourts / NJDG (live upstream)';
  }

  get isProductionReady() {
    return (
      env('ECOURTS_TOS_ACK').toLowerCase() === 'true' &&
      Boolean(env('ECOURTS_BASE_URL')) &&
      Boolean(env('ECOURTS_API_KEY'))
    );
  }

  get _base() {
    return env('ECOURTS_BASE_URL').replace(/\/$/, '');
  }

  get _key() {
    return env('ECOURTS_API_KEY');
  }

  async healthCheck() {
    const ready = this.isProductionReady;
    if (!ready) {
      return {
        ok: true,
        courtId: this.courtId,
        productionReady: false,
        mode: 'credentials_or_tos_pending',
        hint: 'Set ECOURTS_TOS_ACK=true, ECOURTS_BASE_URL, ECOURTS_API_KEY',
      };
    }
    try {
      const res = await fetch(`${this._base}/health`, {
        headers: { Authorization: `Bearer ${this._key}` },
        signal: AbortSignal.timeout(8000),
      });
      return {
        ok: res.ok,
        courtId: this.courtId,
        productionReady: true,
        mode: 'live',
        upstreamStatus: res.status,
      };
    } catch (e) {
      return {
        ok: false,
        courtId: this.courtId,
        productionReady: true,
        mode: 'live_unreachable',
        error: String(e.message || e),
      };
    }
  }

  async lookupByCnr(cnr) {
    if (!this.isProductionReady) return null;
    const cleaned = String(cnr).replace(/[\s-]/g, '').toUpperCase();
    if (cleaned.length !== 16) return null;
    const url = `${this._base}/cnr/${encodeURIComponent(cleaned)}`;
    const res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${this._key}`,
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(15000),
    });
    if (res.status === 404) return null;
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new Error(`eCourts upstream ${res.status}: ${text.slice(0, 200)}`);
    }
    const raw = await res.json();
    return normalizeStatus({
      ...raw,
      cnr: cleaned,
      source: 'ecourts_live',
      court_id: raw.court_id || this.courtId,
    });
  }
}

export class NjdgAdapter extends CourtAdapter {
  get courtId() {
    return 'NJDG';
  }

  get displayName() {
    return 'NJDG (national judicial data)';
  }

  get isProductionReady() {
    return (
      env('ECOURTS_TOS_ACK').toLowerCase() === 'true' &&
      Boolean(env('NJDG_BASE_URL')) &&
      Boolean(env('NJDG_API_KEY'))
    );
  }

  async lookupByCnr(cnr) {
    if (!this.isProductionReady) return null;
    const cleaned = String(cnr).replace(/[\s-]/g, '').toUpperCase();
    const base = env('NJDG_BASE_URL').replace(/\/$/, '');
    const res = await fetch(`${base}/cases/${encodeURIComponent(cleaned)}`, {
      headers: {
        Authorization: `Bearer ${env('NJDG_API_KEY')}`,
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(15000),
    });
    if (res.status === 404) return null;
    if (!res.ok) return null;
    const raw = await res.json();
    return normalizeStatus({ ...raw, cnr: cleaned, source: 'njdg_live' });
  }

  async healthCheck() {
    return {
      ok: true,
      courtId: this.courtId,
      productionReady: this.isProductionReady,
      mode: this.isProductionReady ? 'live' : 'credentials_or_tos_pending',
    };
  }
}
