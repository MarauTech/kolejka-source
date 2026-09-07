import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../models/train_position_resolver.dart';
import '../models/station_mapping.dart';
import '../models/route_presentation.dart';
import '../utils/category_utils.dart';
import '../widgets/train_type_icon.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/route_stop.dart';

class TrainDetailsScreen extends StatefulWidget {
  final ConnectionResult result;
  final DateTime Function()? now;

  const TrainDetailsScreen({
    super.key,
    required this.result,
    this.now,
  });

  @override
  State<TrainDetailsScreen> createState() => _TrainDetailsScreenState();
}

class _TrainDetailsScreenState extends State<TrainDetailsScreen>
    with SingleTickerProviderStateMixin {
  Timer? _autoRefreshTimer;
  late final AnimationController _positionPulse;
  late final Animation<double> _positionPulseCurve;
  bool _isLoading = false;
  bool _routeLoadError = false;
  TrainOperation? _operation;
  TrainRoute? _fullRoute;
  bool _showPreviousStations = false; // State for collapsible past stations

  @override
  void initState() {
    super.initState();
    _positionPulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _positionPulseCurve =
        CurvedAnimation(parent: _positionPulse, curve: Curves.easeInOut);
    final initialOperation = widget.result.operation;
    _operation = initialOperation != null &&
            operationMatchesRoute(
                initialOperation, widget.result.route, _operatingDate)
        ? initialOperation
        : null;
    _fullRoute = widget.result.route;
    if (_fullRoute!.stations.isEmpty) {
      _fullRoute = null; // force fetch if empty
    }
    _fetchData();

    if (widget.result.trainStatus == 'P') {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _fetchData();
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _positionPulse.dispose();
    super.dispose();
  }

  String _getShortCarrierName(String? rawName) {
    if (rawName == null) return '';
    if (rawName.contains('PKP Intercity')) return 'PKP Intercity';
    if (rawName.contains('POLREGIO')) return 'POLREGIO';
    if (rawName.contains('Koleje Mazowieckie')) return 'Koleje Mazowieckie';
    if (rawName.contains('Koleje Wielkopolskie')) return 'Koleje Wielkopolskie';
    if (rawName.contains('Koleje \u015al\u0105skie')) {
      return 'Koleje \u015al\u0105skie';
    }
    if (rawName.contains('Koleje Ma\u0142opolskie')) {
      return 'Koleje Ma\u0142opolskie';
    }
    if (rawName.contains('Koleje Dolno\u015bl\u0105skie')) {
      return 'Koleje Dolno\u015bl\u0105skie';
    }
    if (rawName.contains('\u0141\u00f3dzka Kolej Aglomeracyjna')) {
      return '\u0141KA';
    }
    return rawName;
  }

  String get _operatingDate {
    if (widget.result.operatingDate.isNotEmpty) {
      return widget.result.operatingDate;
    }
    final date = widget.result.operation?.operatingDate;
    if (date != null && date.isNotEmpty) return date;
    final dates = widget.result.route.operatingDates;
    return dates.length == 1
        ? dates.single
        : app_date.formatDateForApi(widget.now?.call() ?? DateTime.now());
  }

  Future<void> _fetchData() async {
    if (!mounted || _isLoading) return;
    setState(() {
      _isLoading = true;
      _routeLoadError = false;
    });
    final appState = context.read<AppState>();
    try {
      // Fetch the schedule first: it can supply the distinct train-order ID.
      if (_fullRoute == null) {
        try {
          final data = await appState.api.getScheduleRoute(
              widget.result.route.scheduleId, widget.result.route.orderId);
          if (!mounted) return;
          final fetched = TrainRoute.fromJson(data);
          if (fetched.scheduleId == widget.result.route.scheduleId &&
              fetched.orderId == widget.result.route.orderId) {
            setState(() => _fullRoute = fetched);
          } else {
            setState(() => _routeLoadError = true);
          }
        } catch (error) {
          debugPrint('[TrainDetails] Route unavailable: $error');
          if (mounted) setState(() => _routeLoadError = true);
        }
      }
      if (!mounted) return;
      final route = _fullRoute ?? widget.result.route;
      final trainOrderId = route.trainOrderId ?? _operation?.trainOrderId;
      final updated = await appState.getTrainOperation(
          route.scheduleId,
          trainOrderId != null && trainOrderId > 0
              ? trainOrderId
              : route.orderId,
          _operatingDate);
      if (!mounted) return;
      setState(() {
        _operation = updated != null &&
                operationMatchesRoute(updated, route, _operatingDate)
            ? updated
            : null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDelayBadge(int delay, bool isCancelled) {
    if (_operation == null) {
      return const Text('Wg rozkładu', style: TextStyle(fontSize: 12));
    }
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
    if (delay <= 0) {
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

    final isCancelled = _operation?.trainStatus == 'X';

    String relStart = widget.result.fromStationName;
    String relEnd = widget.result.toStationName;

    if (route.stations.isNotEmpty) {
      relStart = appState.stationNames[route.stations.first.stationId] ??
          widget.result.fromStationName;
      relEnd = appState.stationNames[route.stations.last.stationId] ??
          widget.result.toStationName;
    }

    // NEW: Compute live train position using TrainPositionResolver
    final positionResult = TrainPositionResolver.resolve(
      operation: _operation,
      routeStations: route.stations,
      stationNames: appState.stationNames,
      operatingDate: widget.result.operatingDate.isNotEmpty
          ? widget.result.operatingDate
          : _operation?.operatingDate,
      now: widget.now?.call() ?? DateTime.now(),
    );

    int currentDelay = positionResult.delayMinutes;

    // Find the index of current/next station in the route list
    int currentActiveIndex = -1;
    if (positionResult.status == TrainStatusType.atStation &&
        positionResult.currentStation != null) {
      currentActiveIndex =
          route.stations.indexOf(positionResult.currentStation!);
    } else if (positionResult.status == TrainStatusType.betweenStations &&
        positionResult.nextStation != null) {
      currentActiveIndex = route.stations.indexOf(positionResult.nextStation!);
    } else if (positionResult.status == TrainStatusType.completed) {
      currentActiveIndex = route.stations.length;
    }

    // Determine how many passed stations to hide by default
    // We keep the active station and the one immediately before it visible, hide everything before that.
    int hiddenPassedCount = 0;
    if (currentActiveIndex > 1) {
      hiddenPassedCount = currentActiveIndex - 1;
    }

    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF191D25) : theme.colorScheme.surface;
    final number = widget.result.trainNumber;
    final category = widget.result.commercialCategory;
    final trainName = widget.result.trainName;
    final visibleStart = _showPreviousStations ? 0 : hiddenPassedCount;
    String stationName(StationOnRoute station) =>
        appState.stationNames[station.stationId] ?? 'Stacja bez nazwy';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
          backgroundColor: background,
          title: Text([category, number].where((s) => s.isNotEmpty).join(' '),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
                onPressed: _isLoading ? null : _fetchData,
                tooltip: 'Odśwież dane trasy',
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh))
          ]),
      body: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TrainTypeIcon(
                                      category: category,
                                      size: 28,
                                      color: categoryColor(category,
                                          isDark: isDark)),
                                  if (category.isNotEmpty)
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: categoryColor(category,
                                                isDark: isDark),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(category,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: categoryTextColor(
                                                    category,
                                                    isDark: isDark)))),
                                  Text(number,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700)),
                                  _buildDelayBadge(currentDelay, isCancelled),
                                ]),
                            if (trainName.isNotEmpty)
                              Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(trainName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600))),
                            const SizedBox(height: 12),
                            Text('$relStart \u2192 $relEnd',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Wrap(spacing: 14, runSpacing: 4, children: [
                              Text(
                                  _getShortCarrierName(
                                      widget.result.carrierName),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                              Text(app_date.formatDate(_operatingDate),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ]),
                          ])),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                      child: Text(
                          _isLoading && _fullRoute == null
                              ? 'Pobieranie trasy...'
                              : _routeLoadError
                                  ? 'Nie udało się pobrać trasy'
                                  : 'Pełna trasa pociągu (${route.stations.length} stacji)',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700))),
                  if (_isLoading && _fullRoute == null)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()))
                  else if (_routeLoadError)
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextButton.icon(
                            onPressed: _fetchData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Spróbuj ponownie')))
                  else if (route.stations.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Trasa nie zawiera stacji'))
                  else ...[
                    if (hiddenPassedCount > 0)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextButton.icon(
                              key: const ValueKey('toggle-previous-stations'),
                              onPressed: () => setState(() =>
                                  _showPreviousStations =
                                      !_showPreviousStations),
                              icon: Icon(
                                  _showPreviousStations
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 18),
                              label: Text(_showPreviousStations
                                  ? 'Ukryj poprzednie stacje'
                                  : 'Pokaż poprzednie stacje ($hiddenPassedCount)'))),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: Column(children: [
                              for (var index = visibleStart;
                                  index < route.stations.length;
                                  index++)
                                RouteStopWidget(
                                  key: ValueKey('route-stop-$index'),
                                  stationName:
                                      stationName(route.stations[index]),
                                  scheduleData: route.stations[index],
                                  realtimeData: operationForStop(
                                      route.stations[index],
                                      route.stations,
                                      _operation?.stations ?? []),
                                  operatingDate: _operatingDate,
                                  index: index,
                                  isFirst: index == 0,
                                  isLast: index == route.stations.length - 1,
                                  startsVisibleRoute: index == visibleStart,
                                  isPassed: index < currentActiveIndex,
                                  hasTrainNow: positionResult.status ==
                                          TrainStatusType.atStation &&
                                      positionResult
                                              .currentStation?.stationId ==
                                          route.stations[index].stationId,
                                  isBetweenNext: positionResult.status ==
                                          TrainStatusType.betweenStations &&
                                      positionResult.nextStation?.stationId ==
                                          route.stations[index].stationId,
                                  isTrainAtPrevious: positionResult.status ==
                                          TrainStatusType.betweenStations &&
                                      positionResult
                                              .previousStation?.stationId ==
                                          route.stations[index].stationId,
                                  pulseSegment: positionResult.status ==
                                          TrainStatusType.betweenStations &&
                                      positionResult
                                              .previousStation?.stationId ==
                                          route.stations[index].stationId,
                                  pulseStation: positionResult.status ==
                                          TrainStatusType.atStation &&
                                      positionResult
                                              .currentStation?.stationId ==
                                          route.stations[index].stationId,
                                  isEstimatedPosition: positionResult.source !=
                                      PositionSource.live,
                                  pulseAnimation: _positionPulseCurve,
                                  notice: routeStopNotice(
                                      route.stations[index],
                                      index > 0
                                          ? route.stations[index - 1]
                                          : null,
                                      destination: appState.stationNames[
                                          route.stations.last.stationId]),
                                ),
                            ]))),
                  ],
                  const SizedBox(height: 32),
                ]),
          )),
    );
  }
}
