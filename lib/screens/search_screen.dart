import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/station_search.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Station? _fromStation;
  Station? _toStation;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSearching = false;

  void _swapStations() {
    setState(() {
      final temp = _fromStation;
      _fromStation = _toStation;
      _toStation = temp;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('pl', 'PL'),
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
        const SnackBar(content: Text('Stacja początkowa i docelowa muszą być różne.')),
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

      final dateStr = app_date.formatDate(_selectedDate.toIso8601String());

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
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rozkład PKP',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: appState.isLoading && appState.stations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Wczytywanie stacji...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          StationSearchField(
                            label: 'Skąd',
                            stations: appState.stations,
                            selectedStation: _fromStation,
                            onStationSelected: (s) => setState(() => _fromStation = s),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: _swapStations,
                                icon: const Icon(Icons.swap_vert, size: 20),
                                label: const Text('Skąd ↔ Dokąd'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          StationSearchField(
                            label: 'Dokąd',
                            stations: appState.stations,
                            selectedStation: _toStation,
                            onStationSelected: (s) => setState(() => _toStation = s),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Data',
                                      prefixIcon: Icon(Icons.calendar_today, size: 20, color: Color(0xFF003366)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    child: Text(
                                      app_date.formatDate(_selectedDate.toIso8601String()),
                                      style: const TextStyle(fontSize: 14),
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
                                    decoration: const InputDecoration(
                                      labelText: 'Godzina',
                                      prefixIcon: Icon(Icons.access_time, size: 20, color: Color(0xFF003366)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    child: Text(
                                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _isSearching ? null : _performSearch,
                              icon: _isSearching
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(
                                _isSearching ? 'SZUKANIE...' : 'SZUKAJ',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF003366),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
