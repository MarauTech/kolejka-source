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
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connection-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();
    final timeFields = find.descendant(
        of: find.byType(TimePickerDialog), matching: find.byType(TextField));
    await tester.enterText(timeFields.first, '09');
    await tester.enterText(timeFields.last, '45');
    await tester.tap(find.text('OK'));
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
      expect(find.text('1 przesiadka'), findsNothing);
      expect(find.textContaining('1 przesiadka'), findsOneWidget);
      expect(find.text('Przyj. Per. II/7'), findsOneWidget);
      expect(find.text('Odj. Per. IV/3'), findsOneWidget);
      expect(find.textContaining('Przewidywany: 3 h 5 min'), findsOneWidget);
      expect(tester.widget<Text>(find.text('10:05')).style?.color, Colors.red);
      expect(tester.widget<Text>(find.text('10:00')).style?.decoration,
          TextDecoration.lineThrough);
      expect(find.textContaining('919191'), findsNothing);
      expect(find.byType(Card), findsNothing);
      await tester.tap(find.text('30521'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
