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
    final color = delay > 0 ? Colors.red : theme.colorScheme.onSurface;
    final label = arrival ? 'Przyjazd' : 'Odjazd';
    return Semantics(
      label: delayKnown
          ? '$label $display, opóźnienie $delay minut'
          : '$label $display według rozkładu',
      child: Tooltip(
        message: '$label · Planowo ${app_date.formatTimeSafe(planned)}',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(arrival ? 'Prz.' : 'Odj.',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 3),
                    Text(display,
                        key: ValueKey(
                            'route-time-$index-${arrival ? 'arrival' : 'departure'}'),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                    if (delayKnown) ...[
                      const SizedBox(width: 4),
                      Text(suffix,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: delay > 0
                                  ? Colors.red
                                  : theme.brightness == Brightness.dark
                                      ? const Color(0xFF83C998)
                                      : const Color(0xFF26743D))),
                    ],
                  ])),
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
    final primary = theme.colorScheme.primary;
    final normalLine = theme.colorScheme.outline;
    final pastLine = theme.colorScheme.outlineVariant;
    final topLine = isBetweenNext
        ? primary
        : isPassed
            ? pastLine
            : normalLine;
    final bottomLine = (hasTrainNow || isTrainAtPrevious)
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
    final dotSize = active ? 9.0 : 7.0;

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
      SizedBox(
          width: 20,
          key: ValueKey('route-axis-$index'),
          child: Stack(alignment: Alignment.topCenter, children: [
            if (!isFirst && !startsVisibleRoute)
              Positioned(
                  top: 0,
                  height: 21,
                  child: Container(width: 1.5, color: topLine)),
            if (!isLast)
              Positioned(
                  top: 21,
                  bottom: 0,
                  child: Container(width: 1.5, color: bottomLine)),
            Positioned(
                top: 21 - dotSize / 2,
                child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? primary : theme.colorScheme.surface,
                        border: Border.all(
                            color: active
                                ? primary
                                : isPassed
                                    ? pastLine
                                    : normalLine,
                            width: 1.5)))),
          ])),
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
