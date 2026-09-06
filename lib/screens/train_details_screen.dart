import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../widgets/route_stop.dart';
import '../utils/date_utils.dart' as app_date;

class TrainDetailsScreen extends StatefulWidget {
  final ConnectionResult result;

  const TrainDetailsScreen({
    super.key,
    required this.result,
  });

  @override
  State<TrainDetailsScreen> createState() => _TrainDetailsScreenState();
}

class _TrainDetailsScreenState extends State<TrainDetailsScreen> {
  Timer? _autoRefreshTimer;
  bool _isLoading = false;
  TrainOperation? _operation;
  TrainRoute? _fullRoute;

  @override
  void initState() {
    super.initState();
    _operation = widget.result.operation;
    _fullRoute = widget.result.route;
    _fetchData();

    // Auto-refresh once per 60 seconds if train is in progress
    if (widget.result.trainStatus == 'P') {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _fetchData();
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final appState = context.read<AppState>();
    final operatingDate = widget.result.operatingDate.isNotEmpty
        ? widget.result.operatingDate
        : app_date.formatDateForApi(DateTime.now());

    try {
      // 1. Fetch full route if stations are missing or empty
      if (_fullRoute == null || _fullRoute!.stations.isEmpty) {
        try {
          final routeResp = await appState.api.getScheduleRoute(
            widget.result.route.scheduleId,
            widget.result.route.orderId,
          );
          if (routeResp.isNotEmpty && mounted) {
            setState(() {
              _fullRoute = TrainRoute.fromJson(routeResp);
            });
          }
        } catch (e) {
          debugPrint('[TrainDetails] Error fetching route: $e');
        }
      }

      // 2. Fetch realtime operations
      final updatedOp = await appState.getTrainOperation(
        widget.result.route.scheduleId,
        widget.result.route.orderId,
        operatingDate,
      );

      if (mounted && updatedOp != null) {
        setState(() {
          _operation = updatedOp;
        });
      }
    } catch (e) {
      debugPrint('[TrainDetails] Error fetching realtime: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDelayBadge(int delay, bool isCancelled) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red),
        ),
        child: const Text('Odwołany',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      );
    }

    Color color;
    String text;
    if (delay == 0) {
      color = Colors.green;
      text = 'Planowo';
    } else if (delay <= 10) {
      color = Colors.orange.shade800;
      text = '+$delay min';
    } else {
      color = Colors.red;
      text = '+$delay min';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final route = _fullRoute ?? widget.result.route;

    // Real-time map by stationId
    final Map<int, OperationStation> opStationsMap = {};
    if (_operation != null) {
      for (final st in _operation!.stations) {
        opStationsMap[st.stationId] = st;
      }
    }

    // Determine current delay
    int currentDelay = widget.result.delay;
    if (_operation != null) {
      for (final st in _operation!.stations) {
        final d = st.departureDelayMinutes ?? st.arrivalDelayMinutes ?? 0;
        if (d > currentDelay) currentDelay = d;
      }
    }

    final isCancelled =
        _operation?.trainStatus == 'X' || widget.result.isCancelled;

    // Compute live train position
    final positionInfo = TrainPositionInfo.compute(
      operation: _operation,
      routeStations: route.stations,
      stationNames: appState.stationNames,
    );

    // Identify user segment indices if available
    int userFromIdx = -1;
    int userToIdx = -1;
    for (int i = 0; i < route.stations.length; i++) {
      if (route.stations[i].stationId == widget.result.fromStationId &&
          userFromIdx == -1) {
        userFromIdx = i;
      }
      if (route.stations[i].stationId == widget.result.toStationId &&
          userToIdx == -1) {
        userToIdx = i;
      }
    }
    final hasUserSegment =
        userFromIdx != -1 && userToIdx != -1 && userFromIdx < userToIdx;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            if (widget.result.commercialCategory.isNotEmpty)
              widget.result.commercialCategory,
            if (widget.result.trainNumber.isNotEmpty) widget.result.trainNumber,
            if (widget.result.trainName.isNotEmpty)
              '"${widget.result.trainName}"',
          ].join(' '),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchData,
            tooltip: 'Odśwież dane trasy',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Train Header Card
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.result.carrierName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildDelayBadge(currentDelay, isCancelled),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Relacja: ${widget.result.relationStart} - ${widget.result.relationEnd}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.result.operatingDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Data kursowania: ${widget.result.operatingDate}',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Live Position Banner
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.directions_train,
                                size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bieżące położenie',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    positionInfo.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Segment hint if applicable
              if (hasUserSegment)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Twój odcinek: ${widget.result.fromStationName} - ${widget.result.toStationName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Route Timeline
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Pełna trasa pociągu (${route.stations.length} stacji)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: List.generate(route.stations.length, (index) {
                      final stop = route.stations[index];
                      final stationName =
                          appState.getStationName(stop.stationId);
                      final realTimeStop = opStationsMap[stop.stationId];

                      final isUserSegment = hasUserSegment &&
                          (index >= userFromIdx && index <= userToIdx);
                      final isPassed = realTimeStop?.actualDeparture != null;
                      final hasTrainNow =
                          positionInfo.type == TrainStatusType.atStation &&
                              positionInfo.currentStationId == stop.stationId;
                      final isBetweenNext = positionInfo.type ==
                              TrainStatusType.betweenStations &&
                          positionInfo.currentStationId == stop.stationId;

                      return RouteStopWidget(
                        stationName: stationName,
                        scheduleData: stop,
                        realtimeData: realTimeStop,
                        isFirst: index == 0,
                        isLast: index == route.stations.length - 1,
                        isHighlighted: isUserSegment,
                        isPassed: isPassed,
                        hasTrainNow: hasTrainNow,
                        isBetweenNext: isBetweenNext,
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Technical Details Expansion Tile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: const Text(
                      'Szczegóły techniczne',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Schedule ID: ${route.scheduleId}, Order ID: ${route.orderId}',
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Identyfikator rozkładu: ${route.scheduleId}',
                                style: const TextStyle(fontSize: 12)),
                            Text('Identyfikator zamówienia: ${route.orderId}',
                                style: const TextStyle(fontSize: 12)),
                            if (route.trainOrderId != null)
                              Text(
                                  'Identyfikator pociągu: ${route.trainOrderId}',
                                  style: const TextStyle(fontSize: 12)),
                            if (_operation?.trainOrderId != null)
                              Text(
                                  'Train Order ID wykonania: ${_operation!.trainOrderId}',
                                  style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),
                            const Text('Surowy JSON z API:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                const JsonEncoder.withIndent('  ').convert({
                                  'route': route.raw,
                                  if (_operation != null)
                                    'operation': _operation!.raw,
                                }),
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
