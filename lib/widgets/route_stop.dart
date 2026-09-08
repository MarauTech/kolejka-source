import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/format_utils.dart';

/// One row in a continuous railway route: times, axis, station, platform.
class RouteStopWidget extends StatelessWidget {
  final String stationName;
  final StationOnRoute scheduleData;
  final OperationStation? realtimeData;
  final bool isFirst;
  final bool isLast;
  final bool isHighlighted;
  final bool isPassed;
  final bool hasTrainNow;
  final bool isBetweenNext;
  final int index;
  final bool isTrainAtPrevious;
  final String operatingDate;
  final String? notice;
  final bool startsVisibleRoute;
  final bool pulseSegment;
  final bool pulseStation;
  final bool isEstimatedPosition;
  final Animation<double>? pulseAnimation;

  const RouteStopWidget(
      {super.key,
      required this.stationName,
      required this.scheduleData,
      this.realtimeData,
      this.isFirst = false,
      this.isLast = false,
      this.isHighlighted = false,
      this.isPassed = false,
      this.hasTrainNow = false,
      this.isBetweenNext = false,
      this.isTrainAtPrevious = false,
      this.operatingDate = '',
      this.notice,
      this.startsVisibleRoute = false,
      this.pulseSegment = false,
      this.pulseStation = false,
      this.isEstimatedPosition = false,
      this.pulseAnimation,
      required this.index});

  bool _hasTime(String? planned, String? actual) =>
      app_date.formatTimeSafe(actual) != '--:--' ||
      app_date.formatTimeSafe(planned) != '--:--';

  Widget _time(bool arrival, ThemeData theme) {
    final planned = arrival
        ? realtimeData?.plannedArrival ?? scheduleData.arrivalTime
        : realtimeData?.plannedDeparture ?? scheduleData.departureTime;
    final actual =
        arrival ? realtimeData?.actualArrival : realtimeData?.actualDeparture;
    final reported = arrival
        ? realtimeData?.arrivalDelayMinutes
        : realtimeData?.departureDelayMinutes;
    final delay = app_date.timeDelay(planned, actual, reported,
        operatingDate: operatingDate,
        day: arrival ? scheduleData.arrivalDay : scheduleData.departureDay);
    final display = app_date.delayedTime(planned, actual, delay);
    final delayKnown = reported != null ||
        (app_date.parsePdpDateTime(actual) != null &&
            app_date.scheduleDateTime(planned, operatingDate,
                    day: arrival
                        ? scheduleData.arrivalDay
                        : scheduleData.departureDay) !=
                null);
    final suffix = delay >= 0 ? '+$delay' : '$delay';
    final color =
        delay > 0 ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final label = arrival ? 'Przyjazd' : 'Odjazd';
    return Semantics(
      label: delayKnown
          ? '$label $display, opóźnienie $delay minut'
          : '$label $display według rozkładu',
      child: Tooltip(
        message: '$label · Planowo ${app_date.formatTimeSafe(planned)}',
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(arrival ? 'Przyjazd' : 'Odjazd',
                style: TextStyle(
                    fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
            Text(display,
                key: ValueKey(
                    'route-time-$index-${arrival ? 'arrival' : 'departure'}'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            if (delayKnown && delay != 0) ...[
              Text(app_date.formatTimeSafe(planned),
                  style: TextStyle(
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant)),
              Text('$suffix min',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = hasTrainNow || isBetweenNext || isHighlighted;
    final foreground = theme.colorScheme.onSurface;
    final muted = theme.colorScheme.onSurfaceVariant;
    final primary = theme.brightness == Brightness.dark
        ? const Color(0xFF62CB91)
        : const Color(0xFF25804A);
    final normalLine = primary.withValues(alpha: 0.45);
    final pastLine = theme.colorScheme.outlineVariant;
    final topLine = isBetweenNext
        ? primary
        : isPassed
            ? pastLine
            : normalLine;
    final bottomLine = isTrainAtPrevious
        ? primary
        : isPassed
            ? pastLine
            : normalLine;
    final platform = formatPlatformTrack(
        realtimeData?.platform ??
            (isLast
                ? scheduleData.arrivalPlatform ?? scheduleData.departurePlatform
                : scheduleData.departurePlatform ??
                    scheduleData.arrivalPlatform),
        realtimeData?.track ??
            (isLast
                ? scheduleData.arrivalTrack ?? scheduleData.departureTrack
                : scheduleData.departureTrack ?? scheduleData.arrivalTrack),
        compact: false);
    final arrival = _hasTime(
        realtimeData?.plannedArrival ?? scheduleData.arrivalTime,
        realtimeData?.actualArrival);
    final departure = _hasTime(
        realtimeData?.plannedDeparture ?? scheduleData.departureTime,
        realtimeData?.actualDeparture);
    final showArrival = arrival && (!isFirst || !departure || isLast);
    final showDeparture = departure && (!isLast || !arrival);
    final stationActive = hasTrainNow || isHighlighted;
    final dotSize = stationActive ? 10.0 : 8.0;

    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
          width: 94,
          child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 3, bottom: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showArrival) _time(true, theme),
                    if (showDeparture) _time(false, theme),
                  ]))),
      _RouteAxis(
        key: ValueKey('route-axis-$index'),
        isFirst: isFirst,
        isLast: isLast,
        startsVisibleRoute: startsVisibleRoute,
        topLine: topLine,
        bottomLine: bottomLine,
        normalLine: normalLine,
        pastLine: pastLine,
        surface: theme.colorScheme.surface,
        activeColor: primary,
        active: stationActive,
        isPassed: isPassed,
        dotSize: dotSize,
        pulseSegment: pulseSegment,
        pulseStation: pulseStation,
        pulseIncoming: isBetweenNext,
        animation: pulseAnimation,
      ),
      Expanded(
          child: Container(
              padding: const EdgeInsets.only(top: 11, bottom: 12, left: 5),
              decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                              width: 0.5))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(stationName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14,
                                      height: 1.3,
                                      fontWeight: active || isLast
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? primary
                                          : isPassed
                                              ? muted
                                              : foreground))),
                          if (platform != null) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                                width: 84,
                                child: Text(platform,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 11,
                                        height: 1.6,
                                        color: muted))),
                          ],
                        ]),
                    if (hasTrainNow)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Pociąg na stacji',
                              style: TextStyle(fontSize: 11, color: primary))),
                    if ((hasTrainNow || isBetweenNext) && isEstimatedPosition)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Pozycja szacowana',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant))),
                    if (notice != null && notice!.trim().isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 8, right: 2),
                          child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 13, color: muted),
                                    const SizedBox(width: 5),
                                    Expanded(
                                        child: Text(notice!,
                                            style: TextStyle(
                                                fontSize: 11,
                                                height: 1.4,
                                                color: muted))),
                                  ]))),
                  ]))),
    ]));
  }
}

