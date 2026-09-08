import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/station_mapping.dart';
import '../utils/category_utils.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/format_utils.dart';
import 'train_type_icon.dart';

/// A compact journey timeline with equally prominent departure and arrival.
class TrainCard extends StatelessWidget {
  final ConnectionResult connection;
  final VoidCallback onTap;
  const TrainCard({super.key, required this.connection, required this.onTap});
  Widget _time(BuildContext context, String label, String planned,
      String? actual, int delay, bool cancelled,
      {bool alignRight = false}) {
    final display = app_date.delayedTime(planned, actual, delay);
    final original = app_date.formatTimeSafe(planned);
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
        label: label,
        child: Column(
            crossAxisAlignment:
                alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(display,
                  style: TextStyle(
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: delay > 0 || cancelled
                          ? Theme.of(context).colorScheme.error
                          : null)),
              if (display != original && original != '--:--')
                Text(original,
                    style: TextStyle(
                        fontSize: 11,
                        color: secondary,
                        decoration: TextDecoration.lineThrough)),
            ]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final c = connection;
    final dep = operationForStop(
        c.fromStop, c.route.stations, c.operation?.stations ?? []);
    final lastLeg = c.secondLeg ?? c;
    final arr = operationForStop(lastLeg.toStop, lastLeg.route.stations,
        lastLeg.operation?.stations ?? []);
    final depDelay = app_date.timeDelay(
        dep?.plannedDeparture ?? c.departureTime,
        dep?.actualDeparture,
        dep?.departureDelayMinutes,
        operatingDate: c.operatingDate.isNotEmpty
            ? c.operatingDate
            : c.operation?.operatingDate ?? '',
        day: c.fromStop.departureDay);
    final arrDelay = app_date.timeDelay(arr?.plannedArrival ?? c.arrivalTime,
        arr?.actualArrival, arr?.arrivalDelayMinutes,
        operatingDate: lastLeg.operatingDate.isNotEmpty
            ? lastLeg.operatingDate
            : lastLeg.operation?.operatingDate ?? '',
        day: lastLeg.toStop.arrivalDay);
    final delay = depDelay > arrDelay ? depDelay : arrDelay;
    final cancelled = c.isCancelled || lastLeg.isCancelled;
    final hasRealtime = dep?.departureDelayMinutes != null ||
        dep?.actualDeparture != null ||
        arr?.arrivalDelayMinutes != null ||
        arr?.actualArrival != null;
    final platform = formatPlatformTrack(
        dep?.platform ?? c.fromStop.departurePlatform,
        dep?.track ?? c.fromStop.departureTrack,
        compact: true);
    final arrivalPlatform = formatPlatformTrack(
        arr?.platform ?? lastLeg.toStop.arrivalPlatform,
        arr?.track ?? lastLeg.toStop.arrivalTrack,
        compact: true);
    final operatingDate = c.operatingDate.isNotEmpty
        ? c.operatingDate
        : c.operation?.operatingDate ?? '';
    final effectiveDuration = app_date.effectiveTravelTime(
      plannedDeparture: dep?.plannedDeparture ?? c.departureTime,
      plannedArrival: arr?.plannedArrival ?? c.arrivalTime,
      actualDeparture: dep?.actualDeparture,
      actualArrival: arr?.actualArrival,
      departureDelay: depDelay,
      arrivalDelay: arrDelay,
      operatingDate: operatingDate,
      departureDay: c.fromStop.departureDay,
      arrivalDay: lastLeg.toStop.arrivalDay,
    );
    final durationText =
        effectiveDuration.isNotEmpty ? effectiveDuration : c.duration;
    final durationDescription =
        '${hasRealtime ? 'Przewidywany czas podróży' : 'Rozkładowy czas podróży'}: $durationText';
    final connectionType = c.isDirect
        ? 'Bezpośredni'
        : c.transfersCount == 1
            ? '1 przesiadka'
            : '${c.transfersCount} przesiadki';
    final statusText = cancelled
        ? 'Odwołany'
        : delay > 0
            ? app_date.formatDelay(delay)
            : hasRealtime
                ? app_date.formatDelay(delay)
                : 'Wg rozkładu';
    final statusColor = cancelled || delay > 0
        ? theme.colorScheme.error
        : hasRealtime
            ? dark
                ? const Color(0xFF83C998)
                : const Color(0xFF26743D)
            : theme.colorScheme.onSurfaceVariant;
    Widget identity(ConnectionResult leg) {
      final category =
          leg.route.commercialCategorySymbol ?? leg.commercialCategory;
      final color = categoryColor(category, isDark: dark);
      return Wrap(
          spacing: 6,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TrainTypeIcon(category: category, size: 20, color: color),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)),
              child: DefaultTextStyle(
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: theme.textTheme.bodySmall?.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: categoryTextColor(category, isDark: dark)),
                child: Wrap(spacing: 4, children: [
                  if (category.isNotEmpty) Text(category),
                  Text(leg.route.nationalNumber ?? leg.trainNumber),
                ]),
              ),
            ),
            if (leg.trainName.isNotEmpty)
              Text(leg.trainName,
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ]);
    }

    Widget duration() => Tooltip(
        message: durationDescription,
        child: Semantics(
            label: durationDescription,
            excludeSemantics: true,
            child: Text(durationText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600))));

    final secondaryStyle =
        TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant);
    return Material(
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.6))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: identity(c)),
                const SizedBox(width: 8),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(statusText,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor)))),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 16, color: theme.colorScheme.outline),
              ]),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final inlineDuration =
                    !largeText && constraints.maxWidth >= 264;
                return Column(children: [
                  ExcludeSemantics(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Expanded(child: Text('Odjazd', style: secondaryStyle)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Przyjazd',
                                textAlign: TextAlign.end,
                                style: secondaryStyle)),
                      ])),
                  const SizedBox(height: 2),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        flex: 3,
                        child: _time(context, 'Odjazd', c.departureTime,
                            dep?.actualDeparture, depDelay, cancelled)),
                    if (inlineDuration)
                      Expanded(
                          flex: 4,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(children: [
                                if (durationText.isNotEmpty) duration(),
                                Row(children: [
                                  Expanded(
                                      child: Divider(
                                          color: theme
                                              .colorScheme.outlineVariant)),
                                  Icon(Icons.arrow_forward,
                                      size: 14,
                                      color: theme.colorScheme.outline),
                                ]),
                                Text(connectionType,
                                    textAlign: TextAlign.center,
                                    style: secondaryStyle),
                              ])))
                    else
                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: Icon(Icons.arrow_forward,
                              size: 18, color: theme.colorScheme.outline)),
                    Expanded(
                        flex: 3,
                        child: _time(context, 'Przyjazd', c.arrivalTime,
                            arr?.actualArrival, arrDelay, cancelled,
                            alignRight: true)),
                  ]),
                  if (!inlineDuration)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (durationText.isNotEmpty) duration(),
                              Text(connectionType, style: secondaryStyle),
                            ])),
                ]);
              }),
              if (platform != null || arrivalPlatform != null)
                Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(
                                  platform != null ? 'Odj. $platform' : '',
                                  style: secondaryStyle)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  arrivalPlatform != null
                                      ? 'Przyj. $arrivalPlatform'
                                      : '',
                                  textAlign: TextAlign.end,
                                  style: secondaryStyle)),
                        ])),
              if (c.secondLeg != null) ...[
                const SizedBox(height: 10),
                Text('Przesiadka: ${lastLeg.fromStationName}',
                    style: secondaryStyle),
                const SizedBox(height: 5),
                identity(lastLeg),
              ],
            ]),
          ),
        ));
  }
}
