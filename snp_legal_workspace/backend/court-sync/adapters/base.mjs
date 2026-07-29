/**
 * Court adapter interface — production eCourts/NJDG access stays server-side.
 * Mobile clients only call the SNP gateway.
 */

export class CourtAdapter {
  get courtId() {
    throw new Error('not implemented');
  }

  get displayName() {
    throw new Error('not implemented');
  }

  get isProductionReady() {
    return false;
  }

  async lookupByCnr(cnr) {
    throw new Error('not implemented');
  }

  async healthCheck() {
    return { ok: true, courtId: this.courtId };
  }
}

export function normalizeStatus(raw) {
  return {
    cnr: String(raw.cnr || '').toUpperCase(),
    case_number: raw.case_number || raw.caseNumber || null,
    court_name: raw.court_name || raw.courtName || null,
    court_id: raw.court_id || raw.courtId || null,
    parties: {
      petitioners: raw.parties?.petitioners || raw.petitioners || [],
      respondents: raw.parties?.respondents || raw.respondents || [],
    },
    stage: raw.stage || null,
    next_hearing: raw.next_hearing || raw.nextHearing || null,
    last_order_date: raw.last_order_date || raw.lastOrderDate || null,
    status_text: raw.status_text || raw.statusText || null,
    source: raw.source || 'gateway',
    fetched_at: new Date().toISOString(),
  };
}
