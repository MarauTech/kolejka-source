import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/services/cache_service.dart';
import 'package:trainly/screens/search_screen.dart';
import 'package:trainly/widgets/train_card.dart';
import 'fixtures.dart';

void main() {
  testWidgets('Overnight arrival uses the route day for status and duration',
      (tester) async {
    const date = '2026-09-07';
    final from = StationOnRoute(
        stationId: 67009, orderNumber: 71, departureTime: '23:38:00', raw: {});
    final to = StationOnRoute(
        stationId: 60608,
        orderNumber: 81,
        arrivalTime: '00:01:00',
        arrivalDay: 1,
        raw: {});
    final result = ConnectionResult(
        route: TrainRoute(
            scheduleId: 1,
            orderId: 2,
            nationalNumber: '37010',
            name: 'URSA',
            commercialCategorySymbol: 'EC/IC',
            operatingDates: [date],
            stations: [from, to],
            connections: [],
            raw: {}),
        fromStop: from,
        toStop: to,
        fromStationName: 'Kędzierzyn-Koźle',
        toStationName: 'Opole Główne',
        carrierName: '',
        commercialCategory: 'EC/IC',
        operatingDate: date,
        operation: TrainOperation(
            scheduleId: 1,
            orderId: 2,
            trainOrderId: 3,
            operatingDate: date,
            stations: [
              OperationStation(
                  stationId: from.stationId,
                  plannedSequenceNumber: 71,
                  actualSequenceNumber: 71,
                  plannedDeparture: '${date}T23:38:00',
                  actualDeparture: '${date}T23:38:00',
                  isConfirmed: false,
                  isCancelled: false,
                  raw: {}),
              OperationStation(
                  stationId: to.stationId,
                  plannedSequenceNumber: 81,
                  actualSequenceNumber: 81,
                  plannedArrival: '${date}T00:01:00',
                  actualArrival: '2026-09-08T00:01:00',
                  isConfirmed: false,
                  isCancelled: false,
                  raw: {}),
            ],
            raw: {}));
    expect(result.arrivalDelay, 0);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TrainCard(connection: result, onTap: () {}))));
    expect(find.text('23:38'), findsOneWidget);
    expect(find.text('00:01'), findsOneWidget);
    expect(find.text('23 min'), findsOneWidget);
    expect(find.text('Planowo'), findsOneWidget);
    expect(find.text('+1440 min'), findsNothing);
    expect(tester.widget<Text>(find.text('00:01')).style?.color,
        isNot(ThemeData.light().colorScheme.error));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Select stations, edit date/time, save and remove favorites persistently',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = FixtureState();
    state.cache = CacheService();
    await state.cache.init();
    state.stations = [
      Station(id: 1, name: 'Opole Główne'),
      Station(id: 2, name: 'Gliwice')
    ];
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: SearchScreen())));
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'Opole');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opole Główne').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.last, 'Gliw');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gliwice').last);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connection-date')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final selected = DateTime(now.year, now.month + 1, 15);
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(selected);
    await tester.tap(find.text('Gotowe'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connection-time')));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(
            DateTime(selected.year, selected.month, selected.day, 9, 45));
    await tester.tap(find.text('Gotowe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wyszukaj połączenia'));
    await tester.pumpAndSettle();
    expect(state.searchedDate?.day, 15);
    expect(state.searchedTime?.minute, 45);
    await tester.tap(find.byTooltip('Dodaj trasę do ulubionych'));
    await tester.pumpAndSettle();
    expect(state.favoriteRoutes.length, 1);
    expect(state.cache.loadFavoriteRoutes().length, 1);
    final saved =
        FavoriteRoute.fromJson(state.cache.loadFavoriteRoutes().single);
    expect(saved.fromStationId, 1);
    expect(saved.toStationId, 2);
    expect(saved.fromStationName, 'Opole Główne');
    expect(find.text('Ulubione trasy'), findsNothing);
    await tester.tap(find.byTooltip('Usuń trasę z ulubionych'));
    await tester.pumpAndSettle();
    expect(state.favoriteRoutes, isEmpty);
    expect(state.cache.loadFavoriteRoutes(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  for (final width in [320.0, 360.0, 384.0, 411.0]) {
    testWidgets(
        'Transfer result shows both trains, endpoint platforms and red times $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = connectionFixture();
      final last = StationOnRoute(
          stationId: 900,
          orderNumber: 2,
          arrivalTime: '2026-09-06T13:10:30',
          arrivalPlatform: '2',
          arrivalTrack: '7',
          raw: {});
      final route = TrainRoute(
          scheduleId: 919191,
          orderId: 818181,
          nationalNumber: '30521',
          commercialCategorySymbol: 'R',
          stations: [base.fromStop, last],
          operatingDates: ['2026-09-06'],
          connections: [],
          raw: {});
      final second = ConnectionResult(
          route: route,
          fromStop: base.fromStop,
          toStop: last,
          fromStationName: 'Katowice',
          toStationName: 'Kraków Główny',
          carrierName: '',
          commercialCategory: 'R');
      final operation = TrainOperation(
          scheduleId: 1,
          orderId: 2,
          trainOrderId: 3,
          operatingDate: '2026-09-06',
          trainStatus: 'P',
          stations: [
            OperationStation(
                stationId: base.fromStop.stationId,
                plannedSequenceNumber: base.fromStop.orderNumber,
                departureDelayMinutes: 5,
                actualSequenceNumber: 1,
                isConfirmed: false,
                isCancelled: false,
                raw: {})
          ],
          raw: {});
      final c = ConnectionResult(
          route: base.route,
          fromStop: base.fromStop,
          toStop: base.toStop,
          fromStationName: base.fromStationName,
          toStationName: base.toStationName,
          carrierName: '',
          commercialCategory: 'IC',
          secondLeg: second,
          isDirect: false,
          transfersCount: 1,
          operation: operation,
          operatingDate: '2026-09-06');
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: TrainCard(connection: c, onTap: () => tapped = true))));
      expect(find.text('30521'), findsOneWidget);
      expect(find.text('1 przesiadka'), findsOneWidget);
      expect(find.text('Przyj. Per. II/7'), findsOneWidget);
      expect(find.text('Odj. Per. IV/3'), findsOneWidget);
      expect(find.text('3 h 5 min'), findsOneWidget);
      expect(find.byTooltip('Przewidywany czas podróży: 3 h 5 min'),
          findsOneWidget);
      expect(tester.widget<Text>(find.text('10:05')).style?.color,
          ThemeData.light().colorScheme.error);
      expect(tester.widget<Text>(find.text('10:00')).style?.decoration,
          TextDecoration.lineThrough);
      final departure = tester.getTopLeft(find.text('10:05'));
      final arrival = tester.getTopLeft(find.text('13:10'));
      expect(arrival.dy, departure.dy);
      expect(arrival.dx, greaterThan(departure.dx));
      expect(find.textContaining('919191'), findsNothing);
      expect(find.byType(Card), findsNothing);
      await tester.tap(find.text('30521'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  for (final dark in [false, true]) {
    testWidgets(
        'Connection summary and times fit 320dp with larger text, dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = FixtureState();
      final from = Station(id: 1, name: 'Gorzów Wielkopolski Wschodni');
      final to = Station(id: 2, name: 'Warszawa Aleje Jerozolimskie');
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.6)),
                  child: child!),
              home: SearchScreen(
                  initialFromStation: from,
                  initialToStation: to,
                  searchOnStart: true))));
      await tester.pumpAndSettle();
      expect(find.text(from.name), findsOneWidget);
      expect(find.text(to.name), findsOneWidget);
      expect(find.text('Zmień'), findsOneWidget);
      expect(find.textContaining('Od '), findsOneWidget);
      final earlier = find.byKey(const ValueKey('earlier-connections'));
      if (earlier.evaluate().isNotEmpty) {
        await tester.ensureVisible(earlier);
        await tester.tap(earlier);
        await tester.pumpAndSettle();
      }
      final departure = tester.getTopLeft(find.text('10:00'));
      final arrival = tester.getTopLeft(find.text('10:30'));
      expect(arrival.dy, departure.dy);
      expect(arrival.dx, greaterThan(departure.dx));
      expect(find.text('29 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Zmień'));
      await tester.tap(find.text('Zmień'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('origin-field')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
