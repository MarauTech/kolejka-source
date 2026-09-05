import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../widgets/station_search.dart';

class StationScreen extends StatefulWidget {
  const StationScreen({super.key});

  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Station? _selectedStation;
  bool _isLoading = false;
  String? _errorMessage;
  List<StationBoardItem> _departures = [];
  List<StationBoardItem> _arrivals = [];

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

  Future<void> _loadData() async {
    if (_selectedStation == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final board = await appState.getStationBoard(_selectedStation!.id);

      if (mounted) {
        setState(() {
          _departures = board['departures'] ?? [];
          _arrivals = board['arrivals'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Nie udało się pobrać danych ze stacji: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onStationSelected(Station? station) {
    setState(() {
      _selectedStation = station;
      _departures = [];
      _arrivals = [];
      _errorMessage = null;
    });
    if (station != null) {
      _loadData();
    }
  }

  Widget _buildDelayBadge(int? delay, bool isCancelled) {
    if (isCancelled) {
      return const Text(
        'Odwołany',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
      );
    }

    if (delay == null || delay == 0) {
      return const Text(
        'Planowo',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
      );
    }

    final color = delay <= 10 ? Colors.orange.shade800 : Colors.red;
    return Text(
      '+$delay min',
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  Widget _buildList(List<StationBoardItem> items, bool isArrival) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedStation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Wybierz stację powyżej',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                isArrival ? 'Brak zbliżających się przyjazdów' : 'Brak zbliżających się odjazdów',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final item = items[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: SizedBox(
              width: 55,
              child: Text(
                item.time,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
            ),
            title: Text(
              item.direction,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                if (item.trainCategory.isNotEmpty) item.trainCategory,
                item.trainNumber,
                if (item.carrier.isNotEmpty) item.carrier,
              ].join(' '),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: _buildDelayBadge(item.delayMinutes, item.isCancelled),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablica stacyjna', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _selectedStation != null && !_isLoading ? _loadData : null,
            tooltip: 'Odśwież',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(115),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: StationSearchField(
                  label: 'Wybierz stację',
                  stations: appState.stations,
                  selectedStation: _selectedStation,
                  onStationSelected: _onStationSelected,
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF003366),
                labelColor: const Color(0xFF003366),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Odjazdy', icon: Icon(Icons.flight_takeoff, size: 20)),
                  Tab(text: 'Przyjazdy', icon: Icon(Icons.flight_land, size: 20)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_departures, false),
          _buildList(_arrivals, true),
        ],
      ),
    );
  }
}
