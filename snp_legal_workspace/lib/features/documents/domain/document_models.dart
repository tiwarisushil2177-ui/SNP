/// Document domain models — case files, versions, secure share links.

class CaseDocument {
  const CaseDocument({
    required this.id,
    this.caseId,
    required this.filename,
    this.contentType,
    this.sizeBytes = 0,
    this.category,
    this.version = 1,
    this.isOfficialFiled = false,
    this.localPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? caseId;
  final String filename;
  final String? contentType;
  final int sizeBytes;
  final String? category;
  final int version;
  final bool isOfficialFiled;
  final String? localPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  CaseDocument copyWith({
    String? id,
    String? caseId,
    String? filename,
    String? contentType,
    int? sizeBytes,
    String? category,
    int? version,
    bool? isOfficialFiled,
    String? localPath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaseDocument(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      filename: filename ?? this.filename,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      category: category ?? this.category,
      version: version ?? this.version,
      isOfficialFiled: isOfficialFiled ?? this.isOfficialFiled,
      localPath: localPath ?? this.localPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
        'category': category,
        'version': version,
        'is_official_filed': isOfficialFiled,
        'local_path': localPath,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CaseDocument.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return CaseDocument(
      id: json['id'] as String,
      caseId: json['case_id'] as String? ?? json['caseId'] as String?,
      filename: json['filename'] as String? ?? 'document',
      contentType:
          json['content_type'] as String? ?? json['contentType'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ??
          (json['sizeBytes'] as num?)?.toInt() ??
          0,
      category: json['category'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      isOfficialFiled: json['is_official_filed'] as bool? ??
          json['isOfficialFiled'] as bool? ??
          false,
      localPath:
          json['local_path'] as String? ?? json['localPath'] as String?,
      notes: json['notes'] as String?,
      createdAt:
          parse(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt:
          parse(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class DocumentShareLink {
  const DocumentShareLink({
    required this.token,
    required this.documentId,
    required this.expiresAt,
    this.maxDownloads = 5,
    this.downloadsRemaining = 5,
    this.revoked = false,
  });

  final String token;
  final String documentId;
  final DateTime expiresAt;
  final int maxDownloads;
  final int downloadsRemaining;
  final bool revoked;

  bool get isValid =>
      !revoked && downloadsRemaining > 0 && expiresAt.isAfter(DateTime.now());

  Map<String, dynamic> toJson() => {
        'token': token,
        'document_id': documentId,
        'expires_at': expiresAt.toIso8601String(),
        'max_downloads': maxDownloads,
        'downloads_remaining': downloadsRemaining,
        'revoked': revoked,
      };

  factory DocumentShareLink.fromJson(Map<String, dynamic> json) {
    return DocumentShareLink(
      token: json['token'] as String,
      documentId:
          json['document_id'] as String? ?? json['documentId'] as String,
      expiresAt: DateTime.parse(
          (json['expires_at'] ?? json['expiresAt']).toString()),
      maxDownloads: (json['max_downloads'] as num?)?.toInt() ?? 5,
      downloadsRemaining:
          (json['downloads_remaining'] as num?)?.toInt() ?? 5,
      revoked: json['revoked'] as bool? ?? false,
    );
  }
}

const documentCategories = [
  'Petition / Plaint',
  'Written statement',
  'Affidavit',
  'Order / Judgment',
  'Evidence',
  'Application / IA',
  'Vakalatnama',
  'Correspondence',
  'Other',
];
