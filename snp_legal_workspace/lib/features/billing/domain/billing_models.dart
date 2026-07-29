/// Billing domain — fee models, GST invoices, time tracking (solo advocate).

enum FeeModel {
  fixed,
  hourly,
  perHearing,
  retainer;

  String get label {
    switch (this) {
      case FeeModel.fixed:
        return 'Fixed fee';
      case FeeModel.hourly:
        return 'Hourly';
      case FeeModel.perHearing:
        return 'Per hearing';
      case FeeModel.retainer:
        return 'Retainer';
    }
  }
}

enum InvoiceStatus {
  draft,
  sent,
  paid,
  partiallyPaid,
  overdue,
  cancelled;

  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.partiallyPaid:
        return 'Partial';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class InvoiceLineItem {
  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitAmount,
    this.feeModel = FeeModel.fixed,
  });

  final String description;
  final double quantity;
  final double unitAmount;
  final FeeModel feeModel;

  double get amount => quantity * unitAmount;

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_amount': unitAmount,
        'fee_model': feeModel.name,
      };

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitAmount: (json['unit_amount'] as num?)?.toDouble() ??
          (json['unitAmount'] as num?)?.toDouble() ??
          0,
      feeModel: FeeModel.values.firstWhere(
        (e) => e.name == (json['fee_model'] ?? json['feeModel']),
        orElse: () => FeeModel.fixed,
      ),
    );
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.clientId,
    this.clientName,
    this.caseId,
    this.lines = const [],
    this.gstPercent = 18.0,
    this.status = InvoiceStatus.draft,
    this.notes,
    this.dueDate,
    this.paidAmount = 0,
    this.upiReference,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String invoiceNumber;
  final String? clientId;
  final String? clientName;
  final String? caseId;
  final List<InvoiceLineItem> lines;
  final double gstPercent;
  final InvoiceStatus status;
  final String? notes;
  final DateTime? dueDate;
  final double paidAmount;
  final String? upiReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get subtotal =>
      lines.fold(0.0, (sum, line) => sum + line.amount);

  double get gstAmount => subtotal * (gstPercent / 100);

  double get total => subtotal + gstAmount;

  double get balanceDue => (total - paidAmount).clamp(0, double.infinity);

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? clientId,
    String? clientName,
    String? caseId,
    List<InvoiceLineItem>? lines,
    double? gstPercent,
    InvoiceStatus? status,
    String? notes,
    DateTime? dueDate,
    double? paidAmount,
    String? upiReference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      caseId: caseId ?? this.caseId,
      lines: lines ?? this.lines,
      gstPercent: gstPercent ?? this.gstPercent,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      paidAmount: paidAmount ?? this.paidAmount,
      upiReference: upiReference ?? this.upiReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'client_id': clientId,
        'client_name': clientName,
        'case_id': caseId,
        'lines': lines.map((e) => e.toJson()).toList(),
        'gst_percent': gstPercent,
        'status': status.name,
        'notes': notes,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'paid_amount': paidAmount,
        'upi_reference': upiReference,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Invoice.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    final linesRaw = json['lines'] as List? ?? const [];
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ??
          json['invoiceNumber'] as String? ??
          '',
      clientId: json['client_id'] as String? ?? json['clientId'] as String?,
      clientName:
          json['client_name'] as String? ?? json['clientName'] as String?,
      caseId: json['case_id'] as String? ?? json['caseId'] as String?,
      lines: linesRaw
          .map((e) =>
              InvoiceLineItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      gstPercent: (json['gst_percent'] as num?)?.toDouble() ??
          (json['gstPercent'] as num?)?.toDouble() ??
          18,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      notes: json['notes'] as String?,
      dueDate: parse(json['due_date'] ?? json['dueDate']),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ??
          (json['paidAmount'] as num?)?.toDouble() ??
          0,
      upiReference:
          json['upi_reference'] as String? ?? json['upiReference'] as String?,
      createdAt:
          parse(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt:
          parse(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class TimeEntry {
  const TimeEntry({
    required this.id,
    this.caseId,
    this.clientId,
    required this.description,
    required this.minutes,
    this.hourlyRate = 0,
    this.billable = true,
    this.invoiceId,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String? caseId;
  final String? clientId;
  final String description;
  final int minutes;
  final double hourlyRate;
  final bool billable;
  final String? invoiceId;
  final DateTime date;
  final DateTime createdAt;

  double get amount => (minutes / 60.0) * hourlyRate;

  String get durationLabel {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'client_id': clientId,
        'description': description,
        'minutes': minutes,
        'hourly_rate': hourlyRate,
        'billable': billable,
        'invoice_id': invoiceId,
        'date': date.toIso8601String().split('T').first,
        'created_at': createdAt.toIso8601String(),
      };

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return TimeEntry(
      id: json['id'] as String,
      caseId: json['case_id'] as String? ?? json['caseId'] as String?,
      clientId: json['client_id'] as String? ?? json['clientId'] as String?,
      description: json['description'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ??
          (json['hourlyRate'] as num?)?.toDouble() ??
          0,
      billable: json['billable'] as bool? ?? true,
      invoiceId:
          json['invoice_id'] as String? ?? json['invoiceId'] as String?,
      date: parse(json['date']) ?? DateTime.now(),
      createdAt:
          parse(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
    );
  }
}

class InvoiceDraft {
  InvoiceDraft({
    this.clientId,
    this.clientName,
    this.caseId,
    this.lines = const [],
    this.gstPercent = 18,
    this.notes,
    this.dueDate,
  });

  String? clientId;
  String? clientName;
  String? caseId;
  List<InvoiceLineItem> lines;
  double gstPercent;
  String? notes;
  DateTime? dueDate;
}
