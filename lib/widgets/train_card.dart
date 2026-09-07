import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/station_mapping.dart';
import '../utils/category_utils.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/format_utils.dart';
import 'train_type_icon.dart';

/// Compact connection row, sharing the visual rhythm of the station board.
class TrainCard extends StatelessWidget {
  final ConnectionResult connection;
  final VoidCallback onTap;
  const TrainCard({super.key, required this.connection, required this.onTap});
  Widget _time(String planned, String? actual, int delay, bool cancelled,
      {double fontSize = 17}) {
    final display = app_date.delayedTime(planned, actual, delay);
    final original = app_date.formatTimeSafe(planned);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(display,
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: delay > 0 || cancelled ? Colors.red : null)),
      if (display != original && original != '--:--')
        Text(original,
            style: const TextStyle(
                fontSize: 11, decoration: TextDecoration.lineThrough)),
    ]);
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
    final durationText = effectiveDuration.isNotEmpty
        ? '${hasRealtime ? 'Przewidywany' : 'Planowo'}: $effectiveDuration'
        : c.duration.isNotEmpty
            ? 'Planowo: ${c.duration}'
            : '';
    final statusText = cancelled
        ? 'Odwołany'
        : delay > 0
            ? app_date.formatDelay(delay)
            : hasRealtime
                ? 'Planowo'
                : 'Wg rozkładu';
    final statusColor = cancelled || delay > 0
        ? Colors.red
        : hasRealtime
            ? Colors.green
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
            TrainTypeIcon(category: category, size: 24, color: color),
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
                      fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ]);
    }

    return Material(
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.6))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 58,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                              label: 'Odjazd',
                              child: _time(c.departureTime,
                                  dep?.actualDeparture, depDelay, cancelled)),
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Icon(Icons.south,
                                  size: 11, color: theme.colorScheme.outline)),
                          Semantics(
                              label: 'Przyjazd',
                              child: _time(c.arrivalTime, arr?.actualArrival,
                                  arrDelay, cancelled,
                                  fontSize: 14)),
                        ])),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      identity(c),
                      const SizedBox(height: 6),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_forward,
                                size: 14, color: theme.colorScheme.outline),
                            const SizedBox(width: 5),
                            Expanded(
                                child: Text(c.toStationName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                          ]),
                      if (c.secondLeg != null) ...[
                        const SizedBox(height: 6),
                        Text('Przesiadka: ${lastLeg.fromStationName}',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        identity(lastLeg),
                      ],
                      const SizedBox(height: 6),
                      Text(statusText,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ])),
                Icon(Icons.chevron_right,
                    size: 16, color: theme.colorScheme.outline),
              ]),
              const SizedBox(height: 8),
              Text(
                  [
                    if (durationText.isNotEmpty) durationText,
                    c.isDirect
                        ? 'Bezpośredni'
                        : c.transfersCount == 1
                            ? '1 przesiadka'
                            : '${c.transfersCount} przesiadki',
                  ].join(' · '),
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              if (platform != null || arrivalPlatform != null)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 12, runSpacing: 3, children: [
                      if (platform != null)
                        Text('Odj. $platform',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant)),
                      if (arrivalPlatform != null)
                        Text('Przyj. $arrivalPlatform',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant)),
                    ])),
            ]),
          ),
        ));
  }
}
