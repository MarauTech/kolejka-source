import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/widgets/connection_results.dart';
import 'package:trainly/widgets/train_card.dart';
import 'package:trainly/widgets/train_type_icon.dart';

ConnectionResult journey(int hour, {String category = 'IC'}) {
  final start = StationOnRoute(
      stationId: 1,
      orderNumber: 1,
      departureTime: '${hour.toString().padLeft(2, '0')}:00',
      raw: {});
  final end = StationOnRoute(
      stationId: 2,
      orderNumber: 2,
      arrivalTime: '${(hour + 1).toString().padLeft(2, '0')}:00',
      raw: {});
  return ConnectionResult(
    route: TrainRoute(
        scheduleId: hour,
        orderId: hour,
        nationalNumber: '10$hour',
        commercialCategorySymbol: category,
        operatingDates: ['2026-09-07'],
        stations: [start, end],
        connections: [],
        raw: {}),
    fromStop: start,
    toStop: end,
    fromStationName: 'Warszawa Centralna',
    toStationName: 'Kraków Główny',
    carrierName: '',
    commercialCategory: category,
    operatingDate: '2026-09-07',
  );
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('Earlier journeys remain above later pages, dark=$dark',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
            body: SingleChildScrollView(
                child: ConnectionResults(
          results: [
            for (final hour in [19, 8, 12, 17, 9, 15, 10, 18, 11, 16, 13, 14])
              journey(hour)
          ],
          selectedDeparture: DateTime(2026, 9, 7, 10),
        ))),
      ));
      List<int> displayed() => tester
          .widgetList<TrainCard>(find.byType(TrainCard))
          .map((widget) => widget.connection.route.scheduleId)
          .toList();
      expect(displayed(), [10, 11, 12, 13, 14, 15, 16, 17]);
      await tester.tap(find.byKey(const ValueKey('earlier-connections')));
      await tester.pumpAndSettle();
      expect(displayed(), [8, 9, 10, 11, 12, 13, 14, 15, 16, 17]);
      final rows = find.byType(TrainCard);
      expect(tester.getTopLeft(rows.at(0)).dy,
          lessThan(tester.getTopLeft(rows.at(2)).dy));
      await tester
          .ensureVisible(find.byKey(const ValueKey('later-connections')));
      await tester.tap(find.byKey(const ValueKey('later-connections')));
      await tester.pumpAndSettle();
      expect(displayed(), [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);
      expect(find.byKey(const ValueKey('later-connections')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Regional and express services render the matching artwork',
      (tester) async {
    for (final category in ['R', 'REGIO', 'RP', 'IC', 'EIC', 'EIP', 'EC/IC']) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: TrainCard(
        connection: journey(10, category: category),
        onTap: () {},
      ))));
      final icon = tester.widget<TrainTypeIcon>(find.byType(TrainTypeIcon));
      expect(icon.category, category);
      expect(usesExpressTrainIcon(icon.category),
          !['R', 'REGIO', 'RP'].contains(category));
      expect(tester.takeException(), isNull);
    }
  });
}
