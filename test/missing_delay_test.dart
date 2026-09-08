import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/models/train_position_resolver.dart';
import 'package:trainly/screens/train_details_screen.dart';
import 'package:trainly/widgets/train_card.dart';
import 'fixtures.dart';

void main() {
  test(
      'Completed API status retains the final delay despite device clock differences',
      () {
    final stop = StationOnRoute(
        stationId: 1, orderNumber: 1, arrivalTime: '17:48:00', raw: {});
    final operation = TrainOperation(
        scheduleId: 1,
        orderId: 2,
        trainOrderId: 3,
        operatingDate: '2026-09-06',
        trainStatus: 'C',
        stations: [
          OperationStation(
              stationId: 1,
              actualSequenceNumber: 1,
              actualArrival: '2026-09-06T18:06:00',
              isConfirmed: true,
              isCancelled: false,
              raw: {})
        ],
        raw: {});
    final position = TrainPositionResolver.resolve(
        operation: operation,
        routeStations: [stop],
        stationNames: {1: 'Modlin'},
        now: DateTime(2026, 9, 6, 16, 59));
    expect(position.status, TrainStatusType.completed);
    expect(position.delayMinutes, 18);
  });
  for (final width in [320.0, 360.0, 384.0, 411.0]) {
    testWidgets(
        'Missing API delay fields still give red actual times at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final first = StationOnRoute(
          stationId: 1, orderNumber: 1, departureTime: '10:00:00', raw: {});
      final last = StationOnRoute(
          stationId: 2, orderNumber: 2, arrivalTime: '11:00:00', raw: {});
      final route = TrainRoute(
          scheduleId: 1,
          orderId: 2,
          stations: [first, last],
          nationalNumber: '97133',
          operatingDates: ['2026-09-06'],
          connections: [],
          raw: {});
      final operation = TrainOperation(
          scheduleId: 1,
          orderId: 2,
          trainOrderId: 3,
          operatingDate: '2026-09-06',
          trainStatus: 'P',
          stations: [
            OperationStation(
                stationId: 1,
                plannedSequenceNumber: 1,
                actualSequenceNumber: 1,
                actualDeparture: '2026-09-06T10:18:00',
                isConfirmed: true,
                isCancelled: false,
                raw: {}),
            OperationStation(
                stationId: 2,
                plannedSequenceNumber: 2,
                actualSequenceNumber: 2,
                actualArrival: '2026-09-06T11:18:00',
                isConfirmed: false,
                isCancelled: false,
                raw: {}),
          ],
          raw: {});
      final result = ConnectionResult(
          route: route,
          fromStop: first,
          toStop: last,
          fromStationName: 'Warszawa',
          toStationName: 'Modlin',
          carrierName: 'KM',
          commercialCategory: 'KM',
          operatingDate: '2026-09-06',
          operation: operation);
      expect(result.departureDelay, 18);
      expect(result.arrivalDelay, 18);
      final state = FixtureState()..updatedOperation = operation;
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
              home: TrainDetailsScreen(
                  result: result, now: () => DateTime(2026, 9, 6, 10, 19)))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      for (final value in ['10:18', '11:18']) {
        expect(
            tester.widgetList<Text>(find.text(value)).any((t) =>
                t.style?.color ==
                Theme.of(tester.element(find.text(value).first))
                    .colorScheme
                    .error),
            isTrue);
      }
      expect(find.text('Planowo'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: TrainCard(connection: result, onTap: () {}))));
      await tester.pumpAndSettle();
      for (final value in ['10:18', '11:18']) {
        expect(
            tester.widgetList<Text>(find.text(value)).any((t) =>
                t.style?.color ==
                Theme.of(tester.element(find.text(value).first))
                    .colorScheme
                    .error),
            isTrue);
      }
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Przewidywany czas podróży: 1 h 0 min'),
          findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
