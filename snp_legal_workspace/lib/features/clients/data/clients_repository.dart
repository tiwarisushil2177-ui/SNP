import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../cases/data/cases_repository.dart';
import '../domain/client_models.dart';

class ClientsRepository {
  ClientsRepository({CasesRepository? casesRepository})
      : _cases = casesRepository ?? CasesRepository();

  static const _fileName = 'snp_clients.json';
  final _uuid = const Uuid();
  final CasesRepository _cases;
  List<ClientProfile> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final list = jsonDecode(await file.readAsString()) as List;
        _cache = list
            .map((e) =>
                ClientProfile.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _cache = [];
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_fileName')
        .writeAsString(jsonEncode(_cache.map((c) => c.toJson()).toList()));
  }

  Future<List<ClientProfile>> list({String? query}) async {
    await _ensureLoaded();
    var items = List<ClientProfile>.from(_cache);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items.where((c) {
        final hay = [
          c.name,
          c.email,
          c.phone,
          c.address,
          c.notes,
          ...c.tags,
        ].whereType<String>().join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<ClientProfile?> getById(String id) async {
    await _ensureLoaded();
    try {
      return _cache.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ClientProfile> create(ClientDraft draft) async {
    await _ensureLoaded();
    final name = draft.name.trim();
    if (name.isEmpty) throw ArgumentError('Name is required');
    final now = DateTime.now();
    final client = ClientProfile(
      id: _uuid.v4(),
      name: name,
      email: _emptyToNull(draft.email),
      phone: _emptyToNull(draft.phone),
      address: _emptyToNull(draft.address),
      notes: _emptyToNull(draft.notes),
      createdAt: now,
      updatedAt: now,
    );
    _cache = [..._cache, client];
    await _persist();
    return client;
  }

  Future<ClientProfile> update(ClientProfile client) async {
    await _ensureLoaded();
    final idx = _cache.indexWhere((c) => c.id == client.id);
    if (idx < 0) throw StateError('Client not found');
    final saved = client.copyWith(updatedAt: DateTime.now());
    _cache = [..._cache]..[idx] = saved;
    await _persist();
    return saved;
  }

  Future<void> delete(String id) async {
    await _ensureLoaded();
    _cache = _cache.where((c) => c.id != id).toList();
    await _persist();
  }

  Future<ConflictCheckResult> conflictCheck(List<String> partyNames) async {
    await _ensureLoaded();
    final names = partyNames
        .map((n) => n.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return const ConflictCheckResult(hasConflict: false);
    }

    final matches = <ConflictMatch>[];

    for (final client in _cache) {
      final cn = client.name.toLowerCase();
      for (final n in names) {
        if (cn == n || cn.contains(n) || n.contains(cn)) {
          matches.add(ConflictMatch(
            partyName: client.name,
            source: 'client',
            clientId: client.id,
            role: 'client',
          ));
        }
      }
    }

    final cases = await _cases.list(includeArchived: true);
    for (final c in cases) {
      for (final p in c.parties.petitioners) {
        final pn = p.toLowerCase();
        for (final n in names) {
          if (pn == n || pn.contains(n) || n.contains(pn)) {
            matches.add(ConflictMatch(
              partyName: p,
              source: 'case',
              caseId: c.id,
              role: 'petitioner',
            ));
          }
        }
      }
      for (final r in c.parties.respondents) {
        final rn = r.toLowerCase();
        for (final n in names) {
          if (rn == n || rn.contains(n) || n.contains(rn)) {
            matches.add(ConflictMatch(
              partyName: r,
              source: 'case',
              caseId: c.id,
              role: 'respondent',
            ));
          }
        }
      }
    }

    final seen = <String>{};
    final unique = <ConflictMatch>[];
    for (final m in matches) {
      final key = '${m.source}:${m.clientId ?? m.caseId}:${m.partyName}';
      if (seen.add(key)) unique.add(m);
    }

    return ConflictCheckResult(
      hasConflict: unique.isNotEmpty,
      matches: unique,
    );
  }

  String? _emptyToNull(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }
}
