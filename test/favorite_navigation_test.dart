import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/main.dart';
import 'package:trainly/models/models.dart';
import 'fixtures.dart';

class FavoriteNavigationState extends FixtureState {
  @override
  Future<void> selectManualStation(Station station) async {
    currentStation = station;
    notifyListeners();
  }
}

void main() {
  testWidgets(
      'Favorite station opens its board through the real bottom navigation',
      (tester) async {
    final state = FavoriteNavigationState()
      ..favoriteStations = [FavoriteStation(id: 1, name: 'Opole Główne')];
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: MainScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Ulubione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opole Główne'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
    expect(find.text('Tablica stacyjna'), findsOneWidget);
    expect(state.currentStation?.id, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
