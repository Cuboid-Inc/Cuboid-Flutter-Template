class Period {
  const Period({required this.start, required this.end});

  factory Period.month(int year, int month) => Period(
    start: DateTime(year, month),
    end: DateTime(year, month + 1, 0, 23, 59, 59),
  );

  factory Period.year(int year) =>
      Period(start: DateTime(year), end: DateTime(year + 1, 1, 0, 23, 59, 59));

  factory Period.thisMonth() {
    final now = DateTime.now();
    return Period.month(now.year, now.month);
  }

  factory Period.lastMonth() {
    final now = DateTime.now();
    return Period.month(now.year, now.month - 1);
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && !value.isAfter(end);

  @override
  bool operator ==(Object other) =>
      other is Period && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}
