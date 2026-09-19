import 'package:intl/intl.dart';

/// Every day in this app is identified by a local-date string: "2026-09-18".
///
/// Using the device's *local* date (not UTC) is deliberate: the user's "today"
/// is whatever the calendar on their wall says, regardless of timezone.
class DayKey {
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  static String of(DateTime date) => _fmt.format(date);

  static DateTime parse(String key) => _fmt.parse(key);

  static String today() => of(DateTime.now());

  static String tomorrow() => of(DateTime.now().add(const Duration(days: 1)));

  static String yesterday() =>
      of(DateTime.now().subtract(const Duration(days: 1)));

  static String addDays(String key, int days) =>
      of(parse(key).add(Duration(days: days)));

  /// Difference in whole days: `b - a`.
  static int daysBetween(String a, String b) =>
      parse(b).difference(parse(a)).inDays;

  static String pretty(String key) =>
      DateFormat('EEEE, d MMMM').format(parse(key));

  static String shortPretty(String key) =>
      DateFormat('d MMM yyyy').format(parse(key));

  /// 1 = Monday ... 7 = Sunday, matching DateTime.weekday.
  static int weekday(String key) => parse(key).weekday;
}
