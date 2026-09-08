import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/api/plk_api.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/search_screen.dart';
import 'package:trainly/utils/date_utils.dart' as dates;
import 'package:trainly/widgets/connection_results.dart';
import 'package:trainly/widgets/train_card.dart';
import 'api_resilience_test.dart';
import 'fixtures.dart';

ConnectionResult datedJourney(DateTime date, int number, int hour) {
  final from = StationOnRoute(
      stationId: 1,
      orderNumber: 1,
      departureTime: '${hour.toString().padLeft(2, '0')}:10:00',
      raw: {});
  final to = StationOnRoute(
      stationId: 2,
      orderNumber: 2,
      arrivalTime: '${hour.toString().padLeft(2, '0')}:50:00',
      raw: {});
  return ConnectionResult(
      route: TrainRoute(
          scheduleId: number,
          orderId: number,
          nationalNumber: '$number',
          commercialCategorySymbol: 'R',
          operatingDates: [dates.formatDateForApi(date)],
          stations: [from, to],
          connections: [],
          raw: {}),
      fromStop: from,
      toStop: to,
      fromStationName: 'Kędzierzyn-Koźle',
      toStationName: 'Opole Główne',
      carrierName: '',
      commercialCategory: 'R',
      operatingDate: dates.formatDateForApi(date));
}

