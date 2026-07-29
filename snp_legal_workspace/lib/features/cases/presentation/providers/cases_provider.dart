import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cases_repository.dart';
import '../../domain/case_models.dart';
import '../../../court_sync/data/court_sync_service.dart';
import '../../../court_sync/domain/court_sync_models.dart';
import '../../../court_sync/presentation/providers/court_sync_provider.dart';

final casesRepositoryProvider = Provider<CasesRepository>((ref) {
  return CasesRepository();
});

class CasesListState {
  const CasesListState({
    this.cases = const [],
    this.isLoading = false,
    this.query = '',
    this.stageFilter,
    this.error,
  });

  final List<LegalCase> cases;
  final bool isLoading;
  final String query;
  final CaseStage? stageFilter;
  final String? error;

  CasesListState copyWith({
    List<LegalCase>? cases,
    bool? isLoading,
    String? query,
    CaseStage? stageFilter,
    String? error,
    bool clearStage = false,
    bool clearError = false,
  }) {
    return CasesListState(
      cases: cases ?? this.cases,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      stageFilter: clearStage ? null : (stageFilter ?? this.stageFilter),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CasesListNotifier extends StateNotifier<CasesListState> {
  CasesListNotifier(this._repo) : super(const CasesListState()) {
    refresh();
  }

  final CasesRepository _repo;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.list(
        stage: state.stageFilter,
        query: state.query.isEmpty ? null : state.query,
      );
      state = state.copyWith(cases: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load cases.',
      );
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    refresh();
  }

  void setStageFilter(CaseStage? stage) {
    state = state.copyWith(
      stageFilter: stage,
      clearStage: stage == null,
    );
    refresh();
  }

  Future<LegalCase> create(CaseDraft draft) async {
    final created = await _repo.create(draft);
    await refresh();
    return created;
  }

  Future<LegalCase> update(LegalCase item) async {
    final updated = await _repo.update(item);
    await refresh();
    return updated;
  }

  Future<void> archive(String id) async {
    await _repo.archive(id);
    await refresh();
  }
}

final casesListProvider =
    StateNotifierProvider<CasesListNotifier, CasesListState>((ref) {
  return CasesListNotifier(ref.watch(casesRepositoryProvider));
});

final caseByIdProvider =
    FutureProvider.family<LegalCase?, String>((ref, id) async {
  return ref.watch(casesRepositoryProvider).getById(id);
});

class CaseFromCourtSync {
  static CaseDraft draftFrom(CourtCaseStatus status) {
    final petitioners = <String>[];
    final respondents = <String>[];
    if (status.petitioner != null && status.petitioner!.trim().isNotEmpty) {
      petitioners.add(status.petitioner!.trim());
    }
    if (status.respondent != null && status.respondent!.trim().isNotEmpty) {
      respondents.add(status.respondent!.trim());
    }
    return CaseDraft(
      cnr: status.cnr,
      court: [
        status.courtName,
        if (status.district != null) status.district,
        if (status.state != null) status.state,
      ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
      caseType: status.caseType,
      petitioners: petitioners,
      respondents: respondents,
      stage: CaseStage.fromString(status.stage),
      nextHearingDate: status.nextHearing?.date,
      nextHearingPurpose: status.nextHearing?.purpose,
    );
  }
}

final caseCnrLookupProvider =
    Provider<CourtSyncService>((ref) => ref.watch(courtSyncServiceProvider));
