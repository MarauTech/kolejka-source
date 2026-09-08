import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../widgets/train_card.dart';
import 'train_details_screen.dart';
import 'search_screen.dart';
import '../utils/date_utils.dart' as app_date;

class ResultsScreen extends StatefulWidget {
  final List<ConnectionResult> results;
  final String fromStationName;
  final String toStationName;
  final String date;

  const ResultsScreen({
    super.key,
    required this.results,
    required this.fromStationName,
    required this.toStationName,
    required this.date,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _showPastConnections = false;
  void _openDetails(ConnectionResult result) {
    Navigator.push(
        context,
        MaterialPageRoute(
            settings: const RouteSettings(name: 'Szczegóły pociągu'),
            builder: (_) => TrainDetailsScreen(result: result)));
  }

  void _searchFavoriteRoute(FavoriteRoute fav) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => SearchScreen(
                  initialFromStation:
                      Station(id: fav.fromStationId, name: fav.fromStationName),
                  initialToStation:
                      Station(id: fav.toStationId, name: fav.toStationName),
                  searchOnStart: true,
                )));
  }

  Widget _buildSectionDivider(String title, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final now = DateTime.now();

    final pastConnections = <ConnectionResult>[];
    final futureConnections = <ConnectionResult>[];

    for (final result in widget.results) {
      final plannedDep = app_date.scheduleDateTime(
          result.fromStop.departureTime, result.operatingDate,
          day: result.fromStop.departureDay);
      final delay = result.departureDelay;
      if (plannedDep != null) {
        final correctedDep = plannedDep.add(Duration(minutes: delay));
        if (now.isAfter(correctedDep)) {
          pastConnections.add(result);
        } else {
          futureConnections.add(result);
        }
      } else {
        futureConnections.add(result);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.fromStationName} - ${widget.toStationName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.date,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: widget.results.isEmpty
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 64, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    const Text(
                      'Nie znaleziono połączeń',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spróbuj zmienić datę lub godzinę wyszukiwania.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                    if (appState.favoriteRoutes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Ulubione trasy',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...appState.favoriteRoutes.map((fav) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.route_outlined, size: 18),
                            title: Text(
                              '${fav.fromStationName} - ${fav.toStationName}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            onTap: () => _searchFavoriteRoute(fav),
                          )),
                    ],
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (pastConnections.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPastConnections = !_showPastConnections;
                        });
                      },
                      icon: Icon(_showPastConnections
                          ? Icons.expand_less
                          : Icons.expand_more),
                      label: Text(_showPastConnections
                          ? 'Ukryj wcześniejsze połączenia'
                          : 'Pokaż wcześniejsze połączenia (${pastConnections.length})'),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      children: _showPastConnections
                          ? pastConnections
                              .map((result) => TrainCard(
                                    connection: result,
                                    onTap: () => _openDetails(result),
                                  ))
                              .toList()
                          : [],
                    ),
                  ),
                  if (_showPastConnections &&
                      futureConnections.isNotEmpty &&
                      pastConnections.isNotEmpty)
                    _buildSectionDivider('Aktualne i nadchodzące', theme),
                ],
                ...futureConnections.map((result) => TrainCard(
                      connection: result,
                      onTap: () => _openDetails(result),
                    )),
                if (appState.favoriteRoutes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            size: 18, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Ulubione trasy',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...appState.favoriteRoutes.map((fav) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 2.0),
                        child: Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.route_outlined,
                                  size: 18, color: theme.colorScheme.primary),
                            ),
                            title: Text(
                              '${fav.fromStationName} - ${fav.toStationName}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            subtitle: const Text(
                              'Kliknij, aby wyszukać na teraz',
                              style: TextStyle(fontSize: 11),
                            ),
                            onTap: () => _searchFavoriteRoute(fav),
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }
}
