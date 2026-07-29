import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/case_models.dart';

/// Local-first cases store for solo-advocate workspace.
/// Persists to JSON under app documents directory.
class CasesRepository {
  CasesRepository();

  static const _fileName = 'snp_cases.json';
  final _uuid = const Uuid();
  List<LegalCase> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = jsonDecode(raw) as List<dynamic>;
        _cache = list
            .map((e) => LegalCase.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _cache = [];
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    final payload = jsonEncode(_cache.map((c) => c.toJson()).toList());
    await file.writeAsString(payload);
  }

  Future<List<LegalCase>> list({
    bool includeArchived = false,
    CaseStage? stage,
    String? query,
  }) async {
    await _ensureLoaded();
    var items = _cache.where((c) => includeArchived || !c.archived).toList();
    if (stage != null) {
      items = items.where((c) => c.stage == stage).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items.where((c) {
        final hay = [
          c.cnr,
          c.court,
          c.caseType,
          c.parties.summary,
          c.notes,
          ...c.sections,
          ...c.parties.petitioners,
          ...c.parties.respondents,
        ].whereType<String>().join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    items.sort((a, b) {
      final ad = a.nextHearingDate;
      final bd = b.nextHearingDate;
      if (ad == null && bd == null) return b.updatedAt.compareTo(a.updatedAt);
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return items;
  }

  Future<LegalCase?> getById(String id) async {
    await _ensureLoaded();
    try {
      return _cache.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<LegalCase> create(CaseDraft draft) async {
    await _ensureLoaded();
    final now = DateTime.now();
    final cnr = draft.cnr?.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final item = LegalCase(
      id: _uuid.v4(),
      cnr: (cnr == null || cnr.isEmpty) ? null : cnr,
      court: draft.court?.trim().isEmpty == true ? null : draft.court?.trim(),
      caseType:
          draft.caseType?.trim().isEmpty == true ? null : draft.caseType?.trim(),
      parties: CaseParties(
        petitioners: draft.petitioners
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        respondents: draft.respondents
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      ),
      sections: draft.sections
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      filingDate: draft.filingDate,
      stage: draft.stage,
      nextHearingDate: draft.nextHearingDate,
      nextHearingPurpose: draft.nextHearingPurpose?.trim().isEmpty == true
          ? null
          : draft.nextHearingPurpose?.trim(),
      opposingCounsel: draft.opposingCounsel?.trim().isEmpty == true
          ? null
          : draft.opposingCounsel?.trim(),
      notes: draft.notes?.trim().isEmpty == true ? null : draft.notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _cache = [..._cache, item];
    await _persist();
    return item;
  }

  Future<LegalCase> update(LegalCase updated) async {
    await _ensureLoaded();
    final idx = _cache.indexWhere((c) => c.id == updated.id);
    if (idx < 0) throw StateError('Case not found');
    final saved = updated.copyWith(updatedAt: DateTime.now());
    _cache = [..._cache]..[idx] = saved;
    await _persist();
    return saved;
  }

  Future<void> archive(String id) async {
    final existing = await getById(id);
    if (existing == null) return;
    await update(existing.copyWith(archived: true));
  }

  Future<List<LegalCase>> hearingsOn(DateTime day) async {
    final all = await list();
    final d = DateTime(day.year, day.month, day.day);
    return all.where((c) {
      final h = c.nextHearingDate;
      if (h == null) return false;
      return h.year == d.year && h.month == d.month && h.day == d.day;
    }).toList();
  }

  Future<List<LegalCase>> hearingsBetween(DateTime from, DateTime to) async {
    final all = await list();
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return all.where((c) {
      final h = c.nextHearingDate;
      if (h == null) return false;
      return !h.isBefore(start) && !h.isAfter(end);
    }).toList()
      ..sort((a, b) => a.nextHearingDate!.compareTo(b.nextHearingDate!));
  }
}
