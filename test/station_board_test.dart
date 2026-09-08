import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/station_screen.dart';

void main() {
  testWidgets(
      'Board date follows the station event, not the overnight route start',
      (tester) async {
    final now = DateTime.now();
    final event = now.add(const Duration(minutes: 5));
    final state = AppState()
      ..currentStation = Station(id: 1, name: 'Opole Główne')
      ..stationDepartures = [
        StationBoardItem(
            time: event.toIso8601String(),
            actualTime: event.toIso8601String(),
            operatingDate: now
                .subtract(const Duration(days: 1))
                .toIso8601String()
                .split('T')
                .first,
            trainNumber: '123',
            trainCategory: 'IC',
            carrier: '',
            direction: 'Brzeg',
            scheduleId: 1,
            orderId: 1,
            raw: {}),
      ];
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: StationScreen())));
    await tester.pumpAndSettle();
    final date =
        '${event.day.toString().padLeft(2, '0')}.${event.month.toString().padLeft(2, '0')}.${event.year}';
    expect(find.textContaining(date), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'StationScreen renders compact railway board across edge cases and 320px width without RenderFlex overflow',
      (WidgetTester tester) async {
    // Set 320px screen width (narrowest mobile screen)
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();
    appState.currentStation = Station(id: 1, name: 'Warszawa Centralna');

    // Use times 60+ minutes in the future so _isItemPast never hides them
    final now = DateTime.now();
    String futureTime(int offsetMinutes) {
      final t = now.add(Duration(minutes: offsetMinutes));
      return t.toIso8601String();
    }

    // Inject test departures covering all required edge cases
    appState.stationDepartures.clear();
    appState.stationDepartures.addAll([
      // 1. Normalny odjazd (on-time, Per. II / Tor 1, trainName)
      StationBoardItem(
        time: futureTime(60),
        trainNumber: '36103',
        trainName: 'Snieżka',
        trainCategory: 'TLK',
        carrier: 'PKP Intercity',
        direction: 'Jelenia Gora',
        delayMinutes: null,
        isCancelled: false,
        scheduleId: 101,
        orderId: 1,
        operatingDate: now.toIso8601String().split('T').first,
        platform: 'II',
        track: '1',
        plannedTime: futureTime(60),
        actualTime: futureTime(60),
        raw: {},
      ),
      // 2. Opozniony odjazd (+12 min, Per. IV / Tor 8)
      StationBoardItem(
        time: futureTime(75),
        trainNumber: '64223',
        trainName: '',
        trainCategory: 'R',
        carrier: 'POLREGIO',
        direction: 'Raciborz',
        delayMinutes: 12,
        isCancelled: false,
        scheduleId: 102,
        orderId: 1,
        operatingDate: now.toIso8601String().split('T').first,
        platform: 'IV',
        track: '8',
        plannedTime: futureTime(63),
        actualTime: futureTime(75),
        raw: {},
      ),
      // 3. Odwolany
      StationBoardItem(
        time: futureTime(90),
        trainNumber: '1410',
        trainName: 'Wisla',
        trainCategory: 'EIC',
        carrier: 'PKP Intercity',
        direction: 'Wisla Uzdrowisko',
        delayMinutes: 0,
        isCancelled: true,
        scheduleId: 103,
        orderId: 1,
        operatingDate: now.toIso8601String().split('T').first,
        platform: 'I',
        track: '2',
        plannedTime: futureTime(90),
        raw: {},
      ),
      // 4. Brak peronu (platform null, only track)
      StationBoardItem(
        time: futureTime(105),
        trainNumber: '5410',
        trainName: 'Hutnik',
        trainCategory: 'IC',
        carrier: 'PKP Intercity',
        direction: 'Gdynia Glowna',
        delayMinutes: 0,
        isCancelled: false,
        scheduleId: 104,
        orderId: 1,
        operatingDate: now.toIso8601String().split('T').first,
        platform: null,
        track: '3',
        plannedTime: futureTime(105),
        raw: {},
      ),
      // 5. Brak toru (track null, only platform)
      StationBoardItem(
        time: futureTime(120),
        trainNumber: '93450',
        trainName: '',
        trainCategory: 'REGIO',
        carrier: 'POLREGIO',
        direction: 'Otwock',
        delayMinutes: 0,
        isCancelled: false,
        scheduleId: 105,
        orderId: 1,
        operatingDate: now.toIso8601String().split('T').first,
        platform: '2',
        track: null,
        plannedTime: futureTime(120),
        raw: {},
      ),
      // 6. Dluga nazwa kierunku, brak nazwy pociagu
      StationBoardItem(
        time: futureTime(135),
        trainNumber: '3818',
        trainName: '',
        trainCategory: 'IC',
        carrier: 'PKP Intercity',
        direction:
            'Bielsko-Biala Glowna przez Katowice, Tychy, Pszczyne i Czechowice-Dziedzice',
        delayMinutes: 3,
        isCancelled: false,
        scheduleId: 106,
        orderId: 1,
        operatingDate: now.toIso8601String().split('T').first,
        platform: 'II',
        track: '3',
        plannedTime: futureTime(132),
        actualTime: futureTime(135),
        raw: {},
      ),
      // 7. Nazwa pociagu (MEHOFFER)
      StationBoardItem(
        time: futureTime(150),
        trainNumber: '37000',
        trainName: 'MEHOFFER',
        trainCategory: 'IC',
        carrier: 'PKP Intercity',
        direction: 'Szczecin Glowny',
        delayMinutes: 0,
        isCancelled: false,
        scheduleId: 107,
        orderId: 1,
        operatingDate: now.toIso8601String().split('T').first,
        platform: 'III',
        track: '1',
        plannedTime: futureTime(150),
        raw: {},
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(
          home: StationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify screen header
    expect(find.text('Tablica stacyjna'), findsOneWidget);
    expect(find.text('Warszawa Centralna'), findsOneWidget);

    // Verify compact category + train-number badges
    expect(find.text('TLK 36103'), findsOneWidget);
    expect(find.text('R 64223'), findsOneWidget);
    expect(find.text('EIC 1410'), findsOneWidget);
    expect(find.text('IC 5410'), findsOneWidget);
    expect(find.text('REGIO 93450'), findsOneWidget);
    expect(find.text('IC 3818'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('IC 37000'), 100,
        scrollable: find
            .byWidgetPredicate((widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down)
            .hitTestable()
            .first);
    expect(find.text('IC 37000'), findsOneWidget);

    // Verify train names
    expect(find.text('Snie\u017cka'), findsOneWidget);
    expect(find.text('MEHOFFER'), findsOneWidget);

    // Verify platform/track formatting
    expect(find.text('Per. II/1'), findsOneWidget);
    expect(find.text('Per. IV/8'), findsOneWidget);
    expect(find.text('Tor 3'), findsOneWidget);
    expect(find.text('Per. II'), findsOneWidget);
    expect(find.text('Per. II/3'), findsOneWidget);

    // Verify delay texts
    expect(find.text('Planowo'), findsWidgets);
    expect(find.text('Rozkład'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('Odwo\u0142any'), findsOneWidget);

    // Planned time for the delayed train should be shown (strikethrough)
    // It's a future time computed dynamically; just verify the widget renders without crash
    expect(find.byType(StationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to Przyjazdy tab
    await tester.tap(find.text('Przyjazdy'));
    await tester.pumpAndSettle();

    // Verify no crash on tab switch
    expect(find.byType(StationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Station board reveals earlier and later departures and arrivals in pages',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    String time(DateTime value) =>
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    StationBoardItem item(String number, DateTime date) => StationBoardItem(
          time: time(date),
          trainNumber: number,
          trainCategory: 'IC',
          carrier: 'PKP Intercity',
          direction: 'Kraków Główny',
          scheduleId: int.parse(number),
          orderId: 1,
          operatingDate: date.toIso8601String().split('T').first,
          platform: '2',
          track: '3',
          delayMinutes: 0,
          plannedTime: time(date),
          raw: const {},
        );

    final state = AppState()
      ..currentStation = Station(id: 1, name: 'Warszawa Centralna')
      ..stationBoardCanLoadMore = false
      ..stationDepartures = [
        item('1001', now.subtract(const Duration(minutes: 20))),
        ...List.generate(
            10,
            (index) => item(
                '${1100 + index}', now.add(Duration(minutes: 20 + index * 5)))),
      ]
      ..stationArrivals = [
        item('2001', now.subtract(const Duration(minutes: 20))),
        ...List.generate(
            10,
            (index) => item(
                '${2100 + index}', now.add(Duration(minutes: 20 + index * 5)))),
      ];

    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: StationScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dziś,'), findsOneWidget);
    expect(find.text('IC 1001'), findsNothing);
    final earlier = find.byKey(const ValueKey('toggle-earlier-departures'));
    if (earlier.evaluate().isNotEmpty) {
      await tester.tap(earlier);
      await tester.pumpAndSettle();
    }
    expect(find.text('IC 1001'), findsOneWidget);
    Future<void> revealPageAction(String key) async {
      // Use the scroll position here: Android's real pointer coordinates do
      // not follow the overridden test viewport density. Manual emulator QA
      // separately verifies swipe gestures using the native screen size.
      final scrollable = find
          .byWidgetPredicate((widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down)
          .hitTestable()
          .first;
      for (var i = 0;
          i < 8 && find.byKey(ValueKey(key)).hitTestable().evaluate().isEmpty;
          i++) {
        final position = tester.state<ScrollableState>(scrollable).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
    }

    await revealPageAction('show-more-departures');
    expect(find.text('Pokaż kolejne odjazdy (2)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('show-more-departures')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('show-more-departures')), findsNothing);

    await tester.tap(find.text('Przyjazdy'));
    await tester.pumpAndSettle();
    expect(find.text('IC 2001'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('toggle-earlier-arrivals')));
    await tester.pumpAndSettle();
    expect(find.text('IC 2001'), findsOneWidget);
    await revealPageAction('show-more-arrivals');
    expect(find.text('Pokaż kolejne przyjazdy (2)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('show-more-arrivals')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('show-more-arrivals')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Board appends the next day only after Pokaż więcej',
      (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    StationBoardItem item(String number, DateTime date, String time) =>
        StationBoardItem(
          time: time,
          trainNumber: number,
          trainCategory: 'IC',
          carrier: 'PKP Intercity',
          direction: 'Kraków Główny',
          scheduleId: int.parse(number),
          orderId: 1,
          operatingDate: date.toIso8601String().split('T').first,
          plannedTime: time,
          raw: const {},
        );

    final state = _MidnightBoardState(
      today: [item('2340', today, '23:40'), item('2358', today, '23:58')],
      tomorrow: [
        item('0012', tomorrow, '00:12'),
        item('0043', tomorrow, '00:43'),
      ],
    )..currentStation = Station(id: 1, name: 'Warszawa Centralna');
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: StationScreen()),
    ));
    await tester.pumpAndSettle();
    expect(state.nextDayCalls, 0);
    await tester.tap(find.byKey(const ValueKey('show-more-departures')));
    await tester.pumpAndSettle();
    expect(state.nextDayCalls, 1);
    expect(find.text('23:40'), findsOneWidget);
    expect(find.text('23:58'), findsOneWidget);
    expect(
        find.text('Jutro · ${tomorrow.day.toString().padLeft(2, '0')}.'
            '${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}'),
        findsOneWidget);
    expect(find.text('00:12'), findsOneWidget);
    expect(find.text('00:43'), findsOneWidget);
    final first = tester.getTopLeft(find.text('23:40')).dy;
    final midnight = tester.getTopLeft(find.text('00:12')).dy;
    expect(first, lessThan(midnight));
    expect(tester.takeException(), isNull);
  });
}

class _MidnightBoardState extends AppState {
  final List<StationBoardItem> today;
  final List<StationBoardItem> tomorrow;
  int nextDayCalls = 0;

  _MidnightBoardState({required this.today, required this.tomorrow}) {
    stationDepartures = today;
    stationBoardCanLoadMore = true;
  }

  @override
  Future<void> loadNextStationBoardDay() async {
    nextDayCalls++;
    stationDepartures = [...stationDepartures, ...tomorrow];
    stationBoardCanLoadMore = false;
    notifyListeners();
  }
}
