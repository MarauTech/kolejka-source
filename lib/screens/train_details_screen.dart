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

  @override
  void initState() {
    super.initState();
    _operation = widget.result.operation;
    _fetchRealtimeData();

    // Auto-refresh once per 60 seconds if train is in progress
    if (widget.result.trainStatus == 'P') {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _fetchRealtimeData();
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRealtimeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final appState = context.read<AppState>();
    final operatingDate = widget.result.operatingDate.isNotEmpty
        ? widget.result.operatingDate
        : app_date.formatDateForApi(DateTime.now());

    try {
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final route = widget.result.route;

    // Build real-time map by stationId for fast lookup
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

    final isCancelled = _operation?.trainStatus == 'X' || widget.result.isCancelled;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            if (widget.result.commercialCategory.isNotEmpty) widget.result.commercialCategory,
            if (widget.result.trainNumber.isNotEmpty) widget.result.trainNumber,
            if (widget.result.trainName.isNotEmpty) '"${widget.result.trainName}"',
          ].join(' '),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchRealtimeData,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRealtimeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.result.carrierName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          _buildDelayBadge(currentDelay, isCancelled),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Relacja: ${widget.result.fromStationName} → ${widget.result.toStationName}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Status: ${_operation?.statusText ?? widget.result.trainStatusText}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isCancelled ? Colors.red : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Route Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Pełna trasa pociągu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003366),
                      ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: List.generate(route.stations.length, (index) {
                      final stop = route.stations[index];
                      final stationName = appState.getStationName(stop.stationId);
                      final realTimeStop = opStationsMap[stop.stationId];
                      final isHighlight = stop.stationId == widget.result.fromStationId ||
                          stop.stationId == widget.result.toStationId;

                      return RouteStopWidget(
                        stationName: stationName,
                        scheduleData: stop,
                        realtimeData: realTimeStop,
                        isFirst: index == 0,
                        isLast: index == route.stations.length - 1,
                        isHighlighted: isHighlight,
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Raw JSON Data Expansion Tile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: const Text(
                      'Pełne dane API',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Oryginalna odpowiedź JSON z PKP PLK API',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey.shade100,
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert({
                            'route': route.raw,
                            if (_operation != null) 'operation': _operation!.raw,
                          }),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
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

  Widget _buildDelayBadge(int delay, bool isCancelled) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red),
        ),
        child: const Text('Odwołany', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      );
    }

    Color color;
    String text;
    if (delay == 0) {
      color = Colors.green;
      text = 'Planowo';
    } else if (delay <= 10) {
      color = Colors.orange;
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
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
