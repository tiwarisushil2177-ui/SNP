import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepository();
});

class DocumentsListState {
  const DocumentsListState({
    this.documents = const [],
    this.isLoading = false,
    this.query = '',
    this.categoryFilter,
    this.error,
  });

  final List<CaseDocument> documents;
  final bool isLoading;
  final String query;
  final String? categoryFilter;
  final String? error;

  DocumentsListState copyWith({
    List<CaseDocument>? documents,
    bool? isLoading,
    String? query,
    String? categoryFilter,
    String? error,
    bool clearCategory = false,
    bool clearError = false,
  }) {
    return DocumentsListState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DocumentsListNotifier extends StateNotifier<DocumentsListState> {
  DocumentsListNotifier(this._repo) : super(const DocumentsListState()) {
    refresh();
  }

  final DocumentsRepository _repo;

  Future<void> refresh({String? caseId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.list(
        caseId: caseId,
        query: state.query.isEmpty ? null : state.query,
        category: state.categoryFilter,
      );
      state = state.copyWith(documents: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load documents.',
      );
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    refresh();
  }

  void setCategory(String? category) {
    state = state.copyWith(
      categoryFilter: category,
      clearCategory: category == null,
    );
    refresh();
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
    final doc = await _repo.add(
      filename: filename,
      caseId: caseId,
      contentType: contentType,
      sizeBytes: sizeBytes,
      category: category,
      markOfficial: markOfficial,
      sourcePath: sourcePath,
      notes: notes,
    );
    await refresh(caseId: caseId);
    return doc;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }

  Future<void> toggleOfficial(CaseDocument doc) async {
    await _repo.update(doc.copyWith(isOfficialFiled: !doc.isOfficialFiled));
    await refresh();
  }

  Future<DocumentShareLink> share(
    String documentId, {
    int expiresInHours = 24,
    int maxDownloads = 5,
  }) {
    return _repo.createShareLink(
      documentId: documentId,
      expiresInHours: expiresInHours,
      maxDownloads: maxDownloads,
    );
  }
}

final documentsListProvider =
    StateNotifierProvider<DocumentsListNotifier, DocumentsListState>((ref) {
  return DocumentsListNotifier(ref.watch(documentsRepositoryProvider));
});
