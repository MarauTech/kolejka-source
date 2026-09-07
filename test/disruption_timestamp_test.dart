import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/screens/disruptions_screen.dart';
import 'package:trainly/utils/date_utils.dart' as app_date;
import 'fixtures.dart';

class TimestampFixture extends FixtureState {
  String? generatedAt = '2026-09-07T15:01:48Z';
  bool shortenedTimestamp = false;
  bool timestampAsDateTime = false;
  String? createdAt;
  @override
  Future<Map<String, dynamic>> getDisruptions() async => {
        if (shortenedTimestamp)
          'ts': timestampAsDateTime && generatedAt != null
              ? DateTime.parse(generatedAt!)
              : generatedAt
        else
          'generatedAt': timestampAsDateTime && generatedAt != null
              ? DateTime.parse(generatedAt!)
              : generatedAt,
        'disruptions': [
          {
            'disruptionId': 1,
            'message': 'Awaria sieci trakcyjnej',
            if (createdAt != null) 'createdAt': createdAt,
          }
        ]
      };
}

void main() {
  testWidgets('Snapshot time is localized and never labeled as creation time',
      (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = TimestampFixture();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: state, child: const MaterialApp(home: DisruptionsScreen())));
    await tester.pumpAndSettle();
    final local = DateTime.parse(state.generatedAt!).toLocal();
    expect(
        find.text('Dane z ${app_date.formatDateDisplay(local)}, '
            '${app_date.formatTimeDisplay(local.hour, local.minute)}'),
        findsOneWidget);
    state.timestampAsDateTime = true;
    await tester.tap(find.byTooltip('Odśwież'));
    await tester.pumpAndSettle();
    expect(
        find.text('Dane z ${app_date.formatDateDisplay(local)}, '
            '${app_date.formatTimeDisplay(local.hour, local.minute)}'),
        findsOneWidget);
    state.timestampAsDateTime = false;
    expect(find.textContaining('Dodano'), findsNothing);
    await tester.tap(find.text('Awaria sieci trakcyjnej'));
    await tester.pumpAndSettle();
    expect(find.text('Godzina dodania: źródło nie udostępnia tej informacji.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.text('Treść komunikatu:'))).pop();
    await tester.pumpAndSettle();
    state.generatedAt = '2026-09-07T15:01:48Z';
    state.createdAt = '2026-09-07T13:42:00Z';
    await tester.tap(find.byTooltip('Odśwież'));
    await tester.pumpAndSettle();
    final createdLocal = DateTime.parse(state.createdAt!).toLocal();
    final createdLabel =
        app_date.formatTimeDisplay(createdLocal.hour, createdLocal.minute);
    expect(find.text('Dodano o $createdLabel'), findsOneWidget);
    await tester.tap(find.text('Awaria sieci trakcyjnej'));
    await tester.pumpAndSettle();
    expect(find.text('Dodano o $createdLabel'), findsNWidgets(2));
    Navigator.of(tester.element(find.text('Treść komunikatu:'))).pop();
    await tester.pumpAndSettle();
    state.shortenedTimestamp = true;
    await tester.tap(find.byTooltip('Odśwież'));
    await tester.pumpAndSettle();
    expect(
        find.text('Dane z ${app_date.formatDateDisplay(local)}, '
            '${app_date.formatTimeDisplay(local.hour, local.minute)}'),
        findsOneWidget);
    state.shortenedTimestamp = false;
    for (final missing in [null, 'invalid']) {
      state.generatedAt = missing;
      await tester.tap(find.byTooltip('Odśwież'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dane z'), findsNothing);
      expect(find.text('--:--'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
