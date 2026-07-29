import 'dart:convert';

import '../../../core/services/api_client.dart';

/// Client for DPDP-oriented compliance endpoints on the SNP core API.
class ComplianceApi {
  ComplianceApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> exportAll() async {
    final res = await _api.dio.get('/compliance/export');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> consents() async {
    final res = await _api.dio.get('/compliance/consents');
    final data = res.data as Map;
    return List<dynamic>.from(data['consents'] as List? ?? const []);
  }

  Future<List<dynamic>> auditLogs() async {
    final res = await _api.dio.get('/compliance/audit');
    final data = res.data as Map;
    return List<dynamic>.from(data['logs'] as List? ?? const []);
  }

  Future<Map<String, dynamic>> recordConsent({
    required String purpose,
    String version = '1.0',
    bool granted = true,
  }) async {
    final res = await _api.dio.post('/compliance/consent', data: {
      'purpose': purpose,
      'version': version,
      'granted': granted,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> retention() async {
    final res = await _api.dio.get('/compliance/retention');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateRetention(Map<String, dynamic> body) async {
    final res = await _api.dio.put('/compliance/retention', data: body);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> runPurge() async {
    final res = await _api.dio.post('/compliance/retention/purge');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> eraseAccount() async {
    final res = await _api.dio.post(
      '/compliance/erase',
      data: {'confirm': 'ERASE_MY_DATA'},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> breachReport(String summary) async {
    final res = await _api.dio.post(
      '/compliance/breach-report',
      data: {'summary': summary},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  String prettyJson(Map<String, dynamic> map) =>
      const JsonEncoder.withIndent('  ').convert(map);
}
