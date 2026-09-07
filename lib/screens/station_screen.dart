import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/category_utils.dart';
import '../utils/format_utils.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/station_search.dart';
import 'train_details_screen.dart';

class StationScreen extends StatefulWidget {
  const StationScreen({super.key});

  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen>
    with SingleTickerProviderStateMixin {
  static const int _boardPageSize = 8;
  late TabController _tabController;
  bool _isSelectingStation = false;
  bool _showPreviousDepartures = false;
  bool _showPreviousArrivals = false;
  int _visibleDepartureCount = _boardPageSize;
  int _visibleArrivalCount = _boardPageSize;
  int? _lastStationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _formatPlatformTrack(String? platform, String? track) {
    return formatPlatformTrack(platform, track, compact: true);
  }

  Widget _buildSectionDivider(String title, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1.5,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1.5,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
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

  Color _getCategoryColor(String category, ColorScheme scheme, bool isDark) {
    return categoryColor(category, isDark: isDark);
  }

  Widget _buildDelayStatus(int? delay, bool isCancelled, ThemeData theme) {
    if (isCancelled) {
      return const Text(
        'Odwołany',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    }

    if (delay == null) {
      return Text(
        'Rozkład',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      );
    }

    if (delay == 0) {
      return const Text(
        '+0',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      );
    }

    return Text(
      '+$delay',
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  bool _isItemPast(StationBoardItem item, DateTime now) {
    final date = item.operatingDate.isEmpty
        ? app_date.formatDateForApi(now)
        : item.operatingDate;
    final actual = app_date.scheduleDateTime(item.actualTime, date);
    final planned =
        app_date.scheduleDateTime(item.plannedTime ?? item.time, date);
    final effective =
        actual ?? planned?.add(Duration(minutes: item.delayMinutes ?? 0));
    return effective != null && now.difference(effective).inMinutes > 5;
  }

  String _boardDateLabel(List<StationBoardItem> items, DateTime now) {
    DateTime date = now;
    if (items.isNotEmpty) {
      date = DateTime.tryParse(items.first.operatingDate) ?? now;
    }
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final prefix = day == today
        ? 'Dziś'
        : day == today.add(const Duration(days: 1))
            ? 'Jutro'
            : const [
                'pon.',
                'wt.',
                'śr.',
                'czw.',
                'pt.',
                'sob.',
                'niedz.'
              ][date.weekday - 1];
    final weekday = const [
      'pon.',
      'wt.',
      'śr.',
      'czw.',
      'pt.',
      'sob.',
      'niedz.'
    ][date.weekday - 1];
    final formatted = app_date.formatDateDisplay(date);
    return prefix == 'Dziś' || prefix == 'Jutro'
        ? '$prefix, $weekday, $formatted'
        : '$prefix, $formatted';
  }

  Widget _buildBoardAction({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: theme.colorScheme.primary),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationHeader(AppState appState) {
    final theme = Theme.of(context);
    final station = appState.currentStation;
    final isFavorite =
        station != null && appState.isStationFavorite(station.id);
    final updated = appState.stationBoardLastUpdated;
    final updatedText = updated == null
        ? ''
        : ' · Aktualizacja ${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isSelectingStation) ...[
            Row(
              children: [
                Expanded(
                  child: StationSearchField(
                    label: 'Zmień stację',
                    stations: appState.stations,
                    selectedStation: station,
                    onStationSelected: (newStation) {
                      if (newStation != null) {
                        appState.selectManualStation(newStation);
                      }
                      setState(() => _isSelectingStation = false);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _isSelectingStation = false),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isSelectingStation = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  station?.name ?? 'Wybierz stację',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: theme.colorScheme.outline,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (appState.isDetectingLocation ||
                                  (appState.isLoading && station == null)) ...[
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Ustalanie stacji na podstawie GPS...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else if (appState.isStationFromGps) ...[
                                Icon(
                                  Icons.near_me,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Najbliższa stacja (GPS)$updatedText',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else ...[
                                Flexible(
                                  child: Text(
                                    'Wybrana$updatedText',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Star favorite toggle
                if (station != null)
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color:
                          isFavorite ? Colors.amber : theme.colorScheme.outline,
                    ),
                    onPressed: () => appState.toggleFavoriteStation(station),
                    tooltip: isFavorite
                        ? 'Usuń z ulubionych'
                        : 'Dodaj do ulubionych',
                  ),
                // GPS button
                IconButton(
                  icon: appState.isDetectingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.my_location,
                          color: appState.isStationFromGps
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                  onPressed: appState.isDetectingLocation
                      ? null
                      : () => appState.detectNearestStation(forceRefresh: true),
                  tooltip: 'Wykryj najbliższą stację',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(
      List<StationBoardItem> items, bool isArrival, AppState appState) {
    final theme = Theme.of(context);

    if (appState.stationBoardError != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                appState.stationBoardError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: appState.currentStation != null
                    ? () =>
                        appState.loadStationBoard(appState.currentStation!.id)
                    : null,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (appState.currentStation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train_outlined,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Wybierz stację, aby zobaczyć tablicę',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty && !appState.isStationBoardLoading) {
      return RefreshIndicator(
        onRefresh: () => appState.loadStationBoard(appState.currentStation!.id),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                isArrival
                    ? 'Brak zbliżających się przyjazdów'
                    : 'Brak zbliżających się odjazdów',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final pastItems = <StationBoardItem>[];
    final upcomingItems = <StationBoardItem>[];

    for (final item in items) {
      if (_isItemPast(item, now)) {
        pastItems.add(item);
      } else {
        upcomingItems.add(item);
      }
    }

    final showPast =
        isArrival ? _showPreviousArrivals : _showPreviousDepartures;
    final visibleCount =
        isArrival ? _visibleArrivalCount : _visibleDepartureCount;
    final visibleUpcoming = upcomingItems.take(visibleCount).toList();
    final remaining = upcomingItems.length - visibleUpcoming.length;
    final children = <Widget>[
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 7, 14, 6),
        color: theme.colorScheme.surfaceContainerLow,
        child: Text(
          _boardDateLabel(items, now),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ];

    if (pastItems.isNotEmpty && upcomingItems.isNotEmpty) {
      children.add(_buildBoardAction(
        key: ValueKey(isArrival
            ? 'toggle-earlier-arrivals'
            : 'toggle-earlier-departures'),
        label: showPast
            ? (isArrival
                ? 'Ukryj wcześniejsze przyjazdy'
                : 'Ukryj wcześniejsze odjazdy')
            : (isArrival
                ? 'Pokaż wcześniejsze przyjazdy (${pastItems.length})'
                : 'Pokaż wcześniejsze odjazdy (${pastItems.length})'),
        icon: showPast ? Icons.expand_less : Icons.history,
        onTap: () => setState(() {
          if (isArrival) {
            _showPreviousArrivals = !_showPreviousArrivals;
          } else {
            _showPreviousDepartures = !_showPreviousDepartures;
          }
        }),
        theme: theme,
      ));
    }

    void addRows(List<StationBoardItem> rows, {required bool past}) {
      for (final item in rows) {
        children.add(_buildRow(item, isArrival, past, theme, appState));
        children.add(Divider(
          height: 1,
          thickness: 0.6,
          indent: 14,
          endIndent: 14,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ));
      }
    }

    if (showPast || upcomingItems.isEmpty) {
      addRows(pastItems, past: true);
    }
    if (showPast && pastItems.isNotEmpty && upcomingItems.isNotEmpty) {
      children.add(_buildSectionDivider('Aktualne i nadchodzące', theme));
    }
    addRows(visibleUpcoming, past: false);

    if (remaining > 0) {
      children.add(_buildBoardAction(
        key:
            ValueKey(isArrival ? 'show-more-arrivals' : 'show-more-departures'),
        label: isArrival
            ? 'Pokaż kolejne przyjazdy ($remaining)'
            : 'Pokaż kolejne odjazdy ($remaining)',
        icon: Icons.expand_more,
        onTap: () => setState(() {
          if (isArrival) {
            _visibleArrivalCount += _boardPageSize;
          } else {
            _visibleDepartureCount += _boardPageSize;
          }
        }),
        theme: theme,
      ));
    }

    return RefreshIndicator(
      onRefresh: () => appState.loadStationBoard(appState.currentStation!.id),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        children: children,
      ),
    );
  }

  Widget _buildRow(StationBoardItem item, bool isArrival, bool isPastItem,
      ThemeData theme, AppState appState) {
    final isDark = theme.brightness == Brightness.dark;
    final catColor =
        _getCategoryColor(item.trainCategory, theme.colorScheme, isDark);
    final platTrack = _formatPlatformTrack(item.platform, item.track);
    final shortCarrier = _getShortCarrierName(item.carrier);

    final hasDelay = item.delayMinutes != null && item.delayMinutes! > 0;
    final isCancelled = item.isCancelled;

    final mainTime = hasDelay
        ? (item.actualTime ?? item.time)
        : (item.plannedTime ?? item.time);
    final struckTime = hasDelay ? item.plannedTime : null;

    final timeColor =
        isCancelled || hasDelay ? Colors.red : theme.colorScheme.onSurface;
    final catTextColor = categoryTextColor(item.trainCategory, isDark: isDark);

    return Opacity(
      opacity: isPastItem ? 0.65 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainDetailsScreen(
                    result: ConnectionResult(
                      route: TrainRoute(
                        scheduleId: item.scheduleId,
                        orderId: item.orderId,
                        nationalNumber: item.trainNumber,
                        name: item.trainName,
                        commercialCategorySymbol: item.trainCategory,
                        operatingDates: [item.operatingDate],
                        stations: [],
                        connections: [],
                        raw: item.raw,
                      ),
                      fromStop: StationOnRoute(
                        stationId: appState.currentStation!.id,
                        orderNumber: 1,
                        departureTime: item.time,
                        raw: {},
                      ),
                      toStop: StationOnRoute(
                        stationId: 0,
                        orderNumber: 2,
                        raw: {},
                      ),
                      fromStationName: isArrival
                          ? item.direction
                          : appState.currentStation!.name,
                      toStationName: isArrival
                          ? appState.currentStation!.name
                          : item.direction,
                      carrierName: item.carrier,
                      commercialCategory: item.trainCategory,
                      operatingDate: item.operatingDate,
                    ),
                  ),
                ),
              );
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mainTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: timeColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      _buildDelayStatus(item.delayMinutes, isCancelled, theme),
                      if (struckTime != null && struckTime != mainTime)
                        Text(struckTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.outline,
                              decoration: TextDecoration.lineThrough,
                            )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (item.trainCategory.isNotEmpty)
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child:
                                  Icon(Icons.train, size: 13, color: catColor),
                            ),
                          if (item.trainCategory.isNotEmpty)
                            const SizedBox(width: 5),
                          if (item.trainCategory.isNotEmpty ||
                              item.trainNumber.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 78),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    [item.trainCategory, item.trainNumber]
                                        .where((value) => value.isNotEmpty)
                                        .join(' '),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: catTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            isArrival ? Icons.arrow_back : Icons.arrow_forward,
                            size: 13,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.direction,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (platTrack != null) ...[
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 58),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(platTrack,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    )),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.trainName.isNotEmpty ||
                          shortCarrier.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.trainName.isNotEmpty
                              ? item.trainName
                              : shortCarrier,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: item.trainName.isNotEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final stationId = appState.currentStation?.id;
    if (_lastStationId != stationId) {
      _lastStationId = stationId;
      _showPreviousDepartures = false;
      _showPreviousArrivals = false;
      _visibleDepartureCount = _boardPageSize;
      _visibleArrivalCount = _boardPageSize;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablica stacyjna',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: appState.isStationBoardLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: appState.currentStation != null &&
                    !appState.isStationBoardLoading
                ? () => appState.loadStationBoard(appState.currentStation!.id)
                : null,
            tooltip: 'Odśwież tablicę',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.outline,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.north_east, size: 15),
                        SizedBox(width: 6),
                        Text('Odjazdy',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.south_west, size: 15),
                        SizedBox(width: 6),
                        Text('Przyjazdy',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStationHeader(appState),
          if (appState.isStationBoardLoading &&
              (appState.stationDepartures.isNotEmpty ||
                  appState.stationArrivals.isNotEmpty))
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(appState.stationDepartures, false, appState),
                _buildList(appState.stationArrivals, true, appState),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
