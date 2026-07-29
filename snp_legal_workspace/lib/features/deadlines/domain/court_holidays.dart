class CourtHoliday {
  const CourtHoliday({required this.date, required this.name});
  final DateTime date;
  final String name;
}

List<CourtHoliday> indiaCourtHolidaysFor(int year) {
  return [
    CourtHoliday(date: DateTime(year, 1, 26), name: 'Republic Day'),
    CourtHoliday(date: DateTime(year, 8, 15), name: 'Independence Day'),
    CourtHoliday(date: DateTime(year, 10, 2), name: 'Gandhi Jayanti'),
    CourtHoliday(date: DateTime(year, 12, 25), name: 'Christmas'),
  ];
}

bool isCourtHoliday(DateTime day, {int? year}) {
  final d = DateTime(day.year, day.month, day.day);
  return indiaCourtHolidaysFor(year ?? day.year).any((h) =>
      h.date.year == d.year && h.date.month == d.month && h.date.day == d.day);
}

DateTime nextWorkingDay(DateTime from) {
  var d = DateTime(from.year, from.month, from.day).add(const Duration(days: 1));
  while (d.weekday == DateTime.sunday || isCourtHoliday(d)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

class PredictedDeadline {
  const PredictedDeadline({
    required this.title,
    required this.dueOn,
    required this.basis,
  });
  final String title;
  final DateTime dueOn;
  final String basis;
}

List<PredictedDeadline> predictDeadlines({
  required DateTime orderDate,
  String? stage,
}) {
  final list = <PredictedDeadline>[
    PredictedDeadline(
      title: 'Review / obtain certified copy (typical)',
      dueOn: nextWorkingDay(orderDate.add(const Duration(days: 6))),
      basis: 'Operational buffer after order date',
    ),
    PredictedDeadline(
      title: 'Limitation watch (approx. 30 days from order)',
      dueOn: nextWorkingDay(orderDate.add(const Duration(days: 29))),
      basis: 'Common outer reminder — confirm applicable limitation',
    ),
  ];
  if ((stage ?? '').toLowerCase().contains('evidence')) {
    list.add(PredictedDeadline(
      title: 'Evidence list / affidavit check',
      dueOn: nextWorkingDay(orderDate.add(const Duration(days: 13))),
      basis: 'Stage-based practice reminder',
    ));
  }
  return list;
}

String toIcsEvent({
  required String title,
  required DateTime day,
  String description = '',
}) {
  final d =
      '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
  return '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//SNP Legal Workspace//EN
BEGIN:VEVENT
DTSTART;VALUE=DATE:$d
SUMMARY:$title
DESCRIPTION:$description
END:VEVENT
END:VCALENDAR
'''.trim();
}
