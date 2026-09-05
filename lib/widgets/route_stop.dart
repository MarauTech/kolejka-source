import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;

class RouteStopWidget extends StatelessWidget {
  final String stationName;
  final StationOnRoute scheduleData;
  final OperationStation? realtimeData;
  final bool isFirst;
  final bool isLast;
  final bool isHighlighted;

  const RouteStopWidget({
    super.key,
    required this.stationName,
    required this.scheduleData,
    this.realtimeData,
    this.isFirst = false,
    this.isLast = false,
    this.isHighlighted = false,
  });

  Widget _buildDelay(int? delay) {
    if (delay == null || delay == 0) {
      return const Text('Planowo', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600));
    }
    if (delay <= 10) {
      return Text('+$delay min', style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600));
    }
    return Text('+$delay min', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600));
  }

  @override
  Widget build(BuildContext context) {
    final arrTime = scheduleData.arrivalTime != null ? app_date.formatTimeSpan(scheduleData.arrivalTime!) : '-';
    final depTime = scheduleData.departureTime != null ? app_date.formatTimeSpan(scheduleData.departureTime!) : '-';

    final realArrTime = realtimeData?.actualArrival != null
        ? app_date.formatDateTime(realtimeData!.actualArrival!)
        : arrTime;
    final realDepTime = realtimeData?.actualDeparture != null
        ? app_date.formatDateTime(realtimeData!.actualDeparture!)
        : depTime;

    final isCancelled = realtimeData?.isCancelled ?? false;
    final stopType = scheduleData.stopTypeName ?? '';

    return Container(
      color: isHighlighted ? const Color(0xFF003366).withValues(alpha: 0.06) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isFirst ? Colors.transparent : Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    width: isHighlighted ? 18 : 14,
                    height: isHighlighted ? 18 : 14,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red
                          : (isHighlighted
                              ? const Color(0xFF003366)
                              : (isFirst || isLast ? const Color(0xFF003366) : Colors.grey.shade400)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isLast ? Colors.transparent : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stationName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isHighlighted
                                  ? FontWeight.bold
                                  : ((isFirst || isLast) ? FontWeight.bold : FontWeight.w600),
                              color: isHighlighted ? const Color(0xFF003366) : Colors.black87,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (scheduleData.arrivalPlatform != null)
                          Text(
                            'Per. ${scheduleData.arrivalPlatform}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                    if (stopType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        stopType,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                    if (isCancelled)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Przystanek odwołany',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (!isFirst && scheduleData.arrivalTime != null)
                      Row(
                        children: [
                          const SizedBox(
                            width: 60,
                            child: Text('Przyjazd:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                          Text(
                            arrTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              decoration: (arrTime != realArrTime && realArrTime != '-') ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (arrTime != realArrTime && realArrTime != '-') ...[
                            const SizedBox(width: 6),
                            Text(realArrTime, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                          const SizedBox(width: 8),
                          _buildDelay(realtimeData?.arrivalDelayMinutes),
                        ],
                      ),
                    if (!isLast && scheduleData.departureTime != null)
                      Padding(
                        padding: EdgeInsets.only(top: (!isFirst && scheduleData.arrivalTime != null) ? 4.0 : 0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 60,
                              child: Text('Odjazd:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                            Text(
                              depTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                decoration: (depTime != realDepTime && realDepTime != '-') ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (depTime != realDepTime && realDepTime != '-') ...[
                              const SizedBox(width: 6),
                              Text(realDepTime, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                            const SizedBox(width: 8),
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
