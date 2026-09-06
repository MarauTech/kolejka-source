import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/station_search.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  final Station? initialFromStation;
  final Station? initialToStation;

  const SearchScreen({
    super.key,
    this.initialFromStation,
    this.initialToStation,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  Station? _fromStation;
  Station? _toStation;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fromStation = widget.initialFromStation;
    _toStation = widget.initialToStation;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  void _swapStations() {
    setState(() {
      final temp = _fromStation;
      _fromStation = _toStation;
      _toStation = temp;
    });
  }

  void _setNow() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.fromDateTime(now);
    });
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _setTomorrow() {
    final t = app_date.tomorrow();
    setState(() {
      _selectedDate = t;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1)),
      lastDate:
          DateTime(now.year, now.month, now.day).add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _performSearch() async {
    if (_fromStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz stację początkową (Skąd).')),
      );
      return;
    }
    if (_toStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz stację docelową (Dokąd).')),
      );
      return;
    }
    if (_fromStation!.id == _toStation!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Stacja początkowa i docelowa muszą być różne.')),
      );
      return;
    }

    setState(() => _isSearching = true);

    final appState = context.read<AppState>();
    try {
      final results = await appState.searchConnections(
        fromStation: _fromStation!,
        toStation: _toStation!,
        date: _selectedDate,
        time: _selectedTime,
      );

      if (!mounted) return;

      final dateStr = app_date.formatDateDisplay(_selectedDate);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            results: results,
            fromStationName: _fromStation!.name,
            toStationName: _toStation!.name,
            date: dateStr,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd wyszukiwania: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    final isFavoriteRoute = _fromStation != null &&
        _toStation != null &&
        appState.isRouteFavorite(_fromStation!.id, _toStation!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Połączenia kolejowe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_fromStation != null && _toStation != null)
            IconButton(
              icon: Icon(
                isFavoriteRoute ? Icons.star : Icons.star_border,
                color:
                    isFavoriteRoute ? Colors.amber : theme.colorScheme.outline,
              ),
              onPressed: () =>
                  appState.toggleFavoriteRoute(_fromStation!, _toStation!),
              tooltip: isFavoriteRoute
                  ? 'Usuń trasę z ulubionych'
                  : 'Dodaj trasę do ulubionych',
            ),
        ],
      ),
      body: appState.isLoading && appState.stations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Wczytywanie stacji z API PLK...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Skąd field
                          StationSearchField(
                            label: 'Skąd (stacja początkowa)',
                            stations: appState.stations,
                            selectedStation: _fromStation,
                            onStationSelected: (s) =>
                                setState(() => _fromStation = s),
                          ),
                          const SizedBox(height: 6),

                          // Swap button
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _swapStations,
                              icon: const Icon(Icons.swap_vert, size: 18),
                              label: const Text('Zamień stacje'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(
                                    color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Dokąd field
                          StationSearchField(
                            label: 'Dokąd (stacja docelowa)',
                            stations: appState.stations,
                            selectedStation: _toStation,
                            onStationSelected: (s) =>
                                setState(() => _toStation = s),
                          ),
                          const SizedBox(height: 16),

                          // Independent Date & Time pickers
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Data podróży',
                                      prefixIcon: Icon(
                                          Icons.calendar_today_outlined,
                                          size: 20,
                                          color: theme.colorScheme.primary),
                                      border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    child: Text(
                                      app_date.formatDateDisplay(_selectedDate),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickTime,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Godzina od',
                                      prefixIcon: Icon(
                                          Icons.access_time_outlined,
                                          size: 20,
                                          color: theme.colorScheme.primary),
                                      border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    child: Text(
                                      app_date.formatTimeDisplay(
                                          _selectedTime.hour,
                                          _selectedTime.minute),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Quick Action Chips
                          Wrap(
                            spacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.flash_on, size: 16),
                                label: const Text('Teraz'),
                                onPressed: _setNow,
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.today, size: 16),
                                label: const Text('Dzisiaj'),
                                onPressed: _setToday,
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.event, size: 16),
                                label: const Text('Jutro'),
                                onPressed: _setTomorrow,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Search Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _isSearching ? null : _performSearch,
                              icon: _isSearching
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(
                                _isSearching
                                    ? 'WYSZUKIWANIE...'
                                    : 'SZUKAJ POŁĄCZEŃ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
