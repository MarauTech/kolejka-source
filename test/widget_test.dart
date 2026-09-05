import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/utils/date_utils.dart' as app_date;
import 'package:trainly/models/models.dart';

void main() {
  group('Date and Time Utils Tests', () {
    test('formatTimeSpan handles standard HH:mm:ss format', () {
      expect(app_date.formatTimeSpan('08:32:00'), '08:32');
      expect(app_date.formatTimeSpan('14:05:30'), '14:05');
      expect(app_date.formatTimeSpan(''), '--:--');
      expect(app_date.formatTimeSpan(null), '--:--');
    });

    test('calculateTravelTime calculates duration between two time spans', () {
      final result = app_date.calculateTravelTime('08:32:00', '11:07:00');
      expect(result, '2 h 35 min');
    });

    test('formatDelay formats on-time and delay minutes', () {
      expect(app_date.formatDelay(0), 'Planowo');
      expect(app_date.formatDelay(12), '+12 min');
      expect(app_date.formatDelay(null), 'Planowo');
    });
  });

  group('Models Tests', () {
    test('Station model fromJson', () {
      final station = Station.fromJson({'id': 33506, 'name': 'Warszawa Centralna'});
      expect(station.id, 33506);
      expect(station.name, 'Warszawa Centralna');
    });

    test('Carrier model fromJson', () {
      final carrier = Carrier.fromJson({'code': 'IC', 'name': 'PKP Intercity S.A.'});
      expect(carrier.code, 'IC');
      expect(carrier.name, 'PKP Intercity S.A.');
    });

    test('OperationStatistics model fromJson', () {
      final stats = OperationStatistics.fromJson({
        'totalTrains': 100,
        'notStarted': 20,
        'inProgress': 50,
        'completed': 25,
        'cancelled': 5,
        'partialCancelled': 2,
      });
      expect(stats.totalTrains, 100);
      expect(stats.inProgress, 50);
      expect(stats.cancelled, 5);
    });
  });
}
