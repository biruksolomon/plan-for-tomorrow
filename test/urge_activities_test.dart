import 'package:flutter_test/flutter_test.dart';
import 'package:plan_tomorrow/data/repositories/urge_activities_catalog.dart';

void main() {
  group('UrgeActivitiesCatalog Tests', () {
    test('Catalog contains exactly 90 activities', () {
      final activities = UrgeActivitiesCatalog.getAll();
      expect(activities.length, equals(90));
    });

    test('getForDay returns valid activity for Day 1 through Day 90', () {
      for (int i = 1; i <= 90; i++) {
        final activity = UrgeActivitiesCatalog.getForDay(i);
        expect(activity.dayNumber, equals(i));
        expect(activity.title.isNotEmpty, isTrue);
        expect(activity.category.isNotEmpty, isTrue);
        expect(activity.steps.isNotEmpty, isTrue);
        expect(activity.psychologicalBenefit.isNotEmpty, isTrue);
      }
    });

    test('getForDay bounds handling', () {
      final first = UrgeActivitiesCatalog.getForDay(0);
      expect(first.dayNumber, equals(1));

      final last = UrgeActivitiesCatalog.getForDay(150);
      expect(last.dayNumber, equals(90));
    });

    test('getByCategory filters correctly', () {
      for (final cat in UrgeActivitiesCatalog.categories) {
        final list = UrgeActivitiesCatalog.getByCategory(cat);
        expect(list.isNotEmpty, isTrue);
        for (final item in list) {
          expect(item.category, equals(cat));
        }
      }
    });
  });
}
