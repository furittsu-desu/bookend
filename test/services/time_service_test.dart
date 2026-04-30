import 'package:flutter_test/flutter_test.dart';
import 'package:bookend/services/time_service.dart';

void main() {
  group('TimeService', () {
    test('getEffectiveDate returns same day before midnight', () {
      final now = DateTime(2026, 4, 29, 22, 0); // 10 PM
      final service = TimeService();
      final effective = service.getEffectiveDate(now: now);
      expect(effective.year, 2026);
      expect(effective.month, 4);
      expect(effective.day, 29);
    });

    test('getEffectiveDate returns same day after midnight but before 4 AM', () {
      final now = DateTime(2026, 4, 30, 2, 0); // 2 AM next day
      final service = TimeService();
      final effective = service.getEffectiveDate(now: now);
      expect(effective.year, 2026);
      expect(effective.month, 4);
      expect(effective.day, 29);
    });

    test('getEffectiveDate returns next day after 4 AM', () {
      final now = DateTime(2026, 4, 30, 4, 1); // 4:01 AM next day
      final service = TimeService();
      final effective = service.getEffectiveDate(now: now);
      expect(effective.year, 2026);
      expect(effective.month, 4);
      expect(effective.day, 30);
    });

    test('getEffectiveDateString formats correctly', () {
      final now = DateTime(2026, 4, 29, 12, 0);
      final service = TimeService();
      final dateStr = service.getEffectiveDateString(now: now);
      expect(dateStr, '2026-04-29');
    });

    test('getEffectiveDate works with default parameter', () {
      final service = TimeService();
      final effective = service.getEffectiveDate();
      final actualNow = DateTime.now();
      // Check if it's either today or yesterday depending on time of day
      if (actualNow.hour < 4) {
        expect(effective.day, actualNow.subtract(const Duration(days: 1)).day);
      } else {
        expect(effective.day, actualNow.day);
      }
    });

    test('now returns current time', () {
      final service = TimeService();
      expect(service.now().year, DateTime.now().year);
    });
  });
}
