import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
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

  Widget _buildDelayBadge(int? delay, bool isCancelled) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Odwołany',
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    if (delay == null || delay == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Planowo',
          style: TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    final color = delay <= 10 ? Colors.orange.shade800 : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '+$delay min',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
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
                              if (appState.isStationFromGps) ...[
                                Icon(
                                  Icons.near_me,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Najbliższa stacja (GPS)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Wybrana stacja',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (appState.stationBoardLastUpdated != null) ...[
                                Text(
                                  ' | Zaktualizowano: ${appState.stationBoardLastUpdated!.hour.toString().padLeft(2, '0')}:${appState.stationBoardLastUpdated!.minute.toString().padLeft(2, '0')}:${appState.stationBoardLastUpdated!.second.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.outline,
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
          if (appState.locationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                appState.locationMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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

    return RefreshIndicator(
      onRefresh: () => appState.loadStationBoard(appState.currentStation!.id),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          final item = items[index];

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: SizedBox(
              width: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (item.plannedTime != null &&
                      item.actualTime != null &&
                      item.plannedTime != item.actualTime)
                    Text(
                      item.plannedTime!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              item.direction,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.trainCategory.isNotEmpty) item.trainCategory,
                    item.trainNumber,
                    if (item.carrier.isNotEmpty) item.carrier,
                  ].join(' | '),
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                if (item.platform != null && item.platform!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Peron ${item.platform}${(item.track != null && item.track!.isNotEmpty) ? ' / Tor ${item.track}' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: _buildDelayBadge(item.delayMinutes, item.isCancelled),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainDetailsScreen(
                    result: ConnectionResult(
                      route: TrainRoute(
                        scheduleId: item.scheduleId,
                        orderId: item.orderId,
                        nationalNumber: item.trainNumber,
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
            },
          );
        },
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
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.north_east, size: 16),
                      SizedBox(width: 8),
                      Text('Odjazdy',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.south_west, size: 16),
                      SizedBox(width: 8),
                      Text('Przyjazdy',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
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
