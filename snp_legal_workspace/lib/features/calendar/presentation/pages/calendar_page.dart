import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/calendar_models.dart';
import '../providers/calendar_provider.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final focused = state.focusedDay ?? DateTime.now();
    final selected = state.selectedDay ?? focused;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () {
              final today = DateTime.now();
              notifier.selectDay(today);
              notifier.loadMonth(today);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2015, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: focused,
              selectedDayPredicate: (day) => isSameDay(selected, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: notifier.eventsFor,
              onDaySelected: (day, focus) {
                notifier.selectDay(day);
                if (focus.month != focused.month || focus.year != focused.year) {
                  notifier.loadMonth(focus);
                }
              },
              onPageChanged: notifier.onPageChanged,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.saffron.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.deepNavy,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.saffron,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
          ),
          if (state.clashes.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.saffron, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.clashes.length == 1
                          ? state.clashes.first.message
                          : '${state.clashes.length} days this month have multiple hearings.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Cause list · ${dateFmt.format(selected)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (state.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: state.selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      'No hearings on this day.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: state.selectedEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = state.selectedEvents[i];
                      return Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: e.caseId == null
                              ? null
                              : () => context.push('/cases/${e.caseId}'),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.saffron,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.title ?? e.partiesSummary ?? 'Hearing',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (e.purpose != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          e.purpose!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (e.court != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          e.court!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
