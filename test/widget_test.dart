import 'package:flutter_test/flutter_test.dart';
import 'package:tao_app_fixed_clean/services/subscription_service.dart';

void main() {
  group('trialLabelFromIso8601', () {
    test('reads Play billing periods', () {
      expect(trialLabelFromIso8601('P3D'), '3-day');
      expect(trialLabelFromIso8601('P1W'), '1-week');
      expect(trialLabelFromIso8601('P1M'), '1-month');
    });

    test('returns null for an unknown format', () {
      expect(trialLabelFromIso8601('P1M2D'), isNull);
      expect(trialLabelFromIso8601(''), isNull);
    });
  });
}
