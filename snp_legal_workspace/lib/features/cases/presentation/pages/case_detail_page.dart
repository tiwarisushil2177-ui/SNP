import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../court_sync/domain/court_sync_models.dart';
import '../../../court_sync/presentation/providers/court_sync_provider.dart';
import '../../domain/case_models.dart';
import '../providers/cases_provider.dart';

class CaseDetailPage extends ConsumerStatefulWidget {
  const CaseDetailPage({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends ConsumerState<CaseDetailPage> {
  bool _refreshing = false;
  CourtSyncResult? _syncResult;

  Future<void> _refreshCourt(LegalCase c) async {
    if (c.cnr == null || c.cnr!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CNR on this case to refresh.')),
      );
      return;
    }
    setState(() {
      _refreshing = true;
      _syncResult = null;
    });
    final result = await ref.read(courtSyncServiceProvider).refreshAndCompare(
          cnr: c.cnr!,
          localCaseId: c.id,
          localNextHearing: c.nextHearingDate,
          localStage: c.stage.label,
        );
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _syncResult = result;
    });
  }

  Future<void> _applyRemoteHearing(LegalCase c, CourtCaseStatus remote) async {
    final updated = c.copyWith(
      nextHearingDate: remote.nextHearing?.date,
      nextHearingPurpose: remote.nextHearing?.purpose ?? c.nextHearingPurpose,
      stage: remote.stage != null
          ? CaseStage.fromString(remote.stage)
          : c.stage,
      court: remote.courtName ?? c.court,
    );
    await ref.read(casesListProvider.notifier).update(updated);
    ref.invalidate(caseByIdProvider(widget.caseId));
    if (!mounted) return;
    setState(() => _syncResult = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Court dates applied to this case.')),
    );
  }

  Future<void> _archive(LegalCase c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive case?'),
        content: const Text(
            'Archived cases are hidden from the main list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Archive')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(casesListProvider.notifier).archive(c.id);
    if (!mounted) return;
    context.go('/cases');
  }

  @override
  Widget build(BuildContext context) {
    final asyncCase = ref.watch(caseByIdProvider(widget.caseId));
    final dateFmt = DateFormat('dd MMM yyyy');

    return asyncCase.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Case')),
        body: const Center(child: Text('Could not load case.')),
      ),
      data: (c) {
        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Case')),
            body: const Center(child: Text('Case not found.')),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.ivory,
          appBar: AppBar(
            title: const Text('Case detail'),
            actions: [
              if (c.cnr != null)
                IconButton(
                  tooltip: 'Refresh from court',
                  icon: _refreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  onPressed: _refreshing ? null : () => _refreshCourt(c),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'archive') _archive(c);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'archive', child: Text('Archive')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                c.parties.summary,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(c.stage.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.saffron)),
              if (_syncResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_syncResult!.message ?? _syncResult!.status.name),
                      if (_syncResult!.status == SyncStatus.discrepancy &&
                          _syncResult!.caseStatus != null) ...[
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => _applyRemoteHearing(
                              c, _syncResult!.caseStatus!),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.deepNavy),
                          child: const Text('Apply court dates'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _kv('CNR', c.cnr ?? '—'),
              _kv('Court', c.court ?? '—'),
              _kv(
                  'Filing',
                  c.filingDate != null
                      ? dateFmt.format(c.filingDate!)
                      : '—'),
              _kv(
                  'Next hearing',
                  c.nextHearingDate != null
                      ? '${dateFmt.format(c.nextHearingDate!)}'
                          '${c.nextHearingPurpose != null ? ' · ${c.nextHearingPurpose}' : ''}'
                      : '—'),
              if (c.opposingCounsel != null)
                _kv('Opposing counsel', c.opposingCounsel!),
              if (c.sections.isNotEmpty)
                _kv('Sections', c.sections.join(', ')),
              if (c.notes != null && c.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Notes',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                Text(c.notes!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
