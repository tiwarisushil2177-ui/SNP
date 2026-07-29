import 'package:isar/isar.dart';

/// Isar schemas for offline-first SNP Legal Workspace.
/// Run: dart run build_runner build --delete-conflicting-outputs

// part 'isar_collections.g.dart'; // enable after build_runner

@collection
class CaseRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  String? cnr;
  late String title;
  String? courtName;
  String? caseNumber;
  String? stage;
  String? notes;
  bool archived = false;

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? nextHearing;

  List<String> petitioners = [];
  List<String> respondents = [];
}

@collection
class ClientRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;
  String? email;
  String? phone;
  String? address;
  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;

  List<String> caseIds = [];
}

@collection
class DocumentRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  String? caseId;
  late String filename;
  String? contentType;
  int sizeBytes = 0;
  String? category;
  int version = 1;
  bool isOfficialFiled = false;
  String? localPath;
  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class InvoiceRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String invoiceNumber;
  String? clientId;
  String? clientName;
  String? caseId;
  late String linesJson;
  double gstPercent = 18;
  late String status;
  String? notes;
  DateTime? dueDate;
  double paidAmount = 0;
  String? upiReference;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class TimeEntryRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  String? caseId;
  String? clientId;
  late String description;
  int minutes = 0;
  double hourlyRate = 0;
  bool billable = true;
  String? invoiceId;

  late DateTime date;
  late DateTime createdAt;
}

@collection
class CalendarEventRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  String? caseId;
  late String title;
  late DateTime startAt;
  DateTime? endAt;
  String? courtName;
  String? notes;
  bool isHearing = true;
}

/// After build_runner, implement openSnpIsar(directory) with generated schemas.