/// One geometry and one green palette for both halves of each connection.
/// The painter listens to animation directly; station rows do not rebuild.
class _RouteAxis extends StatelessWidget {
  final bool isFirst, isLast, startsVisibleRoute, active, isPassed;
  final bool pulseSegment, pulseStation, pulseIncoming;
  final Color topLine, bottomLine, normalLine, pastLine, surface, activeColor;
  final double dotSize;
  final Animation<double>? animation;

  const _RouteAxis({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.startsVisibleRoute,
    required this.topLine,
    required this.bottomLine,
    required this.normalLine,
    required this.pastLine,
    required this.surface,
    required this.activeColor,
    required this.active,
    required this.isPassed,
    required this.dotSize,
    required this.pulseSegment,
    required this.pulseStation,
    required this.pulseIncoming,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 24,
      child: RepaintBoundary(
          child: CustomPaint(
              painter: _RouteAxisPainter(
                  topVisible: !isFirst && !startsVisibleRoute,
                  bottomVisible: !isLast,
                  topLine: topLine,
                  bottomLine: bottomLine,
                  dotColor: active
                      ? activeColor
                      : isPassed
                          ? pastLine
                          : normalLine,
                  surface: surface,
                  green: activeColor,
                  active: active,
                  filled: active || isPassed,
                  dotSize: dotSize,
                  pulseTop: pulseIncoming,
                  pulseBottom: pulseSegment,
                  pulseDot: pulseStation,
                  animation: (pulseIncoming || pulseSegment || pulseStation)
                      ? animation
                      : null))));
}

class _RouteAxisPainter extends CustomPainter {
  final bool topVisible, bottomVisible, active, filled;
  final bool pulseTop, pulseBottom, pulseDot;
  final Color topLine, bottomLine, dotColor, surface, green;
  final double dotSize;
  final Animation<double>? animation;

  _RouteAxisPainter({
    required this.topVisible,
    required this.bottomVisible,
    required this.topLine,
    required this.bottomLine,
    required this.dotColor,
    required this.surface,
    required this.green,
    required this.active,
    required this.filled,
    required this.dotSize,
    required this.pulseTop,
    required this.pulseBottom,
    required this.pulseDot,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 21);
    final pulse = animation?.value ?? 0.5;
    void segment(Offset start, Offset end, Color color, bool highlighted) {
      if (highlighted) {
        canvas.drawLine(
            start,
            end,
            Paint()
              ..color = green.withValues(alpha: 0.08 + pulse * 0.10)
              ..strokeWidth = 7);
      }
      canvas.drawLine(
          start,
          end,
          Paint()
            ..color = color
            ..strokeWidth = 2.5);
    }

    if (topVisible) segment(Offset(center.dx, 0), center, topLine, pulseTop);
    if (bottomVisible) {
      segment(center, Offset(center.dx, size.height), bottomLine, pulseBottom);
    }
    if (active) {
      canvas.drawCircle(center, 8 + (pulseDot ? pulse : 0),
          Paint()..color = green.withValues(alpha: 0.15));
    }
    canvas.drawCircle(
        center, dotSize / 2, Paint()..color = filled ? dotColor : surface);
    canvas.drawCircle(
        center,
        dotSize / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = dotColor);
  }

  @override
  bool shouldRepaint(_RouteAxisPainter old) =>
      topVisible != old.topVisible ||
      bottomVisible != old.bottomVisible ||
      topLine != old.topLine ||
      bottomLine != old.bottomLine ||
      dotColor != old.dotColor ||
      surface != old.surface ||
      green != old.green ||
      active != old.active ||
      filled != old.filled ||
      dotSize != old.dotSize ||
      pulseTop != old.pulseTop ||
      pulseBottom != old.pulseBottom ||
      pulseDot != old.pulseDot ||
      animation != old.animation;
}
