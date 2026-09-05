import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;

class TrainCard extends StatelessWidget {
  final ConnectionResult connection;
  final VoidCallback onTap;

  const TrainCard({
    super.key,
    required this.connection,
    required this.onTap,
  });

  Widget _buildDelayBadge(int delay, bool isCancelled) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Text(
          'Odwołany',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    Color color;
    String text;
    if (delay == 0) {
      color = Colors.green.shade700;
      text = 'Planowo';
    } else if (delay <= 10) {
      color = Colors.orange.shade800;
      text = '+$delay min';
    } else {
      color = Colors.red.shade700;
      text = '+$delay min';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depTime = app_date.formatTimeSpan(connection.departureTime);
    final arrTime = app_date.formatTimeSpan(connection.arrivalTime);
    final duration = connection.duration;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Times and duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$depTime → $arrTime',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003366),
                        ),
                  ),
                  _buildDelayBadge(connection.delay, connection.isCancelled),
                ],
              ),
              const SizedBox(height: 6),

              // Stations
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${connection.fromStationName} → ${connection.toStationName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Train info & duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (connection.commercialCategory.isNotEmpty) connection.commercialCategory,
                        if (connection.trainNumber.isNotEmpty) connection.trainNumber,
                        if (connection.carrierName.isNotEmpty) connection.carrierName,
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (duration.isNotEmpty)
                    Text(
                      duration,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Badges: Direct / Transfer, Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: connection.isDirect ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      connection.isDirect ? 'Bezpośredni' : '1 przesiadka',
                      style: TextStyle(
                        color: connection.isDirect ? Colors.green.shade800 : Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (connection.trainStatusText.isNotEmpty)
                    Text(
                      connection.trainStatusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: connection.isCancelled ? Colors.red : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
