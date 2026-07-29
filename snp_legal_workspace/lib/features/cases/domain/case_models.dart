/// Case domain models for SNP Legal Workspace (solo advocate v1).

enum CaseStage {
  filed,
  admitted,
  hearing,
  reserved,
  judgment,
  disposed;

  String get label {
    switch (this) {
      case CaseStage.filed:
        return 'Filed';
      case CaseStage.admitted:
        return 'Admitted';
      case CaseStage.hearing:
        return 'Hearing';
      case CaseStage.reserved:
        return 'Reserved';
      case CaseStage.judgment:
        return 'Judgment';
      case CaseStage.disposed:
        return 'Disposed';
    }
  }

  static CaseStage fromString(String? raw) {
    if (raw == null) return CaseStage.filed;
    final s = raw.trim().toLowerCase();
    for (final v in CaseStage.values) {
      if (v.name == s || v.label.toLowerCase() == s) return v;
    }
    if (s.contains('hearing') || s.contains('argument')) {
      return CaseStage.hearing;
    }
    if (s.contains('dispos') || s.contains('closed')) {
      return CaseStage.disposed;
    }
    if (s.contains('judgment') || s.contains('order')) {
      return CaseStage.judgment;
    }
    if (s.contains('admit')) return CaseStage.admitted;
    if (s.contains('reserv')) return CaseStage.reserved;
    return CaseStage.filed;
  }
}

class CaseParties {
  const CaseParties({
    this.petitioners = const [],
    this.respondents = const [],
  });

  final List<String> petitioners;
  final List<String> respondents;

  String get summary {
    final p = petitioners.isEmpty ? '—' : petitioners.first;
    final r = respondents.isEmpty ? '—' : respondents.first;
    final extraP = petitioners.length > 1 ? ' & Ors.' : '';
    final extraR = respondents.length > 1 ? ' & Ors.' : '';
    return '$p$extraP vs $r$extraR';
  }

  Map<String, dynamic> toJson() => {
        'petitioners': petitioners,
        'respondents': respondents,
      };

  factory CaseParties.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CaseParties();
    return CaseParties(
      petitioners: (json['petitioners'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      respondents: (json['respondents'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class LegalCase {
  const LegalCase({
    required this.id,
    this.cnr,
    this.court,
    this.caseType,
    this.parties = const CaseParties(),
    this.sections = const [],
    this.filingDate,
    this.stage = CaseStage.filed,
    this.nextHearingDate,
    this.nextHearingPurpose,
    this.opposingCounsel,
    this.relatedCaseIds = const [],
    this.notes,
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? cnr;
  final String? court;
  final String? caseType;
  final CaseParties parties;
  final List<String> sections;
  final DateTime? filingDate;
  final CaseStage stage;
  final DateTime? nextHearingDate;
  final String? nextHearingPurpose;
  final String? opposingCounsel;
  final List<String> relatedCaseIds;
  final String? notes;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  LegalCase copyWith({
    String? id,
    String? cnr,
    String? court,
    String? caseType,
    CaseParties? parties,
    List<String>? sections,
    DateTime? filingDate,
    CaseStage? stage,
    DateTime? nextHearingDate,
    String? nextHearingPurpose,
    String? opposingCounsel,
    List<String>? relatedCaseIds,
    String? notes,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearNextHearing = false,
  }) {
    return LegalCase(
      id: id ?? this.id,
      cnr: cnr ?? this.cnr,
      court: court ?? this.court,
      caseType: caseType ?? this.caseType,
      parties: parties ?? this.parties,
      sections: sections ?? this.sections,
      filingDate: filingDate ?? this.filingDate,
      stage: stage ?? this.stage,
      nextHearingDate:
          clearNextHearing ? null : (nextHearingDate ?? this.nextHearingDate),
      nextHearingPurpose: nextHearingPurpose ?? this.nextHearingPurpose,
      opposingCounsel: opposingCounsel ?? this.opposingCounsel,
      relatedCaseIds: relatedCaseIds ?? this.relatedCaseIds,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cnr': cnr,
        'court': court,
        'case_type': caseType,
        'parties': parties.toJson(),
        'sections': sections,
        'filing_date': filingDate?.toIso8601String().split('T').first,
        'stage': stage.name,
        'next_hearing_date':
            nextHearingDate?.toIso8601String().split('T').first,
        'next_hearing_purpose': nextHearingPurpose,
        'opposing_counsel': opposingCounsel,
        'related_case_ids': relatedCaseIds,
        'notes': notes,
        'archived': archived,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory LegalCase.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return LegalCase(
      id: json['id'] as String,
      cnr: json['cnr'] as String?,
      court: json['court'] as String?,
      caseType: json['case_type'] as String? ?? json['caseType'] as String?,
      parties: CaseParties.fromJson(json['parties'] as Map<String, dynamic>?),
      sections: (json['sections'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      filingDate: parseDate(json['filing_date'] ?? json['filingDate']),
      stage: CaseStage.fromString(json['stage'] as String?),
      nextHearingDate:
          parseDate(json['next_hearing_date'] ?? json['nextHearingDate']),
      nextHearingPurpose: json['next_hearing_purpose'] as String? ??
          json['nextHearingPurpose'] as String?,
      opposingCounsel: json['opposing_counsel'] as String? ??
          json['opposingCounsel'] as String?,
      relatedCaseIds: (json['related_case_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      archived: json['archived'] as bool? ?? false,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']) ??
          DateTime.now(),
    );
  }
}

class CaseDraft {
  CaseDraft({
    this.cnr,
    this.court,
    this.caseType,
    this.petitioners = const [],
    this.respondents = const [],
    this.sections = const [],
    this.filingDate,
    this.stage = CaseStage.filed,
    this.nextHearingDate,
    this.nextHearingPurpose,
    this.opposingCounsel,
    this.notes,
  });

  String? cnr;
  String? court;
  String? caseType;
  List<String> petitioners;
  List<String> respondents;
  List<String> sections;
  DateTime? filingDate;
  CaseStage stage;
  DateTime? nextHearingDate;
  String? nextHearingPurpose;
  String? opposingCounsel;
  String? notes;
}
