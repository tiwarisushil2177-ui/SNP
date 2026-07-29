import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../domain/court_sync_models.dart';
import 'sources/ecourts_boundary.dart';

/// Orchestrates CNR lookup, refresh, and discrepancy detection.
/// Discrepancies are flagged for advocate review — never auto-applied.
class CourtSyncService {
  CourtSyncService(ApiClient apiClient) {
    final dio = apiClient.dio;
    _source = RemoteCourtDataSource(
      (path) async {
        final res = await dio.get(path);
        return Map<String, dynamic>.from(res.data as Map);
      },
      (path, body) async {
        final res = await dio.post(path, data: body);
        return Map<String, dynamic>.from(res.data as Map);
      },
    );
  }

  late final CourtDataSource _source;

  Future<CourtSyncResult> lookupByCnr(String rawCnr) async {
    final cleaned = rawCnr.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (!CnrNumber.isValidFormat(cleaned)) {
      return const CourtSyncResult(
        status: SyncStatus.notFound,
        message: 'Invalid CNR format. Expected 16 alphanumeric characters.',
      );
    }

    try {
      final status = await _source.lookupByCnr(cleaned);
      if (status == null) {
        return const CourtSyncResult(
          status: SyncStatus.notFound,
          message: 'No case found for this CNR in supported courts.',
        );
      }
      return CourtSyncResult(
        status: SyncStatus.success,
        caseStatus: status,
      );
    } on DioException catch (e) {
      return _mapNetworkError(e);
    } catch (_) {
      return const CourtSyncResult(
        status: SyncStatus.networkError,
        message: 'Unable to reach court sync service. Try again later.',
      );
    }
  }

  Future<CourtSyncResult> refreshAndCompare({
    required String cnr,
    String? localCaseId,
    DateTime? localNextHearing,
    String? localStage,
  }) async {
    try {
      final remote = await _source.refreshCase(
        cnr: cnr,
        localCaseId: localCaseId,
      );
      if (remote == null) {
        return const CourtSyncResult(
          status: SyncStatus.notFound,
          message:
              'Case not found or court not yet supported for auto-sync.',
        );
      }

      final discrepancies = <SyncDiscrepancy>[];
      final now = DateTime.now();

      if (localNextHearing != null && remote.nextHearing != null) {
        final localDay = DateTime(
          localNextHearing.year,
          localNextHearing.month,
          localNextHearing.day,
        );
        final remoteDay = DateTime(
          remote.nextHearing!.date.year,
          remote.nextHearing!.date.month,
          remote.nextHearing!.date.day,
        );
        if (localDay != remoteDay) {
          discrepancies.add(SyncDiscrepancy(
            field: 'next_hearing_date',
            localValue: _fmt(localDay),
            remoteValue: _fmt(remoteDay),
            detectedAt: now,
          ));
        }
      }

      if (localStage != null &&
          remote.stage != null &&
          localStage.trim().toLowerCase() !=
              remote.stage!.trim().toLowerCase()) {
        discrepancies.add(SyncDiscrepancy(
          field: 'stage',
          localValue: localStage,
          remoteValue: remote.stage!,
          detectedAt: now,
        ));
      }

      if (discrepancies.isNotEmpty) {
        return CourtSyncResult(
          status: SyncStatus.discrepancy,
          caseStatus: remote,
          discrepancies: discrepancies,
          message:
              'Court data differs from your records. Review before applying.',
        );
      }

      return CourtSyncResult(
        status: SyncStatus.success,
        caseStatus: remote,
        message: 'Court records match your workspace.',
      );
    } on DioException catch (e) {
      return _mapNetworkError(e);
    } catch (_) {
      return const CourtSyncResult(
        status: SyncStatus.networkError,
        message: 'Unable to refresh court status. Try again later.',
      );
    }
  }

  Future<List<SupportedCourt>> supportedCourts() async {
    try {
      return await _source.listSupportedCourts();
    } catch (_) {
      return const [];
    }
  }

  CourtSyncResult _mapNetworkError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 404) {
      return const CourtSyncResult(
        status: SyncStatus.notFound,
        message: 'Case not found.',
      );
    }
    if (code == 501 || code == 422) {
      return const CourtSyncResult(
        status: SyncStatus.unsupportedCourt,
        message:
            'This court is not yet onboarded for automatic sync. Enter hearing dates manually.',
      );
    }
    return const CourtSyncResult(
      status: SyncStatus.networkError,
      message: 'Unable to reach court sync service. Try again later.',
    );
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
