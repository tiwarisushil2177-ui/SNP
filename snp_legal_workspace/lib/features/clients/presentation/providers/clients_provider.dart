import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cases/presentation/providers/cases_provider.dart';
import '../../data/clients_repository.dart';
import '../../domain/client_models.dart';

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepository(
    casesRepository: ref.watch(casesRepositoryProvider),
  );
});

class ClientsListState {
  const ClientsListState({
    this.clients = const [],
    this.isLoading = false,
    this.query = '',
    this.error,
  });

  final List<ClientProfile> clients;
  final bool isLoading;
  final String query;
  final String? error;

  ClientsListState copyWith({
    List<ClientProfile>? clients,
    bool? isLoading,
    String? query,
    String? error,
    bool clearError = false,
  }) {
    return ClientsListState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ClientsListNotifier extends StateNotifier<ClientsListState> {
  ClientsListNotifier(this._repo) : super(const ClientsListState()) {
    refresh();
  }

  final ClientsRepository _repo;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.list(
        query: state.query.isEmpty ? null : state.query,
      );
      state = state.copyWith(clients: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load clients.',
      );
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    refresh();
  }

  Future<ClientProfile> create(ClientDraft draft) async {
    final created = await _repo.create(draft);
    await refresh();
    return created;
  }

  Future<ClientProfile> update(ClientProfile client) async {
    final updated = await _repo.update(client);
    await refresh();
    return updated;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }

  Future<ConflictCheckResult> conflictCheck(List<String> names) {
    return _repo.conflictCheck(names);
  }
}

final clientsListProvider =
    StateNotifierProvider<ClientsListNotifier, ClientsListState>((ref) {
  return ClientsListNotifier(ref.watch(clientsRepositoryProvider));
});

final clientByIdProvider =
    FutureProvider.family<ClientProfile?, String>((ref, id) async {
  return ref.watch(clientsRepositoryProvider).getById(id);
});
