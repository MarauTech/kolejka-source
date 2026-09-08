import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/api/api_client.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/disruptions_screen.dart';
import 'package:trainly/screens/permissions_screen.dart';
import 'package:trainly/screens/search_screen.dart';
import 'package:trainly/screens/station_screen.dart';
import 'package:trainly/screens/train_search_screen.dart';
import 'package:trainly/screens/train_details_screen.dart';
import 'package:trainly/services/location_service.dart';
import 'package:trainly/widgets/connection_results.dart';
import 'package:trainly/widgets/train_card.dart';
import 'fixtures.dart';
import 'connection_form_test.dart' show SearchFixture;

Widget shell(AppState state, Widget screen) =>
    ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          locale: const Locale('pl', 'PL'),
          supportedLocales: const [Locale('pl', 'PL')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          home: screen,
        ));

class PermissionFixture extends LocationService {
  LocationPermissionStatus status = LocationPermissionStatus.denied;
  @override
  Future<LocationPermissionStatus> checkPermission() async => status;
  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      status = LocationPermissionStatus.permanentlyDenied;
}

class OfflineDisruptions extends FixtureState {
  @override
  Map<String, dynamic> get cachedDisruptions => {
        'ts': '2026-09-07T12:00:00',
        'disruptions': [
          {'message': 'Zapamiętane utrudnienie'}
        ]
      };
  @override
  Future<Map<String, dynamic>> getDisruptions() async =>
      throw ApiException(message: 'secret_payload', isConnectionError: true);
}

class FailingTrains extends FixtureState {
  int status = 429;
  @override
  Future<List<TrainSearchResult>> searchTrainByNumber(String query,
          {DateTime? date}) async =>
      throw ApiException(statusCode: status, message: 'secret_payload');
  @override
  Future<TrainOperation?> getTrainOperation(
          int scheduleId, int orderId, String operatingDate) async =>
      throw ApiException(statusCode: status, message: 'secret_payload');
}

