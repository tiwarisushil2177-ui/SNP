import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/billing_models.dart';
import '../providers/billing_provider.dart';

class TimeEntriesPage extends ConsumerStatefulWidget {
  const TimeEntriesPage({super.key});

  @override
  ConsumerState<TimeEntriesPage> createState() => _TimeEntriesPageState();
}

class _TimeEntriesPageState extends ConsumerState<TimeEntriesPage> {
  List<TimeEntry> _entries = [];
  final Set<String> _selected = {};
  bool _loading = true;

  final _descCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '1');
  final _rateCtrl = TextEditingController(text: '5000');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref
        .read(billingListProvider.notifier)
        .timeEntries(billableOnly: false);
    if (!mounted) return;
    setState(() {
      _entries = items;
      _loading = false;
    });
  }

  Future<void> _addEntry() async {
    final desc = _descCtrl.text.trim();
    final hours = double.tryParse(_hoursCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0;
    if (desc.isEmpty || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter description and hours.')),
      );
      return;
    }
    final minutes = (hours * 60).round();
    await ref.read(billingListProvider.notifier).addTime(
          description: desc,
          minutes: minutes,
          hourlyRate: rate,
        );
    _descCtrl.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time entry saved')),
    );
  }

  Future<void> _invoiceSelected() async {
    final chosen = _entries
        .where((e) => _selected.contains(e.id) && e.invoiceId == null)
        .toList();
    if (chosen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select unbilled entries to invoice.')),
      );
      return;
    }
    final lines = chosen
        .map((e) => InvoiceLineItem(
              description: e.description,
              quantity: e.minutes / 60.0,
              unitAmount: e.hourlyRate,
              feeModel: FeeModel.hourly,
            ))
        .toList();
    final inv = await ref.read(billingListProvider.notifier).create(
          InvoiceDraft(
            clientName: 'Time billing',
            lines: lines,
            gstPercent: 18,
            notes: 'Generated from ${chosen.length} time entries',
          ),
        );
    await ref.read(billingRepositoryProvider).markTimeInvoiced(
          chosen.map((e) => e.id).toList(),
          inv.id,
        );
    if (!mounted) return;
    context.go('/billing/${inv.id}');
  }

  String _inr(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    final selectedTotal = _entries
        .where((e) => _selected.contains(e.id))
        .fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Time entries'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _invoiceSelected,
              child: Text('Invoice (${_selected.length})',
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Log time',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepNavy)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Work description',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hoursCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Hours'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _rateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Rate ₹/hr'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _addEntry,
                        icon: const Icon(Icons.timer),
                        label: const Text('Save entry'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_selected.isNotEmpty)
                  Text('Selected total: ${_inr(selectedTotal)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.saffron)),
                ..._entries.map((e) {
                  final billed = e.invoiceId != null;
                  return CheckboxListTile(
                    value: _selected.contains(e.id),
                    onChanged: billed
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(e.id);
                              } else {
                                _selected.remove(e.id);
                              }
                            });
                          },
                    title: Text(e.description),
                    subtitle: Text(
                      '${e.durationLabel} · ${_inr(e.hourlyRate)}/hr · '
                      '${DateFormat('dd MMM').format(e.date)}'
                      '${billed ? ' · Invoiced' : ''}',
                    ),
                    secondary: Text(_inr(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }),
              ],
            ),
    );
  }
}
