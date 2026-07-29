import { CourtAdapter, normalizeStatus } from './base.mjs';

/**
 * Delhi District Courts adapter (production-shaped, fixture-backed pilot).
 * Real upstream must respect rate limits and government ToS.
 */
export class DelhiDistrictAdapter extends CourtAdapter {
  get courtId() {
    return 'DLCT01';
  }

  get displayName() {
    return 'Delhi District Courts (pilot)';
  }

  get isProductionReady() {
    return false;
  }

  async lookupByCnr(cnr) {
    const cleaned = String(cnr).replace(/[\s-]/g, '').toUpperCase();
    if (!cleaned.startsWith('DLCT') && !cleaned.startsWith('DL')) return null;
    if (cleaned.length !== 16) return null;

    return normalizeStatus({
      cnr: cleaned,
      case_number: 'CS/1234/2024',
      court_name: 'District Court, Saket, New Delhi',
      court_id: this.courtId,
      petitioners: ['Ram Kumar'],
      respondents: ['State of NCT of Delhi'],
      stage: 'Evidence',
      next_hearing: '2026-08-15',
      last_order_date: '2026-06-01',
      status_text: 'Listed for evidence',
      source: 'delhi_district_adapter',
    });
  }

  async healthCheck() {
    return {
      ok: true,
      courtId: this.courtId,
      productionReady: this.isProductionReady,
      mode: 'fixture',
    };
  }
}
