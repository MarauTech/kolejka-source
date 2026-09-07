import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/data_source_screen.dart';
import 'package:trainly/screens/disruptions_screen.dart';
import 'package:trainly/screens/results_screen.dart';
import 'package:trainly/screens/search_screen.dart';
import 'package:trainly/screens/station_screen.dart';
import 'package:trainly/screens/statistics_screen.dart';
import 'package:trainly/utils/date_utils.dart';
import 'package:trainly/widgets/train_card.dart';
import 'fixtures.dart';

void main() {
  for (final width in [320.0, 360.0, 384.0, 411.0]) {
    testWidgets('Passenger screens and favorites at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = FixtureState();
      state.favoriteRoutes = [
        FavoriteRoute(
            fromStationId: 1,
            fromStationName: 'Warszawa Centralna',
            toStationId: 2,
            toStationName: 'Kraków Główny')
      ];
      Future<void> show(Widget screen) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(theme: ThemeData.dark(), home: screen)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
      }

      await show(const StatisticsScreen());
      expect(find.text('Połączono z API PLK'), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.textContaining('JSON'), findsNothing);
      expect(find.textContaining('secret_payload'), findsNothing);
      expect(tester.takeException(), isNull);
      await show(const DataSourceScreen());
      expect(find.text('Połączono z API PLK'), findsOneWidget);
      expect(find.textContaining('secret_payload'), findsNothing);
      state.fixtureApi.fail = true;
      await tester.tap(find.byTooltip('Odśwież status'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nie udało się połączyć'), findsOneWidget);
      expect(find.textContaining('secret_payload'), findsNothing);
      state.fixtureApi.fail = false;
      await show(const DisruptionsScreen());
      await tester.tap(find.text('Awaria sieci trakcyjnej'));
      await tester.pumpAndSettle();
      expect(find.text('IC 3819 MEHOFFER'), findsOneWidget);
      expect(find.text('Numer pociągu niedostępny'), findsOneWidget);
      for (final id in [
        '941965170',
        '228097641',
        '124427125',
        '999999999',
        'secret_payload',
        'JSON'
      ]) {
        expect(find.textContaining(id), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await show(ResultsScreen(
          results: [connectionFixture()],
          fromStationName: 'Warszawa Centralna',
          toStationName: 'Kraków Główny',
          date: '06.09.2026'));
      final earlier = find.textContaining('Pokaż wcześniejsze połączenia');
      if (earlier.evaluate().isNotEmpty) {
        await tester.tap(earlier);
        await tester.pumpAndSettle();
      }
      expect(find.byType(TrainCard), findsOneWidget);
      expect(find.text('Ulubione trasy'), findsOneWidget);
      expect(find.text('Odj. Per. IV/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await show(const SearchScreen());
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.text('Warszawa Centralna → Kraków Główny'));
      await tester.tap(find.text('Warszawa Centralna → Kraków Główny'));
      await tester.pumpAndSettle();
      expect(state.searchedFrom?.id, 1);
      expect(state.searchedTo?.id, 2);
      expect(state.searchedDate, today());
      expect(state.searchedTime, TimeOfDay.fromDateTime(DateTime.now()));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
    testWidgets('GPS state, previous separator and delayed red time at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = FixtureState()
        ..currentStation = Station(id: 1, name: 'Warszawa Centralna')
        ..isDetectingLocation = true;
      StationBoardItem item(String number, DateTime date, {int delay = 0}) =>
          StationBoardItem(
              time: formatTimeDisplay(date.hour, date.minute),
              trainNumber: number,
              trainCategory: 'IC',
              carrier: 'PKP Intercity',
              direction: 'Kraków Główny',
              scheduleId: 1,
              orderId: 1,
              operatingDate: formatDateForApi(date),
              platform: '4',
              track: '3',
              delayMinutes: delay,
              plannedTime: formatTimeDisplay(
                  date.subtract(Duration(minutes: delay)).hour,
                  date.subtract(Duration(minutes: delay)).minute),
              raw: {});
      state.stationDepartures = [
        item('1111', DateTime.now().subtract(const Duration(minutes: 20))),
        item('2222', DateTime.now().add(const Duration(minutes: 20)), delay: 3)
      ];
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
              theme: ThemeData.dark(), home: const StationScreen())));
      await tester.pump();
      expect(find.text('Ustalanie stacji na podstawie GPS...'), findsOneWidget);
      state.isDetectingLocation = false;
      state.isStationFromGps = true;
      state.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.textContaining('Najbliższa stacja (GPS)'), findsOneWidget);
      await tester.tap(find.textContaining('Pokaż wcześniejsze odjazdy'));
      await tester.pumpAndSettle();
      expect(find.text('IC 1111'), findsOneWidget);
      expect(find.text('IC 2222'), findsOneWidget);
      expect(find.textContaining('Aktualne i nadchodzące'), findsOneWidget);
      expect(
          tester
              .widgetList<Divider>(find.byType(Divider))
              .any((d) => (d.thickness ?? 0) >= 1.5),
          isTrue);
      expect(find.text('Per. IV/3'), findsWidgets);
      final delayed = state.stationDepartures.last.time;
      expect(
          tester
              .widgetList<Text>(find.text(delayed))
              .any((t) => t.style?.color == Colors.red),
          isTrue);
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
