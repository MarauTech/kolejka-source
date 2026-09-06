import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;

class RouteStopWidget extends StatelessWidget {
  final String stationName;
  final StationOnRoute scheduleData;
  final OperationStation? realtimeData;
  final bool isFirst;
  final bool isLast;
  final bool isHighlighted; // User's travel segment (from/to)
  final bool isPassed; // Already departed
  final bool hasTrainNow; // Train currently at this station
  final bool isBetweenNext; // Train currently between this stop and next

  const RouteStopWidget({
    super.key,
    required this.stationName,
    required this.scheduleData,
    this.realtimeData,
    this.isFirst = false,
    this.isLast = false,
    this.isHighlighted = false,
    this.isPassed = false,
    this.hasTrainNow = false,
    this.isBetweenNext = false,
  });

  Widget _buildDelay(int? delay) {
    if (delay == null || delay == 0) {
      return const Text(
        'Planowo',
        style: TextStyle(
            color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
      );
    }
    if (delay <= 10) {
      return Text(
        '+$delay min',
        style: const TextStyle(
            color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
      );
    }
    return Text(
      '+$delay min',
      style: const TextStyle(
          color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final arrTime = scheduleData.arrivalTime != null
        ? app_date.formatTimeSpan(scheduleData.arrivalTime!)
        : '-';
    final depTime = scheduleData.departureTime != null
        ? app_date.formatTimeSpan(scheduleData.departureTime!)
        : '-';

    final realArrTime = realtimeData?.actualArrival != null
        ? app_date.formatDateTime(realtimeData!.actualArrival!)
        : arrTime;
    final realDepTime = realtimeData?.actualDeparture != null
        ? app_date.formatDateTime(realtimeData!.actualDeparture!)
        : depTime;

    final isCancelled = realtimeData?.isCancelled ?? false;
    final stopType = scheduleData.stopTypeName ?? '';

    // Platform and track
    final platform = realtimeData?.platform ??
        scheduleData.arrivalPlatform ??
        scheduleData.departurePlatform;
    final track = realtimeData?.track ??
        scheduleData.arrivalTrack ??
        scheduleData.departureTrack;

    Color timelineColor = isPassed
        ? theme.colorScheme.outlineVariant
        : (isHighlighted ? primaryColor : theme.colorScheme.outline);

    Color dotColor = isCancelled
        ? Colors.red
        : (hasTrainNow
            ? primaryColor
            : (isPassed
                ? theme.colorScheme.outlineVariant
                : (isHighlighted || isFirst || isLast
                    ? primaryColor
                    : theme.colorScheme.secondary)));

    return Container(
      color: isHighlighted
          ? primaryColor.withValues(alpha: 0.08)
          : (hasTrainNow
              ? primaryColor.withValues(alpha: 0.04)
              : Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline track column
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isFirst ? Colors.transparent : timelineColor,
                    ),
                  ),
                  if (hasTrainNow)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.train,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  else
                    Container(
                      width: isHighlighted ? 18 : 14,
                      height: isHighlighted ? 18 : 14,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isPassed ? theme.colorScheme.surface : dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dotColor,
                          width: isPassed ? 2.5 : 2,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 3,
                          color: isLast
                              ? Colors.transparent
                              : (isPassed
                                  ? theme.colorScheme.outlineVariant
                                  : timelineColor),
                        ),
                        if (isBetweenNext)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_downward,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Station details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Station Name & Platform info
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stationName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isHighlighted
                                  ? FontWeight.bold
                                  : ((isFirst || isLast || hasTrainNow)
                                      ? FontWeight.bold
                                      : FontWeight.w600),
                              color: isPassed
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45)
                                  : (isHighlighted
                                      ? primaryColor
                                      : theme.colorScheme.onSurface),
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (platform != null && platform.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Peron $platform${(track != null && track.isNotEmpty) ? ' / Tor $track' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (hasTrainNow)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 13, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Pociąg aktualnie na stacji',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isBetweenNext)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_train,
                                size: 13, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Pociąg w drodze do następnej stacji',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (stopType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        stopType,
                        style: TextStyle(
                          color: isPassed
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.35)
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],

                    if (isCancelled)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Postój odwołany',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Arrival Time row
                    if (!isFirst && scheduleData.arrivalTime != null)
                      Row(
                        children: [
                          SizedBox(
                            width: 62,
                            child: Text(
                              'Przyjazd:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isPassed
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.35)
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ),
                          Text(
                            arrTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: isPassed
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45)
                                  : theme.colorScheme.onSurface,
                              decoration:
                                  (arrTime != realArrTime && realArrTime != '-')
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                          if (arrTime != realArrTime && realArrTime != '-') ...[
                            const SizedBox(width: 6),
                            Text(
                              realArrTime,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPassed
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          if (!isPassed)
                            _buildDelay(realtimeData?.arrivalDelayMinutes),
                        ],
                      ),

                    // Departure Time row
                    if (!isLast && scheduleData.departureTime != null)
                      Padding(
                        padding: EdgeInsets.only(
                            top: (!isFirst && scheduleData.arrivalTime != null)
                                ? 4.0
                                : 0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 62,
                              child: Text(
                                'Odjazd:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPassed
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.35)
                                      : theme.colorScheme.outline,
                                ),
                              ),
                            ),
                            Text(
                              depTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: isPassed
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45)
                                    : theme.colorScheme.onSurface,
                                decoration: (depTime != realDepTime &&
                                        realDepTime != '-')
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (depTime != realDepTime &&
                                realDepTime != '-') ...[
                              const SizedBox(width: 6),
                              Text(
                                realDepTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPassed
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            if (!isPassed)
                              _buildDelay(realtimeData?.departureDelayMinutes),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
