import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cases/data/cases_repository.dart';
import '../../../cases/presentation/providers/cases_provider.dart';
import '../../domain/calendar_models.dart';

class CalendarState {
  const CalendarState({
    this.focusedDay,
    this.selectedDay,
    this.events = const {},
    this.selectedEvents = const [],
    this.clashes = const [],
    this.isLoading = false,
  });

  final DateTime? focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<CalendarEvent>> events;
  final List<CalendarEvent> selectedEvents;
  final List<HearingClash> clashes;
  final bool isLoading;

  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    Map<DateTime, List<CalendarEvent>>? events,
    List<CalendarEvent>? selectedEvents,
    List<HearingClash>? clashes,
    bool? isLoading,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      events: events ?? this.events,
      selectedEvents: selectedEvents ?? this.selectedEvents,
      clashes: clashes ?? this.clashes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier(this._repo)
      : super(CalendarState(
          focusedDay: DateTime.now(),
          selectedDay: DateTime.now(),
        )) {
    loadMonth(DateTime.now());
  }

  final CasesRepository _repo;

  Future<void> loadMonth(DateTime focus) async {
    state = state.copyWith(isLoading: true, focusedDay: focus);
    final start = DateTime(focus.year, focus.month, 1);
    final end = DateTime(focus.year, focus.month + 1, 0);
    final cases = await _repo.hearingsBetween(start, end);

    final map = <DateTime, List<CalendarEvent>>{};
    for (final c in cases) {
      if (c.nextHearingDate == null) continue;
      final key = _dayKey(c.nextHearingDate!);
      map.putIfAbsent(key, () => []);
      map[key]!.add(CalendarEvent.fromCase(c));
    }

    final clashes = <HearingClash>[];
    for (final entry in map.entries) {
      if (entry.value.length > 1) {
        clashes.add(HearingClash(
          date: entry.key,
          caseIds: entry.value.map((e) => e.caseId!).toList(),
          message:
              '${entry.value.length} hearings on the same day — check for clashes.',
        ));
      }
    }

    final selected = state.selectedDay ?? focus;
    final selectedEvents = map[_dayKey(selected)] ?? const [];

    state = state.copyWith(
      isLoading: false,
      events: map,
      selectedEvents: selectedEvents,
      clashes: clashes,
    );
  }

  void selectDay(DateTime day) {
    final key = _dayKey(day);
    state = state.copyWith(
      selectedDay: day,
      selectedEvents: state.events[key] ?? const [],
    );
  }

  void onPageChanged(DateTime focus) {
    loadMonth(focus);
  }

  List<CalendarEvent> eventsFor(DateTime day) {
    return state.events[_dayKey(day)] ?? const [];
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  ref.watch(casesListProvider);
  return CalendarNotifier(ref.watch(casesRepositoryProvider));
});
