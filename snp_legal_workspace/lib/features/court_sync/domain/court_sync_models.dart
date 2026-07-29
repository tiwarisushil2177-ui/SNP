/// Domain models for Court Sync (eCourts / NJDG / High Courts).
/// v1: lookup + status refresh; coverage rolls out court-by-court.

enum CourtSource {
  eCourts,
  njdg,
  highCourt,
  unknown,
}

enum SyncStatus {
  idle,
  syncing,
  success,
  discrepancy,
  unsupportedCourt,
  notFound,
  networkError,
}

/// CNR format: 16 alphanumeric characters.
class CnrNumber {
  const CnrNumber(this.value);

  final String value;

  static bool isValidFormat(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    return RegExp(r'^[A-Z0-9]{16}$').hasMatch(cleaned);
  }

  String get normalized =>
      value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  @override
  String toString() => normalized;
}

class CourtHearingInfo {
  const CourtHearingInfo({
    required this.date,
    this.purpose,
    this.courtRoom,
    this.judgeName,
    this.businessDate,
  });

  final DateTime date;
  final String? purpose;
  final String? courtRoom;
  final String? judgeName;
  final DateTime? businessDate;
}

class CourtCaseStatus {
  const CourtCaseStatus({
    required this.cnr,
    required this.source,
    required this.fetchedAt,
    this.caseType,
    this.filingNumber,
    this.registrationNumber,
    this.petitioner,
    this.respondent,
    this.stage,
    this.nextHearing,
    this.courtName,
    this.district,
    this.state,
    this.rawPayload,
  });

  final String cnr;
  final CourtSource source;
  final DateTime fetchedAt;
  final String? caseType;
  final String? filingNumber;
  final String? registrationNumber;
  final String? petitioner;
  final String? respondent;
  final String? stage;
  final CourtHearingInfo? nextHearing;
  final String? courtName;
  final String? district;
  final String? state;
  final Map<String, dynamic>? rawPayload;
}

class SyncDiscrepancy {
  const SyncDiscrepancy({
    required this.field,
    required this.localValue,
    required this.remoteValue,
    required this.detectedAt,
  });

  final String field;
  final String localValue;
  final String remoteValue;
  final DateTime detectedAt;
}

class CourtSyncResult {
  const CourtSyncResult({
    required this.status,
    this.caseStatus,
    this.discrepancies = const [],
    this.message,
  });

  final SyncStatus status;
  final CourtCaseStatus? caseStatus;
  final List<SyncDiscrepancy> discrepancies;
  final String? message;
}

class SupportedCourt {
  const SupportedCourt({
    required this.id,
    required this.name,
    required this.state,
    required this.source,
    this.highCourtCode,
  });

  final String id;
  final String name;
  final String state;
  final CourtSource source;
  final String? highCourtCode;
}
