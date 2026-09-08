import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/api/api_client.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/search_screen.dart';
import 'package:trainly/widgets/station_search.dart';
import 'package:trainly/widgets/connection_results.dart';
import 'package:trainly/widgets/train_card.dart';
import 'fixtures.dart';

class SearchFixture extends FixtureState {
  Completer<List<ConnectionResult>>? pending;
  @override
  Future<List<ConnectionResult>> searchConnections(
      {required Station fromStation,
      required Station toStation,
      required DateTime date,
      required TimeOfDay time}) {
    searchedFrom = fromStation;
    searchedTo = toStation;
    searchedDate = date;
    searchedTime = time;
    return pending?.future ?? Future.value([connectionFixture()]);
  }
}

void main() {
  testWidgets('Rate limit explains retry and does not retain stale journeys',
      (tester) async {
    final state = SearchFixture();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
            home: SearchScreen(
                initialFromStation: Station(id: 1, name: 'Opole Główne'),
                initialToStation: Station(id: 2, name: 'Gliwice')))));
    await tester.tap(find.text('Wyszukaj połączenia'));
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionResults), findsOneWidget);
    await tester.tap(find.byTooltip('Zmień trasę lub termin'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zamień stacje'));
    await tester.pumpAndSettle();
    state.pending = Completer<List<ConnectionResult>>();
    await tester.tap(find.text('Wyszukaj połączenia'));
    await tester.pump();
    expect(find.byType(ConnectionResults), findsNothing);
    state.pending!.completeError(
        ApiException(statusCode: 429, message: 'secret_payload'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Spróbuj ponownie za minutę.'), findsOneWidget);
    expect(find.textContaining('secret_payload'), findsNothing);
    expect(find.text('Ulubione trasy'), findsNothing);
    expect(find.byType(ConnectionResults), findsNothing);
    expect(find.byKey(const ValueKey('origin-field')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 384.0, 411.0]) {
      testWidgets(
          'Inline railway form, swap, favorite, loading and results $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = SearchFixture();
        final from = Station(
            id: 1, name: 'Warszawa Centralna Bardzo Długa Nazwa Stacji');
        final to = Station(id: 2, name: 'Kędzierzyn-Koźle');
        state.stations = [from, to];
        await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                home: SearchScreen(
                    initialFromStation: from, initialToStation: to))));
        await tester.pumpAndSettle();
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        expect(find.byType(Card), findsNothing);
        expect(find.text('Brak ulubionych tras'), findsOneWidget);
        final origin = find.byKey(const ValueKey('origin-field'));
        await tester.tap(find.byTooltip('Zamień stacje'));
        await tester.pumpAndSettle();
        expect(
            tester.widget<StationSearchField>(origin).selectedStation?.id, 2);
        expect(
            tester
                .widget<StationSearchField>(
                    find.byKey(const ValueKey('destination-field')))
                .selectedStation
                ?.id,
            1);
        state.favoriteRoutes = [
          FavoriteRoute(
              fromStationId: 1,
              fromStationName: from.name,
              toStationId: 2,
              toStationName: to.name)
        ];
        state.notifyListeners();
        await tester.pumpAndSettle();
        state.pending = Completer<List<ConnectionResult>>();
        await tester.tap(find.text('${from.name} → ${to.name}'));
        await tester.pump();
        expect(state.searchedFrom?.id, 1);
        expect(state.searchedTo?.id, 2);
        expect(state.searchedDate, DateUtils.dateOnly(DateTime.now()));
        expect(state.searchedTime, TimeOfDay.fromDateTime(DateTime.now()));
        expect(find.text('Wyszukiwanie połączeń...'), findsOneWidget);
        expect(find.text('Wyszukaj połączenia'), findsOneWidget);
        expect(find.text('Ulubione trasy'), findsNothing);
        expect(origin, findsOneWidget);
        state.pending!.complete([connectionFixture()]);
        await tester.pumpAndSettle();
        expect(find.byType(SearchScreen), findsOneWidget);
        expect(find.byType(ConnectionResults), findsOneWidget);
        expect(find.text('Ulubione trasy'), findsNothing);
        expect(origin, findsNothing);
        expect(find.byTooltip('Zmień trasę lub termin'), findsOneWidget);
        final earlier = find.textContaining('Pokaż wcześniejsze połączenia');
        if (earlier.evaluate().isNotEmpty) {
          await tester.ensureVisible(earlier);
          await tester.tap(earlier);
          await tester.pumpAndSettle();
        }
        expect(find.byType(TrainCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        await tester.ensureVisible(find.byTooltip('Zmień trasę lub termin'));
        await tester.tap(find.byTooltip('Zmień trasę lub termin'));
        await tester.pumpAndSettle();
        expect(
            tester.widget<StationSearchField>(origin).selectedStation?.id, 1);
        expect(find.text('Ulubione trasy'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      });
    }
  }
  testWidgets(
      'Earlier results use requested time, empty state and stale response',
      (tester) async {
    final state = SearchFixture()
      ..pending = Completer<List<ConnectionResult>>();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
            home: SearchScreen(
                initialFromStation: Station(id: 1, name: 'Opole Główne'),
                initialToStation: Station(id: 2, name: 'Gliwice')))));
    await tester.tap(find.text('Wyszukaj połączenia'));
    await tester.pump();
    await tester.tap(find.byTooltip('Zamień stacje'));
    await tester.pump();
    state.pending!.complete([connectionFixture()]);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionResults), findsNothing);
    state.pending = Completer<List<ConnectionResult>>();
    await tester.tap(find.text('Wyszukaj połączenia'));
    await tester.pump();
    state.pending!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Nie znaleziono połączeń'), findsOneWidget);
    expect(find.text('Ulubione trasy'), findsNothing);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ConnectionResults(
                results: [connectionFixture()],
                selectedDeparture: DateTime(2026, 9, 6, 9)))));
    await tester.pumpAndSettle();
    expect(find.byType(TrainCard), findsOneWidget);
    expect(find.textContaining('Pokaż wcześniejsze'), findsNothing);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ConnectionResults(
                results: [connectionFixture()],
                selectedDeparture: DateTime(2026, 9, 6, 11)))));
    await tester.pumpAndSettle();
    expect(find.byType(TrainCard), findsNothing);
    await tester.tap(find.textContaining('Pokaż wcześniejsze'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainCard), findsOneWidget);
    expect(
        tester
            .widgetList<Divider>(find.byType(Divider))
            .any((d) => (d.thickness ?? 0) >= 2),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
