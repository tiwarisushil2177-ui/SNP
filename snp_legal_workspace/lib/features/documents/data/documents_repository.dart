import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/document_models.dart';

/// Local-first document metadata store.
class DocumentsRepository {
  DocumentsRepository();

  static const _metaFile = 'snp_documents.json';
  static const _shareFile = 'snp_share_links.json';
  final _uuid = const Uuid();
  List<CaseDocument> _docs = [];
  List<DocumentShareLink> _shares = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final meta = File('${dir.path}/$_metaFile');
      if (await meta.exists()) {
        final list = jsonDecode(await meta.readAsString()) as List;
        _docs = list
            .map((e) =>
                CaseDocument.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final shares = File('${dir.path}/$_shareFile');
      if (await shares.exists()) {
        final list = jsonDecode(await shares.readAsString()) as List;
        _shares = list
            .map((e) => DocumentShareLink.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _docs = [];
      _shares = [];
    }
    _loaded = true;
  }

  Future<void> _persistDocs() async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_metaFile')
        .writeAsString(jsonEncode(_docs.map((d) => d.toJson()).toList()));
  }

  Future<void> _persistShares() async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_shareFile')
        .writeAsString(jsonEncode(_shares.map((s) => s.toJson()).toList()));
  }

  Future<List<CaseDocument>> list({
    String? caseId,
    String? query,
    String? category,
  }) async {
    await _ensureLoaded();
    var items = List<CaseDocument>.from(_docs);
    if (caseId != null) {
      items = items.where((d) => d.caseId == caseId).toList();
    }
    if (category != null && category.isNotEmpty) {
      items = items.where((d) => d.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items
          .where((d) =>
              d.filename.toLowerCase().contains(q) ||
              (d.category?.toLowerCase().contains(q) ?? false) ||
              (d.notes?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<CaseDocument?> getById(String id) async {
    await _ensureLoaded();
    try {
      return _docs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<CaseDocument> add({
    required String filename,
    String? caseId,
    String? contentType,
    int sizeBytes = 0,
    String? category,
    bool markOfficial = false,
    String? sourcePath,
    String? notes,
  }) async {
    await _ensureLoaded();
    final now = DateTime.now();
    String? localPath;
    if (sourcePath != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final store = Directory('${dir.path}/case_files');
        if (!await store.exists()) await store.create(recursive: true);
        final id = _uuid.v4();
        final dest = File('${store.path}/$id-$filename');
        await File(sourcePath).copy(dest.path);
        localPath = dest.path;
        sizeBytes = await dest.length();
      } catch (_) {
        localPath = sourcePath;
      }
    }

    if (markOfficial && caseId != null) {
      _docs = _docs
          .map((d) => d.caseId == caseId && d.isOfficialFiled
              ? d.copyWith(isOfficialFiled: false, updatedAt: now)
              : d)
          .toList();
    }

    final doc = CaseDocument(
      id: _uuid.v4(),
      caseId: caseId,
      filename: filename,
      contentType: contentType,
      sizeBytes: sizeBytes,
      category: category,
      isOfficialFiled: markOfficial,
      localPath: localPath,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    _docs = [..._docs, doc];
    await _persistDocs();
    return doc;
  }

  Future<CaseDocument> update(CaseDocument doc) async {
    await _ensureLoaded();
    final idx = _docs.indexWhere((d) => d.id == doc.id);
    if (idx < 0) throw StateError('Document not found');
    final saved = doc.copyWith(updatedAt: DateTime.now());
    if (saved.isOfficialFiled && saved.caseId != null) {
      _docs = _docs
          .map((d) => d.caseId == saved.caseId && d.id != saved.id
              ? d.copyWith(isOfficialFiled: false)
              : d)
          .toList();
    }
    _docs = [..._docs]..[idx] = saved;
    await _persistDocs();
    return saved;
  }

  Future<void> delete(String id) async {
    await _ensureLoaded();
    final doc = await getById(id);
    if (doc?.localPath != null) {
      try {
        final f = File(doc!.localPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _docs = _docs.where((d) => d.id != id).toList();
    _shares = _shares.where((s) => s.documentId != id).toList();
    await _persistDocs();
    await _persistShares();
  }

  Future<DocumentShareLink> createShareLink({
    required String documentId,
    int expiresInHours = 24,
    int maxDownloads = 5,
  }) async {
    await _ensureLoaded();
    final hours = expiresInHours.clamp(1, 168);
    final link = DocumentShareLink(
      token: _uuid.v4().replaceAll('-', ''),
      documentId: documentId,
      expiresAt: DateTime.now().add(Duration(hours: hours)),
      maxDownloads: maxDownloads.clamp(1, 50),
      downloadsRemaining: maxDownloads.clamp(1, 50),
    );
    _shares = [..._shares, link];
    await _persistShares();
    return link;
  }

  Future<void> revokeShare(String token) async {
    await _ensureLoaded();
    _shares = _shares.map((s) {
      if (s.token == token) {
        return DocumentShareLink(
          token: s.token,
          documentId: s.documentId,
          expiresAt: s.expiresAt,
          maxDownloads: s.maxDownloads,
          downloadsRemaining: s.downloadsRemaining,
          revoked: true,
        );
      }
      return s;
    }).toList();
    await _persistShares();
  }

  Future<List<DocumentShareLink>> sharesForDocument(String documentId) async {
    await _ensureLoaded();
    return _shares.where((s) => s.documentId == documentId).toList();
  }
}
