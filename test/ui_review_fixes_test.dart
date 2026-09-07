import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/main.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/widgets/station_search.dart';

import 'fixtures.dart';

void main() {
  testWidgets('Station suggestions accept names without Polish diacritics',
      (tester) async {
    Station? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StationSearchField(
          label: 'Stacja',
          stations: [Station(id: 1, name: 'Łódź Fabryczna')],
          selectedStation: null,
          onStationSelected: (value) => selected = value,
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'Lodz');
    await tester.pumpAndSettle();
    expect(find.text('Łódź Fabryczna'), findsOneWidget);
    await tester.tap(find.text('Łódź Fabryczna'));
    expect(selected?.id, 1);
  });

  testWidgets('Unknown station query explains why no suggestion is shown',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StationSearchField(
          label: 'Stacja',
          stations: [Station(id: 1, name: 'Łódź Fabryczna')],
          selectedStation: null,
          onStationSelected: (_) {},
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'Atlantyda');
    await tester.pump();
    expect(find.text('Nie znaleziono stacji'), findsOneWidget);
  });

  testWidgets('Polish app locale translates the date picker', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('pl', 'PL'),
      supportedLocales: [Locale('pl', 'PL')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: _DatePickerButton()),
    ));
    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    expect(find.text('Wybierz datę'), findsOneWidget);
    expect(find.textContaining('Anul'), findsOneWidget);
  });

  testWidgets(
      'Favorite route stays in main navigation and searches immediately',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = FixtureState()
      ..favoriteRoutes = [
        FavoriteRoute(
            fromStationId: 1,
            fromStationName: 'Warszawa Centralna',
            toStationId: 2,
            toStationName: 'Poznań Główny')
      ];
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: MainScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ulubione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trasy (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Warszawa Centralna'), findsOneWidget);
    expect(find.text('Poznań Główny'), findsOneWidget);
    await tester.tap(find.text('Poznań Główny'));
    await tester.pumpAndSettle();
    expect(state.searchedFrom?.id, 1);
    expect(state.searchedTo?.id, 2);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Wyniki połączeń'), findsOneWidget);
    state.dispose();
  });

  testWidgets('Main navigation labels stay on one line at 320 dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = FixtureState();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: MainScreen())));
    await tester.pumpAndSettle();
    final labelSize = tester.getSize(find.text('Trasy'));
    expect(labelSize.height, lessThan(18));
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showDatePicker(
        context: context,
        initialDate: DateTime(2026, 9, 7),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      ),
      child: const Text('Data'),
    );
  }
}
