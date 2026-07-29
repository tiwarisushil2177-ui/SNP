import '../../cases/domain/case_models.dart';

enum CalendarEventType { hearing, deadline, task }

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.type,
    required this.date,
    this.title,
    this.caseId,
    this.purpose,
    this.court,
    this.partiesSummary,
  });

  final String id;
  final CalendarEventType type;
  final DateTime date;
  final String? title;
  final String? caseId;
  final String? purpose;
  final String? court;
  final String? partiesSummary;

  factory CalendarEvent.fromCase(LegalCase c) {
    return CalendarEvent(
      id: 'hearing-${c.id}',
      type: CalendarEventType.hearing,
      date: c.nextHearingDate!,
      title: c.parties.summary,
      caseId: c.id,
      purpose: c.nextHearingPurpose,
      court: c.court,
      partiesSummary: c.parties.summary,
    );
  }
}

class HearingClash {
  const HearingClash({
    required this.date,
    required this.caseIds,
    required this.message,
  });

  final DateTime date;
  final List<String> caseIds;
  final String message;
}
