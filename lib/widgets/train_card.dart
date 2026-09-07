import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/station_mapping.dart';
import '../utils/category_utils.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/format_utils.dart';

/// Compact connection row, sharing the visual rhythm of the station board.
class TrainCard extends StatelessWidget {
  final ConnectionResult connection;
  final VoidCallback onTap;
  const TrainCard({super.key, required this.connection, required this.onTap});
  Widget _time(String planned, String? actual, int delay, bool cancelled) {
    final display = app_date.delayedTime(planned, actual, delay);
    final original = app_date.formatTimeSafe(planned);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(display,
          style: TextStyle(
              fontSize: 20,
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
        dep?.track ?? c.fromStop.departureTrack);
    final arrivalPlatform = formatPlatformTrack(
        arr?.platform ?? lastLeg.toStop.arrivalPlatform,
        arr?.track ?? lastLeg.toStop.arrivalTrack);
    final cat = c.route.commercialCategorySymbol ?? c.commercialCategory;
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
    return Material(
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.6))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _time(c.departureTime, dep?.actualDeparture, depDelay,
                        cancelled),
                    const Icon(Icons.arrow_forward, size: 16),
                    _time(
                        c.arrivalTime, arr?.actualArrival, arrDelay, cancelled),
                    Text(statusText,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ]),
              const SizedBox(height: 5),
              Text('${c.fromStationName} \u2192 ${c.toStationName}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (cat.isNotEmpty)
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: categoryColor(cat, isDark: dark),
                              borderRadius: BorderRadius.circular(3)),
                          child: Text(cat,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      categoryTextColor(cat, isDark: dark)))),
                    Text(c.route.nationalNumber ?? c.trainNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    if (c.trainName.isNotEmpty)
                      Text(c.trainName, style: const TextStyle(fontSize: 12)),
                  ]),
              const SizedBox(height: 4),
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
              if (c.secondLeg != null)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 6, children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          color: categoryColor(
                              lastLeg.route.commercialCategorySymbol ??
                                  lastLeg.commercialCategory,
                              isDark: dark),
                          child: Text(
                              lastLeg.route.commercialCategorySymbol ??
                                  lastLeg.commercialCategory,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: categoryTextColor(
                                      lastLeg.route.commercialCategorySymbol ??
                                          lastLeg.commercialCategory,
                                      isDark: dark)))),
                      Text(lastLeg.route.nationalNumber ?? lastLeg.trainNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      if (lastLeg.trainName.isNotEmpty)
                        Text(lastLeg.trainName,
                            style: const TextStyle(fontSize: 12)),
                    ])),
              if (platform != null)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 4, children: [
                      const Text('Odjazd:', style: TextStyle(fontSize: 11)),
                      Text(platform, style: const TextStyle(fontSize: 11))
                    ])),
              if (arrivalPlatform != null)
                Wrap(spacing: 4, children: [
                  const Text('Przyjazd:', style: TextStyle(fontSize: 11)),
                  Text(arrivalPlatform, style: const TextStyle(fontSize: 11))
                ]),
            ]),
          ),
        ));
  }
}
