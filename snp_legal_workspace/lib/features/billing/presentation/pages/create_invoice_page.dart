import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/billing_models.dart';
import '../providers/billing_provider.dart';

class CreateInvoicePage extends ConsumerStatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  ConsumerState<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends ConsumerState<CreateInvoicePage> {
  final _clientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _amountCtrl = TextEditingController();

  FeeModel _feeModel = FeeModel.fixed;
  double _gstPercent = 18;
  DateTime? _dueDate;
  final List<InvoiceLineItem> _lines = [];
  bool _saving = false;

  @override
  void dispose() {
    _clientCtrl.dispose();
    _notesCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _addLine() {
    final desc = _descCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (desc.isEmpty || qty <= 0 || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter description, quantity and amount.')),
      );
      return;
    }
    setState(() {
      _lines.add(InvoiceLineItem(
        description: desc,
        quantity: qty,
        unitAmount: amount,
        feeModel: _feeModel,
      ));
      _descCtrl.clear();
      _qtyCtrl.text = '1';
      _amountCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final inv = await ref.read(billingListProvider.notifier).create(
            InvoiceDraft(
              clientName: _clientCtrl.text.trim(),
              lines: List.from(_lines),
              gstPercent: _gstPercent,
              notes: _notesCtrl.text.trim(),
              dueDate: _dueDate,
            ),
          );
      if (!mounted) return;
      context.go('/billing/${inv.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save invoice.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inr = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final subtotal = _lines.fold(0.0, (s, l) => s + l.amount);
    final gst = subtotal * (_gstPercent / 100);
    final total = subtotal + gst;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('New Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          TextFormField(
            controller: _clientCtrl,
            decoration: const InputDecoration(labelText: 'Client name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FeeModel>(
            value: _feeModel,
            decoration: const InputDecoration(labelText: 'Fee model'),
            items: FeeModel.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _feeModel = v);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty / Hours'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Amount / Rate (₹)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add),
            label: const Text('Add line'),
          ),
          ..._lines.asMap().entries.map((e) {
            final line = e.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.description),
              subtitle: Text(
                  '${line.quantity} × ${inr.format(line.unitAmount)}'),
              trailing: Text(inr.format(line.amount)),
            );
          }),
          const Divider(),
          Row(
            children: [
              const Text('GST %'),
              const Spacer(),
              DropdownButton<double>(
                value: _gstPercent,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('0')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 12, child: Text('12')),
                  DropdownMenuItem(value: 18, child: Text('18')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _gstPercent = v);
                },
              ),
            ],
          ),
          Text('Subtotal ${inr.format(subtotal)}'),
          Text('GST ${inr.format(gst)}'),
          Text('Total ${inr.format(total)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Notes / UPI ID / terms'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepNavy,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create invoice'),
          ),
        ],
      ),
    );
  }
}