void main() {
  testWidgets(
      'Permission denial result and return from settings update at 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = PermissionFixture();
    final state = FixtureState()..locationService = location;
    await tester.pumpWidget(shell(state, const PermissionsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zezwól na dostęp'));
    await tester.pumpAndSettle();
    expect(find.text('Dostęp zablokowany w systemie'), findsOneWidget);
    expect(find.text('Ustawienia aplikacji'), findsOneWidget);
    expect(find.text('Zezwól na dostęp'), findsNothing);
    location.status = LocationPermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Uprawnienie przyznane'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('Polish time picker accepts 23:45 and 11:45 without hidden AM/PM',
      (tester) async {
    final state = FixtureState();
    await tester.pumpWidget(shell(state, const SearchScreen()));
    await tester.pumpAndSettle();
    for (final hour in ['23', '11']) {
      await tester.tap(find.byKey(const ValueKey('connection-time')));
      await tester.pumpAndSettle();
      final picker =
          tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      expect(picker.use24hFormat, isTrue);
      picker.onDateTimeChanged(DateTime(2026, 9, 8, int.parse(hour), 45));
      await tester.tap(find.text('Gotowe'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsNothing);
      expect(find.text('$hour:45'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'Repeating identical journey retains results during request and offline error',
      (tester) async {
    final state = SearchFixture();
    await tester.pumpWidget(shell(
        state,
        SearchScreen(
            initialFromStation: Station(id: 1, name: 'Opole'),
            initialToStation: Station(id: 2, name: 'Gliwice'))));
    await tester.tap(find.text('Wyszukaj połączenia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zmień trasę lub termin'));
    await tester.pumpAndSettle();
    state.pending = Completer<List<ConnectionResult>>();
    await tester.tap(find.text('Wyszukaj połączenia'));
    await tester.pump();
    expect(find.byType(ConnectionResults), findsOneWidget);
    state.pending!.completeError(
        ApiException(message: 'secret_payload', isConnectionError: true));
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionResults), findsOneWidget);
    expect(find.textContaining('mogą być nieaktualne'), findsOneWidget);
    expect(find.textContaining('secret_payload'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'Delayed train with future departure remains in upcoming connections',
      (tester) async {
    final from = StationOnRoute(
        stationId: 1, orderNumber: 1, departureTime: '16:16:00', raw: {});
    final to = StationOnRoute(
        stationId: 2, orderNumber: 2, arrivalTime: '18:00:00', raw: {});
    final result = ConnectionResult(
        route: TrainRoute(
            scheduleId: 1,
            orderId: 2,
            stations: [from, to],
            operatingDates: ['2026-09-07'],
            connections: [],
            raw: {}),
        fromStop: from,
        toStop: to,
        fromStationName: 'Opole',
        toStationName: 'Gliwice',
        carrierName: '',
        commercialCategory: 'IC',
        operatingDate: '2026-09-07',
        operation: TrainOperation(
            scheduleId: 1,
            orderId: 2,
            trainOrderId: 3,
            operatingDate: '2026-09-07',
            stations: [
              OperationStation(
                  stationId: 1,
                  plannedSequenceNumber: 1,
                  actualSequenceNumber: 1,
                  plannedDeparture: '2026-09-07T16:16:00',
                  actualDeparture: '2026-09-07T17:42:00',
                  isConfirmed: false,
                  isCancelled: false,
                  raw: {})
            ],
            raw: {}));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ConnectionResults(
                results: [result],
                selectedDeparture: DateTime(2026, 9, 7, 16, 30)))));
    await tester.pumpAndSettle();
    expect(find.byType(TrainCard), findsOneWidget);
    expect(find.textContaining('Pokaż wcześniejsze'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Cached disruptions remain visible with an offline warning after reopening',
      (tester) async {
    final state = OfflineDisruptions();
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(shell(state, const DisruptionsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Zapamiętane utrudnienie'), findsOneWidget);
      expect(find.textContaining('Nie udało się pobrać utrudnień'),
          findsOneWidget);
      expect(find.textContaining('secret_payload'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
    state.dispose();
  });

  for (final status in [429, 500, 503]) {
    testWidgets('Train search explains HTTP $status instead of an empty result',
        (tester) async {
      final state = FailingTrains()..status = status;
      await tester.pumpWidget(shell(state, const TrainSearchScreen()));
      await tester.enterText(find.byType(TextField), '5410');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
          find.textContaining(status == 429 ? 'przeciążone' : 'Nie udało się'),
          findsOneWidget);
      expect(find.textContaining('Nie znaleziono'), findsNothing);
      expect(find.textContaining('secret_payload'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets(
      'Failed details refresh retains validated operations and warns about freshness',
      (tester) async {
    final state = FailingTrains();
    await tester.pumpWidget(
        shell(state, TrainDetailsScreen(result: connectionFixture())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Wyświetlam zapisane dane'), findsOneWidget);
    expect(find.textContaining('secret_payload'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'Board negative delay and missing planned time remain readable without identifiers',
      (tester) async {
    final now = DateTime.now().add(const Duration(hours: 1));
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final state = FixtureState()
      ..currentStation = Station(id: 1, name: 'Kędzierzyn-Koźle')
      ..stationDepartures = [
        StationBoardItem(
            time: time,
            trainNumber: '36101',
            trainName: 'PLANTY',
            trainCategory: 'TLK',
            carrier: '',
            direction: 'Gliwice',
            scheduleId: 2026,
            orderId: 503588516,
            operatingDate: now.toIso8601String().split('T').first,
            plannedTime: '--:--',
            actualTime: now.toIso8601String(),
            delayMinutes: -1,
            raw: {})
      ]
      ..stationBoardError =
          'Nie udało się odświeżyć tablicy. Spróbuj ponownie.';
    await tester.pumpWidget(shell(state, const StationScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('+-1'), findsNothing);
    expect(find.text('-1'), findsOneWidget);
    expect(find.text(time), findsOneWidget);
    expect(find.text('--:--'), findsNothing);
    expect(find.textContaining('503588516'), findsNothing);
    expect(find.textContaining('Nie udało się odświeżyć'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
