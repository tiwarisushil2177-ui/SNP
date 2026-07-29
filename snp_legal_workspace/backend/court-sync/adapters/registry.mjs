import { DelhiDistrictAdapter } from './delhi_district.mjs';
import { LiveEcourtsAdapter, NjdgAdapter } from './live_ecourts.mjs';

const adapters = [
  new DelhiDistrictAdapter(),
  new LiveEcourtsAdapter(),
  new NjdgAdapter(),
];

export function listAdapters() {
  return adapters.map((a) => ({
    court_id: a.courtId,
    name: a.displayName,
    production_ready: a.isProductionReady,
  }));
}

export async function lookupViaAdapters(cnr) {
  for (const a of adapters) {
    if (!a.isProductionReady && a.courtId !== 'DLCT01') continue;
    try {
      const hit = await a.lookupByCnr(cnr);
      if (hit) return hit;
    } catch (e) {
      console.error(`[adapter ${a.courtId}]`, e.message || e);
    }
  }
  const delhi = adapters.find((a) => a.courtId === 'DLCT01');
  if (delhi) return delhi.lookupByCnr(cnr);
  return null;
}

export async function adapterHealth() {
  const results = [];
  for (const a of adapters) {
    results.push(await a.healthCheck());
  }
  return results;
}
