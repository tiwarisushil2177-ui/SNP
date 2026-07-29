import '../../domain/court_sync_models.dart';

/// Integration boundary for eCourts / NJDG / High Court portals.
///
/// The mobile client NEVER scrapes court sites directly.
/// All traffic goes through the SNP backend gateway.
///
/// Backend endpoints:
///   GET  /court-sync/cnr/{cnr}
///   POST /court-sync/refresh
///   GET  /court-sync/supported-courts
abstract class CourtDataSource {
  Future<CourtCaseStatus?> lookupByCnr(String cnr);

  Future<CourtCaseStatus?> refreshCase({
    required String cnr,
    String? localCaseId,
  });

  Future<List<SupportedCourt>> listSupportedCourts();
}

class RemoteCourtDataSource implements CourtDataSource {
  RemoteCourtDataSource(this._dioGet, this._dioPost);

  final Future<Map<String, dynamic>> Function(String path) _dioGet;
  final Future<Map<String, dynamic>> Function(
    String path,
    Map<String, dynamic> body,
  ) _dioPost;

  @override
  Future<CourtCaseStatus?> lookupByCnr(String cnr) async {
    final data = await _dioGet('/court-sync/cnr/${Uri.encodeComponent(cnr)}');
    if (data['found'] != true) return null;
    return _parseStatus(data);
  }

  @override
  Future<CourtCaseStatus?> refreshCase({
    required String cnr,
    String? localCaseId,
  }) async {
    final data = await _dioPost('/court-sync/refresh', {
      'cnr': cnr,
      if (localCaseId != null) 'case_id': localCaseId,
    });
    if (data['found'] != true) return null;
    return _parseStatus(data);
  }

  @override
  Future<List<SupportedCourt>> listSupportedCourts() async {
    final data = await _dioGet('/court-sync/supported-courts');
    final list = data['courts'] as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return SupportedCourt(
        id: m['id'] as String,
        name: m['name'] as String,
        state: m['state'] as String,
        source: _sourceFrom(m['source'] as String?),
        highCourtCode: m['high_court_code'] as String?,
      );
    }).toList();
  }

  CourtSource _sourceFrom(String? s) {
    switch (s?.toLowerCase()) {
      case 'ecourts':
        return CourtSource.eCourts;
      case 'njdg':
        return CourtSource.njdg;
      case 'high_court':
      case 'highcourt':
        return CourtSource.highCourt;
      default:
        return CourtSource.unknown;
    }
  }

  CourtCaseStatus _parseStatus(Map<String, dynamic> data) {
    final hearing = data['next_hearing'] as Map<String, dynamic>?;
    return CourtCaseStatus(
      cnr: data['cnr'] as String,
      source: _sourceFrom(data['source'] as String?),
      fetchedAt: DateTime.parse(data['fetched_at'] as String),
      caseType: data['case_type'] as String?,
      filingNumber: data['filing_number'] as String?,
      registrationNumber: data['registration_number'] as String?,
      petitioner: data['petitioner'] as String?,
      respondent: data['respondent'] as String?,
      stage: data['stage'] as String?,
      courtName: data['court_name'] as String?,
      district: data['district'] as String?,
      state: data['state'] as String?,
      nextHearing: hearing == null
          ? null
          : CourtHearingInfo(
              date: DateTime.parse(hearing['date'] as String),
              purpose: hearing['purpose'] as String?,
              courtRoom: hearing['court_room'] as String?,
              judgeName: hearing['judge_name'] as String?,
              businessDate: hearing['business_date'] != null
                  ? DateTime.parse(hearing['business_date'] as String)
                  : null,
            ),
      rawPayload: data,
    );
  }
}
