import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/widgets/route_stop.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'Current route connector stays green across unequal station rows; dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      Widget stop(int index) => RouteStopWidget(
          index: index,
          stationName: index == 0 ? 'Brzeg' : 'Opole Główne',
          scheduleData: StationOnRoute(
              stationId: index + 1,
              orderNumber: index + 1,
              arrivalTime: '19:46',
              departureTime: '19:47',
              raw: {}),
          isFirst: index == 0,
          isLast: index == 1,
          isPassed: index == 0,
          isTrainAtPrevious: index == 0,
          isBetweenNext: index == 1,
          pulseSegment: index == 0,
          isEstimatedPosition: true,
          pulseAnimation: const AlwaysStoppedAnimation(0.5),
          notice: index == 0
              ? 'Dłuższa informacja o tym przystanku zwiększa wysokość wiersza.'
              : null);
      await tester.pumpWidget(MaterialApp(
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          home: Scaffold(
              body: RepaintBoundary(
                  key: boundaryKey,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [stop(0), stop(1)])))));
      await tester.pump();
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final origin = tester.getTopLeft(find.byKey(boundaryKey));
      final firstAxis = find.byKey(const ValueKey('route-axis-0'));
      final nextAxis = find.byKey(const ValueKey('route-axis-1'));
      final x = (tester.getCenter(firstAxis).dx - origin.dx).floor();
      final join = (tester.getBottomLeft(firstAxis).dy - origin.dy).floor();
      expect(
          tester.getTopLeft(nextAxis).dy, tester.getBottomLeft(firstAxis).dy);
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        for (final y in [join - 5, join - 1, join, join + 1, join + 5]) {
          final pixel = (y * image.width + x) * 4;
          final red = data.getUint8(pixel),
              green = data.getUint8(pixel + 1),
              blue = data.getUint8(pixel + 2);
          expect(green, greaterThan(red + 20),
              reason: 'Connector at row boundary y=$y');
          expect(green, greaterThan(blue + 20),
              reason:
                  'Connector must remain green, including estimated positions');
        }
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }
}
