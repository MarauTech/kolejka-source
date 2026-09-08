import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/screens/disruptions_screen.dart';
import 'fixtures.dart';

class DescriptionState extends FixtureState {
  @override
  Future<Map<String, dynamic>> getDisruptions() async => {
        'disruptionTypes': {
          'utr_55': 'Ograniczenie prędkości pociągu',
          'utr_43': 'Awaria taboru'
        },
        'disruptions': [
          {'disruptionId': 1, 'message': 'utr_55'},
          {'disruptionId': 2, 'message': '', 'disruptionTypeCode': 'utr_43'},
          {'disruptionId': 3, 'message': 'utr_999'},
          {'disruptionId': 4, 'message': ' '},
        ],
      };
}

void main() {
  testWidgets(
      'Both real dictionary-reference formats display descriptions; genuinely empty alerts are omitted',
      (tester) async {
    final state = DescriptionState();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: DisruptionsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Ograniczenie prędkości pociągu'), findsOneWidget);
    expect(find.text('Awaria taboru'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.textContaining('Brak szczegółowego'), findsNothing);
    expect(find.textContaining('utr_'), findsNothing);
    await tester.tap(find.text('Ograniczenie prędkości pociągu'));
    await tester.pumpAndSettle();
    expect(find.text('Ograniczenie prędkości pociągu'), findsWidgets);
    expect(find.textContaining('Brak szczegółowego'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
