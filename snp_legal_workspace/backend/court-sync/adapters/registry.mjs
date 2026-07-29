import { DelhiDistrictAdapter } from './delhi_district.mjs';

const adapters = [new DelhiDistrictAdapter()];

export function listAdapters() {
  return adapters.map((a) => ({
    court_id: a.courtId,
    name: a.displayName,
    production_ready: a.isProductionReady,
  }));
}

export function getAdapterForCnr(cnr) {
  const c = String(cnr || '').toUpperCase();
  if (c.startsWith('DLCT') || c.startsWith('DL')) {
    return adapters.find((a) => a.courtId === 'DLCT01') || null;
  }
  return null;
}

export async function lookupViaAdapters(cnr) {
  const adapter = getAdapterForCnr(cnr);
  if (!adapter) return null;
  return adapter.lookupByCnr(cnr);
}

export async function adapterHealth() {
  const results = [];
  for (const a of adapters) {
    results.push(await a.healthCheck());
  }
  return results;
}
