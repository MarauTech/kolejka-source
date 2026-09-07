import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/models/station_mapping.dart';
import 'package:trainly/utils/category_utils.dart';
import 'package:trainly/utils/date_utils.dart';
import 'package:trainly/utils/format_utils.dart';
import 'package:trainly/utils/search_utils.dart';
import 'fixtures.dart';

void main() {
  test('Missing delay is derived from full dates across midnight', () {
    expect(
        timeDelay('23:55:00', '2026-09-07T00:13:00', null,
            operatingDate: '2026-09-06'),
        18);
    expect(
        timeDelay('23:55:00', '2026-09-07T00:13:00', 3,
            operatingDate: '2026-09-06'),
        3);
    expect(timeDelay(null, null, null, operatingDate: ''), 0);
  });
  test(
      'Affected station references are deduplicated per train and operating day',
      () {
    final disruption = Disruption.fromJson({
      'affectedRoutes': [
        {
          'scheduleId': 1,
          'orderId': 2,
          'stationId': 10,
          'operatingDate': '2026-09-06'
        },
        {
          'scheduleId': 1,
          'orderId': 2,
          'stationId': 20,
          'operatingDate': '2026-09-06'
        },
        {
          'scheduleId': 1,
          'orderId': 2,
          'stationId': 20,
          'operatingDate': '2026-09-07'
        },
      ]
    });
    expect(disruption.affectedRoutes.length, 2);
  });
  test('Roman platforms and Arabic tracks, missing and unusual values', () {
    const roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    for (var i = 1; i <= 10; i++) {
      expect(formatPlatform('$i'), roman[i - 1]);
    }
    expect(formatPlatformTrack('4', '3'), 'Per. IV / Tor 3');
    expect(formatPlatformTrack(null, '5'), 'Tor 5');
    expect(formatPlatformTrack('2', null), 'Per. II');
    expect(formatPlatformTrack('-', null), isNull);
    expect(formatPlatform('2B'), 'IIB');
    expect(formatPlatform(' iv '), 'IV');
    expect(formatPlatform('0'), '0');
    expect(formatPlatform('4000'), '4000');
  });
  test('Category groups and badge contrast in both themes', () {
    const groups = [
      ['Os', 'R', 'RP', 'PR', 'KW', 'ŁKA'],
      ['IR', 'KM'],
      ['TLK', 'IC', 'EC', 'EN'],
      ['EIC'],
      ['EIP'],
      ['SKM', 'KD', 'KMŁ'],
      ['KŚ']
    ];
    for (final dark in [false, true]) {
      expect(
          groups
              .map((g) => categoryColor(g.first, isDark: dark))
              .toSet()
              .length,
          7);
      for (final group in groups) {
        for (final symbol in group) {
          expect(categoryColor(symbol, isDark: dark),
              categoryColor(group.first, isDark: dark));
          final bg = categoryColor(symbol, isDark: dark).computeLuminance();
          final fg = categoryTextColor(symbol, isDark: dark).computeLuminance();
          expect(
              (bg > fg ? (bg + 0.05) / (fg + 0.05) : (fg + 0.05) / (bg + 0.05)),
              greaterThanOrEqualTo(4.5));
        }
      }
      expect(categoryColor(null, isDark: dark),
          categoryColor('UNKNOWN', isDark: dark));
      expect(categoryColor('EC/IC', isDark: dark),
          categoryColor('EC', isDark: dark));
      expect(categoryColor('IR/R', isDark: dark),
          categoryColor('IR', isDark: dark));
      expect(categoryColor('EC/EIC', isDark: dark),
          categoryColor('EC', isDark: dark));
    }
  });
  test('Station query ignores Polish diacritics and repeated spaces', () {
    expect(normalizeStationQuery('Łódź Fabryczna'), 'lodz fabryczna');
    expect(normalizeStationQuery('  KĘDZIERZYN   KOŹLE '), 'kedzierzyn kozle');
  });
  test('Effective duration follows the delayed times shown to passengers', () {
    expect(
        effectiveTravelTime(
            plannedDeparture: '13:32:00',
            plannedArrival: '16:26:00',
            actualDeparture: '2026-09-07T13:32:00',
            actualArrival: '2026-09-07T16:43:00',
            departureDelay: 0,
            arrivalDelay: 17,
            operatingDate: '2026-09-07'),
        '3 h 11 min');
    expect(
        effectiveTravelTime(
            plannedDeparture: '23:40:00',
            plannedArrival: '00:10:00',
            departureDelay: 0,
            arrivalDelay: 5,
            operatingDate: '2026-09-07',
            arrivalDay: 1),
        '35 min');
  });
  test(
      'Short times never use ISO character offsets; delayed time rolls midnight',
      () {
    expect(formatTimeSafe('10:21:00'), '10:21');
    expect(formatTimeSafe('2026-09-06T10:21:00'), '10:21');
    expect(formatTimeSafe(''), '--:--');
    expect(delayedTime('23:58:00', null, 5), '00:03');
    expect(scheduleDateTime('00:03:00', '2026-09-06', day: 1),
        DateTime(2026, 9, 7, 0, 3));
  });
  test(
      'Repeated station ID uses planned sequence; ambiguous data stays unmatched',
      () {
    final a = StationOnRoute(stationId: 1, orderNumber: 1, raw: {});
    final b = StationOnRoute(stationId: 1, orderNumber: 12, raw: {});
    final op = OperationStation(
        stationId: 1,
        plannedSequenceNumber: 12,
        actualSequenceNumber: 5,
        isConfirmed: true,
        isCancelled: false,
        raw: {});
    expect(operationForStop(a, [a, b], [op]), isNull);
    expect(operationForStop(b, [a, b], [op]), same(op));
    final ambiguous = OperationStation(
        stationId: 1,
        actualSequenceNumber: 12,
        isConfirmed: true,
        isCancelled: false,
        raw: {});
    expect(operationForStop(b, [a, b], [ambiguous]), isNull);
    expect(operationForStop(b, [a, b], [op, op]), isNull);
  });
  test(
      'Affected train lookup uses schedule/order, handles strings and caches route',
      () async {
    final state = FixtureState();
    final ref = {
      'scheduleId': '941965170',
      'orderId': '228097641',
      'trainOrderId': 124427125
    };
    final result = await state.resolveAffectedTrain(ref);
    expect(result['nationalNumber'], '3819');
    expect(result['commercialCategorySymbol'], 'IC');
    expect(result['name'], 'MEHOFFER');
    await state.resolveAffectedTrain(ref);
    expect(state.fixtureApi.routeCalls, 1);
    final missing =
        await state.resolveAffectedTrain({'trainOrderId': 941965170});
    expect(missing['nationalNumber'], isNull);
    state.dispose();
  });
}
