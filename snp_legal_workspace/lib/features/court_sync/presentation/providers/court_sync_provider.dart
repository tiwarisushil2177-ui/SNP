import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/court_sync_service.dart';
import '../../domain/court_sync_models.dart';

final courtSyncServiceProvider = Provider<CourtSyncService>((ref) {
  return CourtSyncService(ref.watch(apiClientProvider));
});

class CourtSyncUiState {
  const CourtSyncUiState({
    this.isLoading = false,
    this.result,
    this.cnrInput = '',
  });

  final bool isLoading;
  final CourtSyncResult? result;
  final String cnrInput;

  CourtSyncUiState copyWith({
    bool? isLoading,
    CourtSyncResult? result,
    String? cnrInput,
    bool clearResult = false,
  }) {
    return CourtSyncUiState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      cnrInput: cnrInput ?? this.cnrInput,
    );
  }
}

class CourtSyncNotifier extends StateNotifier<CourtSyncUiState> {
  CourtSyncNotifier(this._service) : super(const CourtSyncUiState());

  final CourtSyncService _service;

  void setCnr(String value) {
    state = state.copyWith(cnrInput: value, clearResult: true);
  }

  Future<void> lookup() async {
    final cnr = state.cnrInput.trim();
    if (cnr.isEmpty) return;
    state = state.copyWith(isLoading: true, clearResult: true);
    final result = await _service.lookupByCnr(cnr);
    state = state.copyWith(isLoading: false, result: result);
  }

  Future<void> refreshForCase({
    required String cnr,
    String? localCaseId,
    DateTime? localNextHearing,
    String? localStage,
  }) async {
    state = state.copyWith(isLoading: true, clearResult: true);
    final result = await _service.refreshAndCompare(
      cnr: cnr,
      localCaseId: localCaseId,
      localNextHearing: localNextHearing,
      localStage: localStage,
    );
    state = state.copyWith(isLoading: false, result: result);
  }

  void clear() {
    state = const CourtSyncUiState();
  }
}

final courtSyncProvider =
    StateNotifierProvider<CourtSyncNotifier, CourtSyncUiState>((ref) {
  return CourtSyncNotifier(ref.watch(courtSyncServiceProvider));
});
