import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/screens/station_screen.dart';
import 'package:trainly/services/cache_service.dart';
import 'package:trainly/widgets/station_picker.dart';
import 'fixtures.dart';

class PickerState extends FixtureState {
  int gpsRequests = 0;
  @override
  Future<void> detectNearestStation({bool forceRefresh = true}) async {
    gpsRequests++;
  }
}

void main() {
  for (final width in [320.0, 360.0, 384.0, 411.0]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
          'Station picker stays usable above keyboard: $width $brightness',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        final cache = CacheService();
        await cache.init();
        final state = PickerState()
          ..cache = cache
          ..currentStation = Station(id: 1, name: 'Opole Główne')
          ..stations = [
            Station(id: 1, name: 'Opole Główne'),
            Station(id: 2, name: 'Kędzierzyn-Koźle Przystanek'),
            Station(id: 3, name: 'Długopole-Zdrój'),
          ]
          ..favoriteStations = [
            FavoriteStation(id: 2, name: 'Kędzierzyn-Koźle Przystanek'),
          ];
        state.recentStations = [...state.stations];
        tester.view.physicalSize = Size(width * 3, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: ThemeData(brightness: brightness, useMaterial3: true),
            home: const StationScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Opole Główne').first);
        await tester.pumpAndSettle();
        // Saved stations remain accessible immediately, without forced typing.
        expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .focusNode
                .hasFocus,
            isFalse);
        expect(find.text('Kędzierzyn-Koźle Przystanek'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'opole');
        tester.view.viewInsets = const FakeViewPadding(bottom: 900);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        final fieldRect = tester.getRect(find.byType(TextField));
        expect(fieldRect.bottom, lessThanOrEqualTo(480));
        // Matching inside a name is excluded, including Długopole.
        expect(find.text('Długopole-Zdrój'), findsNothing);
        final resultTiles = tester.widgetList<ListTile>(find.descendant(
            of: find.byType(StationPicker), matching: find.byType(ListTile)));
        expect((resultTiles.first.title! as Text).data, 'Opole Główne');
        await tester.enterText(find.byType(TextField), 'Kedzierzyn');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        final result = find.text('Kędzierzyn-Koźle Przystanek');
        await tester.ensureVisible(result);
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(state.currentStation!.id, 2);
        expect(find.byType(StationPicker), findsNothing);
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      });
    }
  }

  testWidgets(
      'Station picker GPS shortcut closes the panel and requests location once',
      (tester) async {
    final state = PickerState()
      ..currentStation = Station(id: 1, name: 'Opole Główne');
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: StationScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opole Główne').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Najbliższa stacja'));
    await tester.pumpAndSettle();
    expect(state.gpsRequests, 1);
    expect(find.byType(StationPicker), findsNothing);
    expect(state.currentStation!.id, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'Closing station picker keeps its controller alive through reverse animation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheService();
    await cache.init();
    final state = FixtureState()
      ..cache = cache
      ..currentStation = Station(id: 1, name: 'Opole Główne')
      ..stations = [
        Station(id: 1, name: 'Opole Główne'),
        Station(id: 2, name: 'Kędzierzyn-Koźle')
      ];
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: StationScreen())));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(state.currentStation!.name).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Kedzierzyn');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Kędzierzyn-Koźle').last);
      await tester.pump();
      // The Navigator pop future has completed, but the sheet still builds.
      tester.view.physicalSize = Size(1080, i.isEven ? 2200 : 2340);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(state.currentStation!.id, 2);
    }
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
