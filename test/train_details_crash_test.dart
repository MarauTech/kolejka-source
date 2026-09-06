import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/screens/train_details_screen.dart';
import 'package:trainly/widgets/route_stop.dart';
import 'fixtures.dart';

void main() {
  for (final width in [320.0, 360.0, 384.0, 411.0]) {
    for (final shortTimes in [false, true]) {
      testWidgets(
          'Whole TrainDetailsScreen: 16 planned / 9 reordered operations, next index 11, width $width, short times $shortTimes',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final result = connectionFixture(shortTimes: shortTimes);
        final state = FixtureState()..updatedOperation = result.operation;
        state.stationNames = {
          for (final stop in result.route.stations)
            stop.stationId: 'Stacja ${stop.stationId}'
        };
        await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
                theme: ThemeData.dark(),
                home: TrainDetailsScreen(
                    result: result, now: () => DateTime(2026, 9, 6, 10, 21)))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(find.text('W drodze do: Stacja 1011'), findsOneWidget);
        expect(find.byType(RouteStopWidget), findsNWidgets(6));
        final expand = find.text('Pokaż poprzednie stacje (10)');
        expect(expand, findsOneWidget);
        await tester.ensureVisible(expand);
        await tester.tap(expand);
        await tester.pumpAndSettle();
        expect(find.byType(RouteStopWidget), findsNWidgets(16));
        expect(find.text('Per. IV/3'), findsWidgets);
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -1800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      });
    }
    testWidgets('Unknown position shows full route at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = FixtureState();
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
              home: TrainDetailsScreen(
                  result: connectionFixture(noPosition: true),
                  now: () => DateTime(2026, 9, 6, 10, 21)))));
      await tester.pumpAndSettle();
      expect(find.byType(RouteStopWidget), findsNWidgets(16));
      expect(find.textContaining('Pokaż poprzednie'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
