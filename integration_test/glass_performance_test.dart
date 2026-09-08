import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/station_screen.dart';
import 'package:trainly/screens/train_details_screen.dart';
import 'package:trainly/widgets/app_style.dart';
import 'package:trainly/widgets/connection_results.dart';
import '../test/fixtures.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
      'Profile scroll cost: board, connections and route in Classic and Glass',
      (tester) async {
    for (final glass in [false, true]) {
      for (final screen in ['board', 'connections', 'route']) {
        final state = FixtureState();
        final sample = connectionFixture();
        state.updatedOperation = sample.operation;
        for (final stop in sample.route.stations) {
          state.stationNames[stop.stationId] =
              'Stacja kolejowa ${stop.orderNumber}';
        }
        state.currentStation = Station(id: 1, name: 'Opole Główne');
        state.stationBoardCanLoadMore = false;
        state.stationDepartures = List.generate(
            80,
            (i) => StationBoardItem(
                  time: '10:${(i % 60).toString().padLeft(2, '0')}',
                  trainNumber: '${3800 + i}',
                  trainCategory: i.isEven ? 'IC' : 'R',
                  trainName: 'Pociąg ${i + 1}',
                  carrier: 'PKP Intercity',
                  direction: 'Kraków Główny',
                  operatingDate: '2026-09-06',
                  scheduleId: 2026,
                  orderId: i,
                  plannedTime:
                      '2026-09-06T10:${(i % 60).toString().padLeft(2, '0')}:00',
                  raw: {},
                ));
        final connections = List.generate(
            24,
            (i) => ConnectionResult(
                  route: TrainRoute(
                      scheduleId: 2026,
                      orderId: i,
                      nationalNumber: '${3800 + i}',
                      commercialCategorySymbol: 'IC',
                      stations: sample.route.stations,
                      operatingDates: ['2026-09-06'],
                      connections: [],
                      raw: {}),
                  fromStop: sample.fromStop,
                  toStop: sample.toStop,
                  fromStationName: sample.fromStationName,
                  toStationName: sample.toStationName,
                  carrierName: 'PKP Intercity',
                  commercialCategory: 'IC',
                  operatingDate: '2026-09-06',
                ));
        final Widget page = switch (screen) {
          'board' => const StationScreen(),
          'connections' => SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConnectionResults(
                      results: connections,
                      selectedDeparture: DateTime(2026, 9, 6)))),
          _ => TrainDetailsScreen(
              result: sample, now: () => DateTime(2026, 9, 6, 10, 19)),
        };
        await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
            value: state,
            child: GlassPerformance(
                enabled: glass,
                builder: (context, allowBlur) => MaterialApp(
                      theme: kolejkaTheme(Brightness.light,
                          glass: glass, blur: allowBlur),
                      home: Scaffold(
                          body: page,
                          bottomNavigationBar: GlassSurface(
                              radius: 0,
                              child: NavigationBar(destinations: const [
                                NavigationDestination(
                                    icon: Icon(Icons.train), label: 'Tablica'),
                                NavigationDestination(
                                    icon: Icon(Icons.route),
                                    label: 'Połączenia')
                              ]))),
                    ))));
        await tester.pump(const Duration(seconds: 1));
        final previous = find.byKey(const ValueKey('toggle-previous-stations'));
        if (previous.evaluate().isNotEmpty) {
          await tester.tap(previous);
          await tester.pump(const Duration(milliseconds: 300));
        }
        final scroll = screen == 'board'
            ? find.byType(ListView).first
            : find.byType(SingleChildScrollView).first;
        for (var i = 0; i < 2; i++) {
          await tester.fling(scroll, Offset(0, i.isEven ? -450 : 450), 1000);
          await tester.pump(const Duration(milliseconds: 600));
        }
        final reportKey = '${glass ? 'glass' : 'classic'}_$screen';
        await binding.watchPerformance(() async {
          for (var i = 0; i < 8; i++) {
            await tester.fling(scroll, Offset(0, i.isEven ? -450 : 450), 1000);
            await tester.pump(const Duration(milliseconds: 600));
          }
        }, reportKey: reportKey);
        final style =
            Theme.of(tester.element(scroll)).extension<SurfaceStyle>();
        binding.reportData!['${reportKey}_blur_enabled'] = style?.blur ?? false;
        // ignore: avoid_print
        print(
            'SCROLL PROFILE $reportKey ${jsonEncode(binding.reportData![reportKey])} blur=${style?.blur}');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    }
  });
}
