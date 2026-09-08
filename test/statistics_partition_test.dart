import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/models/models.dart';

void main() {
  OperationStatistics stats(List<int> counts, int total) => OperationStatistics(
        notStarted: counts[0],
        inProgress: counts[1],
        completed: counts[2],
        cancelled: counts[3],
        partialCancelled: counts[4],
        totalTrains: total,
        raw: {},
      );
  test(
      'Five PLK statuses account for the real snapshot including partial cancellations',
      () {
    final shares = stats([3461, 765, 3240, 5, 8], 7479).percentages!;
    expect(shares.values.fold(0.0, (a, b) => a + b), closeTo(100, 0.00001));
    expect(shares['partialCancelled'], 0.1);
    expect(shares['inProgress'], 10.2);
  });
  test('Rounding preserves 100 percent for repeating fractions', () {
    final shares = stats([1, 1, 1, 0, 0], 3).percentages!;
    expect(shares['notStarted'], 33.4);
    expect(shares['inProgress'], 33.3);
    expect(shares['completed'], 33.3);
    expect(shares.values.fold(0.0, (a, b) => a + b), closeTo(100, 0.00001));
  });
  test(
      'Missing, overlapping or negative counts do not produce misleading shares',
      () {
    for (final value in [
      stats([1, 1, 1, 1, 1], 6),
      stats([2, 2, 2, 2, 2], 5),
      stats([-1, 2, 0, 0, 0], 1),
      stats([0, 0, 0, 0, 0], 0)
    ]) {
      expect(value.percentages, isNull);
    }
  });
  test('Blank disruption message falls back to its actual type description',
      () {
    final item =
        Disruption.fromJson({'message': '  ', 'disruptionTypeCode': 'utr_1'});
    expect(item.resolveDescription({'utr_1': 'Uszkodzenie sieci trakcyjnej'}),
        'Uszkodzenie sieci trakcyjnej');
    expect(item.resolveDescription({}), isNull);
    expect(
        Disruption.fromJson({'message': 'utr_55'})
            .resolveDescription({'utr_55': 'Ograniczenie prędkości pociągu'}),
        'Ograniczenie prędkości pociągu');
    expect(Disruption.fromJson({'message': 'utr_999'}).resolveDescription({}),
        isNull);
    expect(
        Disruption.fromJson({'message': 'Opóźnienia do 20 min'})
            .resolveDescription({}),
        'Opóźnienia do 20 min');
    expect(
        Disruption.fromJson({'message': 'Brak opisu'}).resolveDescription({}),
        isNull);
  });
}
