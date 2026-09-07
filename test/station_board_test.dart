import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/station_screen.dart';

void main() {
  testWidgets(
      'StationScreen renders compact railway board across edge cases and 320px width without RenderFlex overflow',
      (WidgetTester tester) async {
    // Set 320px screen width (narrowest mobile screen)
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    appState.currentStation = Station(id: 1, name: 'Warszawa Centralna');

    // Use times 60+ minutes in the future so _isItemPast never hides them
    final now = DateTime.now();
    String futureTime(int offsetMinutes) {
      final t = now.add(Duration(minutes: offsetMinutes));
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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

    // Verify category badges
    expect(find.text('TLK'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.text('EIC'), findsOneWidget);
    expect(find.text('REGIO'), findsOneWidget);

    // Verify train numbers
    expect(find.text('36103'), findsOneWidget);
    expect(find.text('64223'), findsOneWidget);
    expect(find.text('1410'), findsOneWidget);
    expect(find.text('5410'), findsOneWidget);
    expect(find.text('93450'), findsOneWidget);
    expect(find.text('3818'), findsOneWidget);
    expect(find.text('37000'), findsOneWidget);

    // Verify train names
    expect(find.text('Snie\u017cka'), findsOneWidget);
    expect(find.text('MEHOFFER'), findsOneWidget);

    // Verify platform/track formatting
    expect(find.text('Per. II / Tor 1'), findsOneWidget);
    expect(find.text('Per. IV / Tor 8'), findsOneWidget);
    expect(find.text('Tor 3'), findsOneWidget);
    expect(find.text('Per. II'), findsOneWidget);
    expect(find.text('Per. II / Tor 3'), findsOneWidget);

    // Verify delay texts
    expect(find.text('Planowo'), findsWidgets);
    expect(find.text('Wg rozkładu'), findsOneWidget);
    expect(find.text('+12 min'), findsOneWidget);
    expect(find.text('+3 min'), findsOneWidget);
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
}
