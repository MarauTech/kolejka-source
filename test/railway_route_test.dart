import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/models/route_presentation.dart';
import 'package:trainly/screens/train_details_screen.dart';
import 'package:trainly/utils/format_utils.dart';
import 'package:trainly/widgets/route_stop.dart';
import 'fixtures.dart';

void main() {
  test('Compact railway platforms preserve Roman notation and Arabic track',
      () {
    expect(formatPlatformTrack('2', '2', compact: true), 'Per. II/2');
    expect(formatPlatformTrack('4', '8', compact: true), 'Per. IV/8');
    expect(formatPlatformTrack('I', '1', compact: true), 'Per. I/1');
    expect(formatPlatformTrack('2', null, compact: true), 'Per. II');
    expect(formatPlatformTrack(null, '3', compact: true), 'Tor 3');
    expect(formatPlatformTrack('-', '-', compact: true), isNull);
  });
  test('Continuation is generated only from a real designation change', () {
    final stop = StationOnRoute(
        stationId: 1,
        orderNumber: 2,
        arrivalTrainNumber: '64225',
        departureTrainNumber: '64227',
        arrivalCommercialCategory: 'R',
        departureCommercialCategory: 'R',
        raw: {});
    expect(routeStopNotice(stop, null, destination: 'Racibórz'),
        'Kursuje z tego miejsca jako R 64227 w kierunku Racibórz');
    expect(
        routeStopNotice(
            StationOnRoute(
                stationId: 1,
                orderNumber: 1,
                departureTrainNumber: '64227',
                raw: {}),
            null),
        isNull);
    expect(
        routeStopNotice(
            StationOnRoute(
                stationId: 1,
                orderNumber: 1,
                arrivalTrainNumber: '64227',
                departureTrainNumber: '64227',
                raw: {}),
            null),
        isNull);
  });
  test('Operations require matching schedule, train and operating date', () {
    final route = TrainRoute(
        scheduleId: 10,
        orderId: 20,
        trainOrderId: 30,
        operatingDates: [],
        stations: [],
        connections: [],
        raw: {});
    TrainOperation op(int sid, int tid, String day) => TrainOperation(
        scheduleId: sid,
        orderId: 20,
        trainOrderId: tid,
        operatingDate: day,
        stations: [],
        raw: {});
    expect(operationMatchesRoute(op(10, 30, '2026-09-06'), route, '2026-09-06'),
        isTrue);
    expect(operationMatchesRoute(op(10, 31, '2026-09-06'), route, '2026-09-06'),
        isFalse);
    expect(operationMatchesRoute(op(11, 30, '2026-09-06'), route, '2026-09-06'),
        isFalse);
    expect(operationMatchesRoute(op(10, 30, '2026-09-07'), route, '2026-09-06'),
        isFalse);
  });

  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 384.0, 411.0]) {
      testWidgets(
          'Route columns, one/two times, notice and missing platform $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const stationName =
            'Bardzo długa nazwa stacji kolejowej wymagająca dwóch linii';
        const notice =
            'Kursuje z tego miejsca jako R 64227 w kierunku Racibórz. Kontynuacja zgodna z rozkładem jazdy pociągu.';
        Future<void> show(
            {bool first = false,
            bool last = false,
            String? arrival = '18:52:00',
            String? departure = '18:53:00',
            String? platform = '2',
            String? track = '2',
            bool live = true}) async {
          await tester.pumpWidget(MaterialApp(
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              home: Scaffold(
                  body: Padding(
                      padding: const EdgeInsets.all(12),
                      child: RouteStopWidget(
                        stationName: stationName,
                        index: 0,
                        isFirst: first,
                        isLast: last,
                        notice: notice,
                        operatingDate: '2026-09-06',
                        scheduleData: StationOnRoute(
                            stationId: 1,
                            orderNumber: 1,
                            arrivalTime: arrival,
                            departureTime: departure,
                            departurePlatform: platform,
                            departureTrack: track,
                            raw: {}),
                        realtimeData: live
                            ? OperationStation(
                                stationId: 1,
                                actualSequenceNumber: 1,
                                arrivalDelayMinutes: 1,
                                departureDelayMinutes: 0,
                                isConfirmed: false,
                                isCancelled: false,
                                raw: {})
                            : null,
                      )))));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(ErrorWidget), findsNothing);
          expect(find.byType(Card), findsNothing);
        }

        await show();
        expect(
            find.byKey(const ValueKey('route-time-0-arrival')), findsOneWidget);
        expect(find.byKey(const ValueKey('route-time-0-departure')),
            findsOneWidget);
        final arrival = tester
            .widget<Text>(find.byKey(const ValueKey('route-time-0-arrival')));
        expect(arrival.data, '18:53');
        expect(arrival.style?.color, Colors.red);
        expect(find.text('+1'), findsOneWidget);
        expect(find.text('+0'), findsOneWidget);
        expect(find.text(notice), findsOneWidget);
        final hour = tester
            .getTopLeft(find.byKey(const ValueKey('route-time-0-arrival')))
            .dx;
        final axis =
            tester.getTopLeft(find.byKey(const ValueKey('route-axis-0'))).dx;
        final station = tester.getTopLeft(find.text(stationName)).dx;
        final platform = tester.getTopLeft(find.text('Per. II / Tor 2')).dx;
        expect(hour, lessThan(axis));
        expect(axis, lessThan(station));
        expect(station, lessThan(platform));
        expect(tester.widget<Text>(find.text(stationName)).maxLines, 2);
        await show(first: true);
        expect(
            find.byKey(const ValueKey('route-time-0-arrival')), findsNothing);
        expect(find.byKey(const ValueKey('route-time-0-departure')),
            findsOneWidget);
        await show(last: true);
        expect(
            find.byKey(const ValueKey('route-time-0-arrival')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('route-time-0-departure')), findsNothing);
        await show(arrival: null, track: null);
        expect(
            find.byKey(const ValueKey('route-time-0-arrival')), findsNothing);
        expect(find.text('Per. II'), findsOneWidget);
        await show(platform: null, track: null, live: false);
        expect(find.textContaining('Per.'), findsNothing);
        expect(find.text('+0'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets(
          'Whole route fetched asynchronously, expanded and collapsed $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = connectionFixture(shortTimes: true);
        final state = FixtureState()..updatedOperation = fixture.operation;
        state.fixtureApi.routeResponse = {
          'scheduleId': 1,
          'orderId': 2,
          'trainOrderId': 3,
          'nationalNumber': '3819',
          'name': 'MEHOFFER',
          'stations': [
            for (var i = 0; i < fixture.route.stations.length; i++)
              {
                'stationId': 1000 + i,
                'orderNumber': i + 1,
                'arrivalTime': fixture.route.stations[i].arrivalTime,
                'departureTime': fixture.route.stations[i].departureTime,
                'departurePlatform': '4',
                'departureTrack': '8',
                if (i == 12) ...{
                  'arrivalTrainNumber': '64225',
                  'departureTrainNumber': '64227',
                  'departureCommercialCategory': 'R'
                },
              }
          ],
        };
        state.stationNames = {
          for (var i = 0; i < 16; i++)
            1000 + i: 'Długa nazwa stacji kolejowej numer $i'
        };
        state.stationNames[1015] = 'Racibórz';
        final result = ConnectionResult(
            route: TrainRoute(
                scheduleId: 1,
                orderId: 2,
                nationalNumber: '3819',
                name: 'MEHOFFER',
                operatingDates: ['2026-09-06'],
                stations: [],
                connections: [],
                raw: {}),
            fromStop: fixture.fromStop,
            toStop: fixture.toStop,
            fromStationName: 'Przemyśl Główny',
            toStationName: 'Racibórz',
            carrierName: 'PKP Intercity',
            commercialCategory: 'IC',
            operatingDate: '2026-09-06');
        await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                home: TrainDetailsScreen(
                    result: result, now: () => DateTime(2026, 9, 6, 10, 21)))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(state.requestedOperationId, 3);
        expect(state.requestedOperationDate, '2026-09-06');
        expect(find.text('MEHOFFER'), findsOneWidget);
        expect(find.byType(Card), findsNothing);
        expect(find.byType(RouteStopWidget), findsNWidgets(6));
        expect(
            find.text(
                'Kursuje z tego miejsca jako R 64227 w kierunku Racibórz'),
            findsOneWidget);
        final expand = find.text('Pokaż poprzednie stacje (10)');
        await tester.ensureVisible(expand);
        await tester.tap(expand);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(RouteStopWidget), findsNWidgets(16));
        final animation =
            tester.widget<AnimatedSize>(find.byType(AnimatedSize));
        expect(animation.duration, const Duration(milliseconds: 200));
        expect(animation.curve, Curves.easeOutCubic);
        final rows = tester
            .widgetList<RouteStopWidget>(find.byType(RouteStopWidget))
            .toList();
        expect(rows.first.startsVisibleRoute, isTrue);
        expect(rows[1].startsVisibleRoute, isFalse);
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -1400));
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, 1400));
        await tester.pump(const Duration(milliseconds: 250));
        final collapse =
            find.byKey(const ValueKey('toggle-previous-stations'));
        await tester.ensureVisible(collapse);
        await tester.tap(collapse);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(RouteStopWidget), findsNWidgets(6));
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      });
    }
  }
}
