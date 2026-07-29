import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/case_models.dart';
import '../providers/cases_provider.dart';

class CasesPage extends ConsumerStatefulWidget {
  const CasesPage({super.key});

  @override
  ConsumerState<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends ConsumerState<CasesPage> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(casesListProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search CNR, parties, court…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    ref.read(casesListProvider.notifier).setQuery(v),
              )
            : const Text('Cases'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(casesListProvider.notifier).setQuery('');
                }
              });
            },
          ),
          PopupMenuButton<CaseStage?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (stage) {
              ref.read(casesListProvider.notifier).setStageFilter(stage);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All stages')),
              ...CaseStage.values.map(
                (s) => PopupMenuItem(value: s, child: Text(s.label)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cases/new'),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Case'),
      ),
      body: state.isLoading && state.cases.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.cases.isEmpty
              ? _EmptyState(
                  hasQuery: state.query.isNotEmpty || state.stageFilter != null,
                  onCreate: () => context.push('/cases/new'),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(casesListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: state.cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = state.cases[index];
                      return _CaseCard(
                        legalCase: c,
                        onTap: () => context.push('/cases/${c.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.onCreate});
  final bool hasQuery;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching cases' : 'No cases yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different search or clear filters.'
                  : 'Create your first case to track CNR, hearings,\ndocuments and billing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('New Case'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.legalCase, required this.onTap});
  final LegalCase legalCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      legalCase.parties.summary,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StageChip(stage: legalCase.stage),
                ],
              ),
              const SizedBox(height: 8),
              if (legalCase.cnr != null)
                Text(
                  'CNR  ${legalCase.cnr}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              if (legalCase.court != null) ...[
                const SizedBox(height: 4),
                Text(
                  legalCase.court!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (legalCase.nextHearingDate != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.event, size: 14, color: AppColors.saffron),
                    const SizedBox(width: 6),
                    Text(
                      'Next: ${dateFmt.format(legalCase.nextHearingDate!)}'
                      '${legalCase.nextHearingPurpose != null ? ' · ${legalCase.nextHearingPurpose}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage});
  final CaseStage stage;

  @override
  Widget build(BuildContext context) {
    final color = switch (stage) {
      CaseStage.disposed => AppColors.textMuted,
      CaseStage.judgment => AppColors.success,
      CaseStage.hearing => AppColors.saffron,
      CaseStage.reserved => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stage.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
