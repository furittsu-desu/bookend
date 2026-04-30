class TimeService {
  DateTime now() => DateTime.now();

  DateTime getEffectiveDate({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    if (currentTime.hour < 4) {
      return currentTime.subtract(const Duration(days: 1));
    }
    return currentTime;
  }

  String getEffectiveDateString({DateTime? now}) {
    final date = getEffectiveDate(now: now);
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
