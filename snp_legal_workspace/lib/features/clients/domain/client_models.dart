/// Client domain — invite-only, no public discovery (Bar Council Rule 36).

class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.notes,
    this.caseIds = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final List<String> caseIds;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? notes,
    List<String>? caseIds,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      caseIds: caseIds ?? this.caseIds,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'notes': notes,
        'case_ids': caseIds,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return ClientProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      caseIds: (json['case_ids'] as List? ?? json['caseIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      createdAt:
          parse(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt:
          parse(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class ClientDraft {
  ClientDraft({
    this.name = '',
    this.email,
    this.phone,
    this.address,
    this.notes,
  });

  String name;
  String? email;
  String? phone;
  String? address;
  String? notes;
}

class ConflictMatch {
  const ConflictMatch({
    required this.partyName,
    required this.source,
    this.caseId,
    this.clientId,
    this.role,
  });

  final String partyName;
  final String source;
  final String? caseId;
  final String? clientId;
  final String? role;
}

class ConflictCheckResult {
  const ConflictCheckResult({
    required this.hasConflict,
    this.matches = const [],
  });

  final bool hasConflict;
  final List<ConflictMatch> matches;
}
