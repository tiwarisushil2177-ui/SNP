import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/billing_models.dart';
import '../providers/billing_provider.dart';

class InvoiceDetailPage extends ConsumerStatefulWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  final _payCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  @override
  void dispose() {
    _payCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  String _inr(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(v);

  Future<void> _recordPayment(Invoice inv) async {
    _payCtrl.text =
        inv.balanceDue > 0 ? inv.balanceDue.toStringAsFixed(0) : '';
    _upiCtrl.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _payCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiCtrl,
              decoration:
                  const InputDecoration(labelText: 'UPI / reference'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(_payCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;
    await ref.read(billingListProvider.notifier).recordPayment(
          invoiceId: inv.id,
          amount: amount,
          upiReference:
              _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
        );
    ref.invalidate(invoiceByIdProvider(widget.invoiceId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment of ${_inr(amount)} recorded')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncInv = ref.watch(invoiceByIdProvider(widget.invoiceId));

    return asyncInv.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Could not load invoice.')),
      ),
      data: (inv) {
        if (inv == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice')),
            body: const Center(child: Text('Invoice not found.')),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.ivory,
          appBar: AppBar(
            title: Text(inv.invoiceNumber),
            actions: [
              if (inv.status == InvoiceStatus.draft)
                TextButton(
                  onPressed: () async {
                    await ref.read(billingListProvider.notifier).update(
                        inv.copyWith(status: InvoiceStatus.sent));
                    ref.invalidate(invoiceByIdProvider(widget.invoiceId));
                  },
                  child: const Text('Mark sent',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(inv.clientName ?? 'No client',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(inv.status.label,
                  style: const TextStyle(color: AppColors.saffron)),
              const SizedBox(height: 16),
              ...inv.lines.map((l) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.description),
                    subtitle: Text(
                        '${l.feeModel.label} · ${l.quantity} × ${_inr(l.unitAmount)}'),
                    trailing: Text(_inr(l.amount)),
                  )),
              const Divider(),
              _row('Subtotal', _inr(inv.subtotal)),
              _row('GST (${inv.gstPercent.toStringAsFixed(0)}%)',
                  _inr(inv.gstAmount)),
              _row('Total', _inr(inv.total), bold: true),
              if (inv.paidAmount > 0) _row('Paid', _inr(inv.paidAmount)),
              if (inv.balanceDue > 0)
                _row('Balance due', _inr(inv.balanceDue)),
              if (inv.notes != null) ...[
                const SizedBox(height: 12),
                Text(inv.notes!),
              ],
              const SizedBox(height: 24),
              if (inv.status != InvoiceStatus.paid &&
                  inv.status != InvoiceStatus.cancelled)
                FilledButton.icon(
                  onPressed: () => _recordPayment(inv),
                  icon: const Icon(Icons.payments),
                  label: const Text('Record payment'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepNavy,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? AppColors.deepNavy : null)),
        ],
      ),
    );
  }
}