class PagingFixture extends FixtureState {
  final datesRequested = <DateTime>[];
  final timesRequested = <TimeOfDay>[];
  Completer<List<ConnectionResult>>? pending;
  @override
  Future<List<ConnectionResult>> searchConnections(
      {required Station fromStation,
      required Station toStation,
      required DateTime date,
      required TimeOfDay time}) async {
    datesRequested.add(date);
    timesRequested.add(time);
    return pending == null
        ? [datedJourney(date, 100, 5), datedJourney(date, 101, 23)]
        : await pending!.future;
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'Next days append, deduplicate, page and continue past an empty day; dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = PagingFixture();
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              home: SearchScreen(
                  initialFromStation: Station(id: 1, name: 'Kędzierzyn-Koźle'),
                  initialToStation: Station(id: 2, name: 'Opole Główne'),
                  searchOnStart: true))));
      await tester.pumpAndSettle();
      final favorite = find.byKey(const ValueKey('favorite-current-route'));
      expect(favorite, findsOneWidget);
      expect(find.ancestor(of: favorite, matching: find.byType(AppBar)),
          findsNothing);
      final earlier = find.byKey(const ValueKey('earlier-connections'));
      if (earlier.evaluate().isNotEmpty) {
        await tester.tap(earlier);
        await tester.pumpAndSettle();
      }
      final nextButton = find.byKey(const ValueKey('next-day-connections'));
      state.pending = Completer<List<ConnectionResult>>();
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.tap(nextButton);
      await tester.pump();
      expect(state.datesRequested.length, 2);
      expect(find.text('Wczytywanie kolejnego dnia…'), findsOneWidget);
      final tomorrow = DateUtils.addDaysToDate(state.datesRequested.first, 1);
      expect(state.datesRequested.last, tomorrow);
      expect(state.timesRequested.last, const TimeOfDay(hour: 0, minute: 0));
      final next = [
        for (var i = 0; i < 13; i++) datedJourney(tomorrow, 200 + i, i)
      ];
      state.pending!.complete([
        ...next,
        next.first,
        datedJourney(state.datesRequested.first, 100, 5)
      ]);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ConnectionResults>(find.byType(ConnectionResults))
              .results
              .length,
          15);
      expect(find.text('Kolejny dzień · ${dates.formatDateDisplay(tomorrow)}'),
          findsOneWidget);
      final dayLabel =
          find.text('Kolejny dzień · ${dates.formatDateDisplay(tomorrow)}');
      final daySeparator = find.byKey(
          ValueKey('connection-day-${dates.formatDateForApi(tomorrow)}'));
      expect(tester.getCenter(dayLabel).dx,
          closeTo(tester.getCenter(daySeparator).dx, 0.5));
      expect(find.byType(TrainCard), findsNWidgets(10));
      final later = find.byKey(const ValueKey('later-connections'));
      await tester.ensureVisible(later);
      await tester.tap(later);
      await tester.pumpAndSettle();
      expect(find.byType(TrainCard), findsNWidgets(15));
      state.pending = Completer<List<ConnectionResult>>();
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pump();
      state.pending!.complete([]);
      await tester.pumpAndSettle();
      expect(find.textContaining('Brak nowych połączeń na'), findsOneWidget);
      state.pending = Completer<List<ConnectionResult>>();
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pump();
      expect(state.datesRequested.last, DateUtils.addDaysToDate(tomorrow, 2));
      state.pending!
          .complete([datedJourney(state.datesRequested.last, 300, 8)]);
      await tester.pumpAndSettle();
      expect(find.text('300'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Zmień'));
      await tester.tap(find.text('Zmień'));
      await tester.pumpAndSettle();
      expect(find.ancestor(of: favorite, matching: find.byType(AppBar)),
          findsNothing);
      expect(favorite, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets(
      'Failed next day retries the same date; changing route discards the reply',
      (tester) async {
    final state = PagingFixture();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
            home: SearchScreen(
                initialFromStation: Station(id: 1, name: 'Opole'),
                initialToStation: Station(id: 2, name: 'Gliwice'),
                searchOnStart: true))));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('next-day-connections'));
    state.pending = Completer<List<ConnectionResult>>();
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    state.pending!.completeError(StateError('secret_payload'));
    await tester.pumpAndSettle();
    expect(find.text('Spróbuj ponownie'), findsOneWidget);
    expect(
        tester
            .widget<ConnectionResults>(find.byType(ConnectionResults))
            .results
            .length,
        2);
    state.pending = Completer<List<ConnectionResult>>();
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(state.datesRequested.last, state.datesRequested[1]);
    await tester.ensureVisible(find.text('Zmień'));
    await tester.tap(find.text('Zmień'));
    await tester.pump();
    await tester.tap(find.byTooltip('Zamień stacje'));
    await tester.pump();
    state.pending!.complete([datedJourney(state.datesRequested.last, 900, 8)]);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionResults), findsNothing);
    expect(find.textContaining('secret_payload'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  test('Operations are joined by operating day, even when train IDs repeat',
      () async {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = DateUtils.addDaysToDate(today, 1);
    final adapter = ResponseAdapter((request) async {
      if (request.path.endsWith('/operations')) {
        return jsonResponse({
          'trains': [
            for (final date in [today, DateUtils.addDaysToDate(today, -1)])
              {
                'scheduleId': 1,
                'orderId': 2,
                'operatingDate': dates.formatDateForApi(date),
                'stations': [
                  {
                    'stationId': 1,
                    'plannedSequenceNumber': 1,
                    'actualDeparture':
                        '${dates.formatDateForApi(date)}T08:15:00'
                  }
                ]
              }
          ]
        });
      }
      return jsonResponse({
        'routes': [
          {
            'scheduleId': 1,
            'orderId': 2,
            'nationalNumber': '123',
            'operatingDates': [request.queryParameters['dateFrom']],
            'stations': [
              {'stationId': 1, 'orderNumber': 1, 'departureTime': '08:00:00'},
              {'stationId': 2, 'orderNumber': 2, 'arrivalTime': '09:00:00'}
            ]
          }
        ]
      });
    });
    final state = AppState()..api = PlkApi(clientFor(adapter));
    Future<List<ConnectionResult>> search(DateTime date) =>
        state.searchConnections(
            fromStation: Station(id: 1, name: 'A'),
            toStation: Station(id: 2, name: 'B'),
            date: date,
            time: const TimeOfDay(hour: 0, minute: 0));
    final current = (await search(today)).single;
    expect(current.departureDelay, 15);
    final next = (await search(tomorrow)).single;
    expect(next.operation, isNull);
    expect(
        adapter.calls, 3); // Two schedules; only today's live feed is needed.
    expect(next.effectiveDeparture(),
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8));
    state.dispose();
  });

  test(
      'Station board fetches tomorrow despite a live overnight row and continues through empty days',
      () async {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = DateUtils.addDaysToDate(today, 1);
    final requested = <String>[];
    final adapter = ResponseAdapter((request) async {
      requested.add(request.queryParameters['dateFrom'] as String);
      return jsonResponse({'routes': []});
    });
    final state = AppState()
      ..api = PlkApi(clientFor(adapter))
      ..currentStation = Station(id: 1, name: 'Opole')
      ..stationDepartures = [
        StationBoardItem(
            time: '00:01',
            trainNumber: '123',
            trainCategory: 'IC',
            carrier: '',
            direction: 'Gliwice',
            scheduleId: 1,
            orderId: 2,
            operatingDate: dates.formatDateForApi(today),
            actualTime: '${dates.formatDateForApi(tomorrow)}T00:01:00',
            raw: {})
      ];
    await state.loadNextStationBoardDay();
    await state.loadNextStationBoardDay();
    expect(requested, [
      dates.formatDateForApi(tomorrow),
      dates.formatDateForApi(DateUtils.addDaysToDate(tomorrow, 1))
    ]);
    expect(state.stationDepartures.length, 1);
    expect(state.stationBoardCanLoadMore, isTrue);
    state.dispose();
  });
}
