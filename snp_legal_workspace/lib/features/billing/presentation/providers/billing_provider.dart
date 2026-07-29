import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/billing_repository.dart';
import '../../domain/billing_models.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository();
});

class BillingListState {
  const BillingListState({
    this.invoices = const [],
    this.isLoading = false,
    this.query = '',
    this.statusFilter,
    this.outstanding = 0,
    this.paidThisMonth = 0,
    this.error,
  });

  final List<Invoice> invoices;
  final bool isLoading;
  final String query;
  final InvoiceStatus? statusFilter;
  final double outstanding;
  final double paidThisMonth;
  final String? error;

  BillingListState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    String? query,
    InvoiceStatus? statusFilter,
    double? outstanding,
    double? paidThisMonth,
    String? error,
    bool clearStatus = false,
    bool clearError = false,
  }) {
    return BillingListState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      outstanding: outstanding ?? this.outstanding,
      paidThisMonth: paidThisMonth ?? this.paidThisMonth,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BillingListNotifier extends StateNotifier<BillingListState> {
  BillingListNotifier(this._repo) : super(const BillingListState()) {
    refresh();
  }

  final BillingRepository _repo;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.listInvoices(
        status: state.statusFilter,
        query: state.query.isEmpty ? null : state.query,
      );
      final sum = await _repo.summary();
      state = state.copyWith(
        invoices: items,
        isLoading: false,
        outstanding: sum['outstanding'] ?? 0,
        paidThisMonth: sum['paid_this_month'] ?? 0,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load invoices.',
      );
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    refresh();
  }

  void setStatusFilter(InvoiceStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatus: status == null,
    );
    refresh();
  }

  Future<Invoice> create(InvoiceDraft draft) async {
    final inv = await _repo.createInvoice(draft);
    await refresh();
    return inv;
  }

  Future<Invoice> update(Invoice invoice) async {
    final inv = await _repo.updateInvoice(invoice);
    await refresh();
    return inv;
  }

  Future<Invoice> recordPayment({
    required String invoiceId,
    required double amount,
    String? upiReference,
  }) async {
    final inv = await _repo.recordPayment(
      invoiceId: invoiceId,
      amount: amount,
      upiReference: upiReference,
    );
    await refresh();
    return inv;
  }

  Future<void> delete(String id) async {
    await _repo.deleteInvoice(id);
    await refresh();
  }

  Future<TimeEntry> addTime({
    required String description,
    required int minutes,
    required double hourlyRate,
    String? caseId,
    String? clientId,
  }) async {
    return _repo.addTimeEntry(
      description: description,
      minutes: minutes,
      hourlyRate: hourlyRate,
      caseId: caseId,
      clientId: clientId,
    );
  }

  Future<List<TimeEntry>> timeEntries({bool billableOnly = false}) {
    return _repo.listTimeEntries(billableOnly: billableOnly);
  }
}

final billingListProvider =
    StateNotifierProvider<BillingListNotifier, BillingListState>((ref) {
  return BillingListNotifier(ref.watch(billingRepositoryProvider));
});

final invoiceByIdProvider =
    FutureProvider.family<Invoice?, String>((ref, id) async {
  return ref.watch(billingRepositoryProvider).getInvoice(id);
});
