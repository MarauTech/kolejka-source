import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/screens/disruptions_screen.dart';
import 'fixtures.dart';

class ManyDisruptionsState extends FixtureState {
  @override
  Future<Map<String, dynamic>> getDisruptions() async => {
        'disruptions': [
          {
            'disruptionId': 96,
            'message': 'Utrudnienie testowe',
            'affectedRoutes': [
              for (var index = 0; index < 96; index++)
                {
                  'scheduleId': index + 1,
                  'orderId': index + 1,
                  'commercialCategorySymbol': 'IC',
                  'nationalNumber': '${1000 + index}',
                  'name': 'TEST $index',
                }
            ],
          }
        ],
      };
}

void main() {
  testWidgets('All 96 affected trains remain available in paged details',
      (tester) async {
    final state = ManyDisruptionsState();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: DisruptionsScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Utrudnienie testowe'));
    await tester.pumpAndSettle();
    expect(find.text('Dotknięte pociągi (96):'), findsOneWidget);
    expect(find.text('Wyświetlono 20 z 96'), findsOneWidget);
    expect(find.text('IC 1000 TEST 0'), findsOneWidget);
    expect(find.text('IC 1095 TEST 95'), findsNothing);
    for (var page = 0; page < 4; page++) {
      final more = find.byKey(const ValueKey('show-more-affected-trains'));
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
    }
    expect(find.text('Wyświetlono 96 z 96'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('show-more-affected-trains')), findsNothing);
    expect(find.text('IC 1095 TEST 95'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
