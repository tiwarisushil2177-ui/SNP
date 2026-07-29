import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/billing_models.dart';
import '../providers/billing_provider.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _inr(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingListProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search invoices…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    ref.read(billingListProvider.notifier).setQuery(v),
              )
            : const Text('Billing'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(billingListProvider.notifier).setQuery('');
                }
              });
            },
          ),
          PopupMenuButton<InvoiceStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (s) =>
                ref.read(billingListProvider.notifier).setStatusFilter(s),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All statuses')),
              ...InvoiceStatus.values.map(
                (s) => PopupMenuItem(value: s, child: Text(s.label)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/billing/new'),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt),
        label: const Text('New Invoice'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _card('Outstanding', _inr(state.outstanding),
                      AppColors.saffron),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _card('Paid this month', _inr(state.paidThisMonth),
                      AppColors.success),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && state.invoices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('No invoices yet'),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context.push('/billing/new'),
                              icon: const Icon(Icons.receipt),
                              label: const Text('New Invoice'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(billingListProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          itemCount: state.invoices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final inv = state.invoices[i];
                            return Material(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    context.push('/billing/${inv.id}'),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              inv.invoiceNumber,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Text(inv.status.label,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.saffron)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(inv.clientName ?? 'No client',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color:
                                                  AppColors.textSecondary)),
                                      const SizedBox(height: 8),
                                      Text(_inr(inv.total),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.deepNavy)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
