DateTime startOfWeek(DateTime date) {
  final localDate = DateTime(date.year, date.month, date.day);
  return localDate.subtract(
    Duration(days: localDate.weekday - DateTime.monday),
  );
}

bool isSameCalendarDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String weekKeyFor(DateTime date) {
  final monday = startOfWeek(date);
  return [
    monday.year.toString(),
    monday.month.toString().padLeft(2, '0'),
    monday.day.toString().padLeft(2, '0'),
  ].join('-');
}
