import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/court_sync_models.dart';
import '../providers/court_sync_provider.dart';

/// CNR lookup + court sync result surface.
/// Suggestions are never auto-applied to case records.
class CnrLookupPage extends ConsumerStatefulWidget {
  const CnrLookupPage({super.key});

  @override
  ConsumerState<CnrLookupPage> createState() => _CnrLookupPageState();
}

class _CnrLookupPageState extends ConsumerState<CnrLookupPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courtSyncProvider);
    final notifier = ref.read(courtSyncProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('CNR Lookup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Look up a case on eCourts / supported High Courts by CNR number.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Results are for your review only. Nothing is written to a case until you confirm.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-\s]')),
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: const InputDecoration(
              labelText: 'CNR Number',
              hintText: 'e.g. DLCT010012342024',
              prefixIcon: Icon(Icons.tag),
            ),
            onChanged: notifier.setCnr,
            onSubmitted: (_) => notifier.lookup(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () => notifier.lookup(),
              child: state.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Look up'),
            ),
          ),
          if (state.result != null) ...[
            const SizedBox(height: 24),
            _ResultCard(result: state.result!),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final CourtSyncResult result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.status) {
      SyncStatus.success => AppColors.success,
      SyncStatus.discrepancy => AppColors.saffron,
      SyncStatus.notFound ||
      SyncStatus.unsupportedCourt ||
      SyncStatus.networkError =>
        AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.status == SyncStatus.success
                    ? Icons.check_circle_outline
                    : result.status == SyncStatus.discrepancy
                        ? Icons.warning_amber_outlined
                        : Icons.info_outline,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message ?? result.status.name,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
          if (result.caseStatus != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _kv('CNR', result.caseStatus!.cnr),
            _kv('Court', result.caseStatus!.courtName ?? '—'),
            _kv('Stage', result.caseStatus!.stage ?? '—'),
            _kv('Petitioner', result.caseStatus!.petitioner ?? '—'),
            _kv('Respondent', result.caseStatus!.respondent ?? '—'),
            if (result.caseStatus!.nextHearing != null)
              _kv(
                'Next hearing',
                '${result.caseStatus!.nextHearing!.date.toLocal().toString().split(' ').first}'
                '${result.caseStatus!.nextHearing!.purpose != null ? ' · ${result.caseStatus!.nextHearing!.purpose}' : ''}',
              ),
          ],
          if (result.discrepancies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Discrepancies (review before applying)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...result.discrepancies.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${d.field}: local "${d.localValue}" → court "${d.remoteValue}"',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
