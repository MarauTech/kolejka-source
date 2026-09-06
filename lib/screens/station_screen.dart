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
  late TabController _tabController;
  bool _isSelectingStation = false;
  bool _showPreviousDepartures = false;
  bool _showPreviousArrivals = false;

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
    return formatPlatformTrack(platform, track);
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
          fontSize: 12,
        ),
      );
    }

    if (delay == null || delay == 0) {
      return const Text(
        'Planowo',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    }

    return Text(
      '+$delay min',
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 12,
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

  Widget _buildStationHeader(AppState appState) {
    final theme = Theme.of(context);
    final station = appState.currentStation;
    final isFavorite =
        station != null && appState.isStationFavorite(station.id);

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
                                    'Najbliższa stacja (GPS)'
                                    '${appState.stationBoardLastUpdated != null ? ' | Zaktualizowano: ${appState.stationBoardLastUpdated!.hour.toString().padLeft(2, '0')}:${appState.stationBoardLastUpdated!.minute.toString().padLeft(2, '0')}:${appState.stationBoardLastUpdated!.second.toString().padLeft(2, '0')}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else ...[
                                Flexible(
                                  child: Text(
                                    'Wybrana stacja'
                                    '${appState.stationBoardLastUpdated != null ? ' | Zaktualizowano: ${appState.stationBoardLastUpdated!.hour.toString().padLeft(2, '0')}:${appState.stationBoardLastUpdated!.minute.toString().padLeft(2, '0')}:${appState.stationBoardLastUpdated!.second.toString().padLeft(2, '0')}' : ''}',
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
    // If all items are past, show them so user is not presented with an empty list
    final hasUpcoming = upcomingItems.isNotEmpty;
    final displayItems = (showPast || !hasUpcoming)
        ? [...pastItems, ...upcomingItems]
        : upcomingItems;

    return RefreshIndicator(
      onRefresh: () => appState.loadStationBoard(appState.currentStation!.id),
      child: ListView.separated(
        padding: EdgeInsets.only(
          top: 4,
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        itemCount:
            displayItems.length + (hasUpcoming && pastItems.isNotEmpty ? 1 : 0),
        separatorBuilder: (_, index) {
          if (hasUpcoming && pastItems.isNotEmpty && index == 0) {
            return const SizedBox.shrink();
          }
          if (showPast &&
              hasUpcoming &&
              pastItems.isNotEmpty &&
              index == pastItems.length) {
            return _buildSectionDivider('Aktualne i nadchodzące', theme);
          }
          return Divider(
            height: 1,
            thickness: 0.6,
            indent: 14,
            endIndent: 14,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          );
        },
        itemBuilder: (context, index) {
          if (hasUpcoming && pastItems.isNotEmpty) {
            if (index == 0) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isArrival) {
                        _showPreviousArrivals = !_showPreviousArrivals;
                      } else {
                        _showPreviousDepartures = !_showPreviousDepartures;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          showPast ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            showPast
                                ? (isArrival
                                    ? 'Ukryj wcze\u015bniejsze przyjazdy'
                                    : 'Ukryj wcze\u015bniejsze odjazdy')
                                : (isArrival
                                    ? 'Poka\u017c wcze\u015bniejsze przyjazdy (${pastItems.length})'
                                    : 'Poka\u017c wcze\u015bniejsze odjazdy (${pastItems.length})'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final itemIndex = index - 1;
            final item = displayItems[itemIndex];
            final isPastItem = showPast && itemIndex < pastItems.length;
            return _buildRow(item, isArrival, isPastItem, theme, appState);
          }

          final item = displayItems[index];
          final isPastItem = pastItems.contains(item);
          return _buildRow(item, isArrival, isPastItem, theme, appState);
        },
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

    final timeColor = isCancelled
        ? Colors.red
        : (hasDelay ? Colors.red : theme.colorScheme.primary);
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LEWA KOLUMNA: GODZINA
                SizedBox(
                  width: 50,
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
                      if (struckTime != null && struckTime != mainTime) ...[
                        const SizedBox(height: 1),
                        Text(
                          struckTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 2. ŚRODKOWA + PRAWA KOLUMNA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wiersz 1: [Badge] [Numer] [Nazwa pociągu / przewoźnik] ... [Peron/Tor]
                      Row(
                        children: [
                          if (item.trainCategory.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.trainCategory,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: catTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          if (item.trainNumber.isNotEmpty) ...[
                            Text(
                              item.trainNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (item.trainName.isNotEmpty) ...[
                            Expanded(
                              child: Text(
                                item.trainName,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else if (shortCarrier.isNotEmpty) ...[
                            Expanded(
                              child: Text(
                                shortCarrier,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            const Spacer(),
                          ],
                        ],
                      ),
                      if (platTrack != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(platTrack,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color:
                                        theme.colorScheme.onSurfaceVariant))),
                      const SizedBox(height: 3),

                      // Wiersz 2: [Strzałka] [Kierunek] ... [Status/Opóźnienie]
                      Row(
                        children: [
                          Icon(
                            isArrival ? Icons.arrow_back : Icons.arrow_forward,
                            size: 13,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.direction,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildDelayStatus(
                              item.delayMinutes, isCancelled, theme),
                        ],
                      ),
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
