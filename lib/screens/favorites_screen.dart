import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import 'search_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final ValueChanged<FavoriteRoute>? onOpenRoute;

  const FavoritesScreen({super.key, this.onNavigateToTab, this.onOpenRoute});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  void _openStation(AppState appState, FavoriteStation favStation) {
    // Find Station in stations dictionary
    final station = appState.stations.firstWhere(
      (s) => s.id == favStation.id,
      orElse: () => Station(id: favStation.id, name: favStation.name),
    );

    appState.selectManualStation(station);
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(1); // Switch to Tablica tab
    }
  }

  void _openRoute(AppState appState, FavoriteRoute favRoute) {
    if (widget.onOpenRoute != null) {
      widget.onOpenRoute!(favRoute);
      return;
    }
    final fromSt = appState.stations.firstWhere(
      (s) => s.id == favRoute.fromStationId,
      orElse: () =>
          Station(id: favRoute.fromStationId, name: favRoute.fromStationName),
    );
    final toSt = appState.stations.firstWhere(
      (s) => s.id == favRoute.toStationId,
      orElse: () =>
          Station(id: favRoute.toStationId, name: favRoute.toStationName),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          initialFromStation: fromSt,
          initialToStation: toSt,
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
        title: const Text('Ulubione',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          tabs: [
            Tab(text: 'Stacje (${appState.favoriteStations.length})'),
            Tab(text: 'Trasy (${appState.favoriteRoutes.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Favorite Stations list
          appState.favoriteStations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline,
                            size: 56, color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Brak ulubionych stacji',
                          style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kliknij ikonę gwiazdki na tablicy stacyjnej, aby dodać stację.',
                          style: TextStyle(
                              fontSize: 13, color: theme.colorScheme.outline),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: appState.favoriteStations.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final fav = appState.favoriteStations[index];
                    return ListTile(
                      leading:
                          Icon(Icons.train, color: theme.colorScheme.primary),
                      title: Text(
                        fav.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text(
                          'Dotknij, aby wyświetlić tablicę odjazdów i przyjazdów'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => appState.removeFavoriteStation(fav.id),
                        tooltip: 'Usuń z ulubionych',
                      ),
                      onTap: () => _openStation(appState, fav),
                    );
                  },
                ),

          // Favorite Routes list
          appState.favoriteRoutes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route_outlined,
                            size: 56, color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Brak ulubionych tras',
                          style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Wyszukaj połączenie i kliknij gwiazdkę w nagłówku, aby zapisać trasę.',
                          style: TextStyle(
                              fontSize: 13, color: theme.colorScheme.outline),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: appState.favoriteRoutes.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final fav = appState.favoriteRoutes[index];
                    return ListTile(
                      leading: Icon(Icons.swap_calls,
                          color: theme.colorScheme.primary),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fav.fromStationName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Icon(Icons.arrow_downward,
                                size: 14, color: theme.colorScheme.outline),
                          ),
                          Text(fav.toStationName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Wyszukaj połączenia'),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => appState.removeFavoriteRoute(
                            fav.fromStationId, fav.toStationId),
                        tooltip: 'Usuń z ulubionych',
                      ),
                      onTap: () => _openRoute(appState, fav),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
