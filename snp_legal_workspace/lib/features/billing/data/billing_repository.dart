import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/billing_models.dart';

class BillingRepository {
  BillingRepository();

  static const _invoiceFile = 'snp_invoices.json';
  static const _timeFile = 'snp_time_entries.json';
  final _uuid = const Uuid();
  List<Invoice> _invoices = [];
  List<TimeEntry> _time = [];
  bool _loaded = false;
  int _invoiceSeq = 0;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final inv = File('${dir.path}/$_invoiceFile');
      if (await inv.exists()) {
        final list = jsonDecode(await inv.readAsString()) as List;
        _invoices = list
            .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _invoiceSeq = _invoices.length;
      }
      final t = File('${dir.path}/$_timeFile');
      if (await t.exists()) {
        final list = jsonDecode(await t.readAsString()) as List;
        _time = list
            .map((e) =>
                TimeEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _invoices = [];
      _time = [];
    }
    _loaded = true;
  }

  Future<void> _persistInvoices() async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_invoiceFile').writeAsString(
        jsonEncode(_invoices.map((e) => e.toJson()).toList()));
  }

  Future<void> _persistTime() async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_timeFile')
        .writeAsString(jsonEncode(_time.map((e) => e.toJson()).toList()));
  }

  String _nextInvoiceNumber() {
    _invoiceSeq += 1;
    final year = DateTime.now().year;
    return 'SNP-$year-${_invoiceSeq.toString().padLeft(4, '0')}';
  }

  Future<List<Invoice>> listInvoices({
    InvoiceStatus? status,
    String? query,
  }) async {
    await _ensureLoaded();
    var items = List<Invoice>.from(_invoices);
    if (status != null) {
      items = items.where((i) => i.status == status).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items.where((i) {
        final hay = [
          i.invoiceNumber,
          i.clientName,
          i.notes,
          ...i.lines.map((l) => l.description),
        ].whereType<String>().join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<Invoice?> getInvoice(String id) async {
    await _ensureLoaded();
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Invoice> createInvoice(InvoiceDraft draft) async {
    await _ensureLoaded();
    final now = DateTime.now();
    final invoice = Invoice(
      id: _uuid.v4(),
      invoiceNumber: _nextInvoiceNumber(),
      clientId: draft.clientId,
      clientName: draft.clientName?.trim().isEmpty == true
          ? null
          : draft.clientName?.trim(),
      caseId: draft.caseId,
      lines: draft.lines,
      gstPercent: draft.gstPercent,
      notes: draft.notes?.trim().isEmpty == true ? null : draft.notes?.trim(),
      dueDate: draft.dueDate,
      createdAt: now,
      updatedAt: now,
    );
    _invoices = [..._invoices, invoice];
    await _persistInvoices();
    return invoice;
  }

  Future<Invoice> updateInvoice(Invoice invoice) async {
    await _ensureLoaded();
    final idx = _invoices.indexWhere((i) => i.id == invoice.id);
    if (idx < 0) throw StateError('Invoice not found');
    final saved = invoice.copyWith(updatedAt: DateTime.now());
    _invoices = [..._invoices]..[idx] = saved;
    await _persistInvoices();
    return saved;
  }

  Future<Invoice> recordPayment({
    required String invoiceId,
    required double amount,
    String? upiReference,
  }) async {
    final inv = await getInvoice(invoiceId);
    if (inv == null) throw StateError('Invoice not found');
    final paid = inv.paidAmount + amount;
    InvoiceStatus status;
    if (paid >= inv.total - 0.01) {
      status = InvoiceStatus.paid;
    } else if (paid > 0) {
      status = InvoiceStatus.partiallyPaid;
    } else {
      status = inv.status;
    }
    return updateInvoice(inv.copyWith(
      paidAmount: paid,
      status: status,
      upiReference: upiReference ?? inv.upiReference,
    ));
  }

  Future<void> deleteInvoice(String id) async {
    await _ensureLoaded();
    _invoices = _invoices.where((i) => i.id != id).toList();
    await _persistInvoices();
  }

  Future<List<TimeEntry>> listTimeEntries({
    String? caseId,
    bool? billableOnly,
  }) async {
    await _ensureLoaded();
    var items = List<TimeEntry>.from(_time);
    if (caseId != null) {
      items = items.where((t) => t.caseId == caseId).toList();
    }
    if (billableOnly == true) {
      items = items.where((t) => t.billable && t.invoiceId == null).toList();
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<TimeEntry> addTimeEntry({
    required String description,
    required int minutes,
    required double hourlyRate,
    String? caseId,
    String? clientId,
    bool billable = true,
    DateTime? date,
  }) async {
    await _ensureLoaded();
    final entry = TimeEntry(
      id: _uuid.v4(),
      caseId: caseId,
      clientId: clientId,
      description: description.trim(),
      minutes: minutes,
      hourlyRate: hourlyRate,
      billable: billable,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
    _time = [..._time, entry];
    await _persistTime();
    return entry;
  }

  Future<void> deleteTimeEntry(String id) async {
    await _ensureLoaded();
    _time = _time.where((t) => t.id != id).toList();
    await _persistTime();
  }

  Future<void> markTimeInvoiced(List<String> entryIds, String invoiceId) async {
    await _ensureLoaded();
    _time = _time.map((t) {
      if (entryIds.contains(t.id)) {
        return TimeEntry(
          id: t.id,
          caseId: t.caseId,
          clientId: t.clientId,
          description: t.description,
          minutes: t.minutes,
          hourlyRate: t.hourlyRate,
          billable: t.billable,
          invoiceId: invoiceId,
          date: t.date,
          createdAt: t.createdAt,
        );
      }
      return t;
    }).toList();
    await _persistTime();
  }

  Future<Map<String, double>> summary() async {
    final all = await listInvoices();
    double outstanding = 0;
    double paidThisMonth = 0;
    final now = DateTime.now();
    for (final i in all) {
      if (i.status != InvoiceStatus.cancelled &&
          i.status != InvoiceStatus.paid) {
        outstanding += i.balanceDue;
      }
      if (i.status == InvoiceStatus.paid ||
          i.status == InvoiceStatus.partiallyPaid) {
        if (i.updatedAt.year == now.year && i.updatedAt.month == now.month) {
          paidThisMonth += i.paidAmount;
        }
      }
    }
    return {
      'outstanding': outstanding,
      'paid_this_month': paidThisMonth,
      'invoice_count': all.length.toDouble(),
    };
  }
}
