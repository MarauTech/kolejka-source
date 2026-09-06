import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/category_utils.dart';
import '../utils/date_utils.dart' as app_date;
import 'train_details_screen.dart';

class TrainSearchScreen extends StatefulWidget {
  const TrainSearchScreen({super.key});

  @override
  State<TrainSearchScreen> createState() => _TrainSearchScreenState();
}

class _TrainSearchScreenState extends State<TrainSearchScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _numberController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSearching = false;
  List<TrainSearchResult> _results = [];
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _numberController.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1)),
      lastDate:
          DateTime(now.year, now.month, now.day).add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _searchTrain() async {
    final query = _numberController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wpisz numer lub nazwę pociągu.')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();
    try {
      final res =
          await appState.searchTrainByNumber(query, date: _selectedDate);
      if (mounted) {
        setState(() {
          _results = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Błąd podczas wyszukiwania pociągu: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szukaj pociągu',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
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
                    TextField(
                      controller: _numberController,
                      decoration: InputDecoration(
                        labelText: 'Numer lub nazwa pociągu',
                        hintText: 'np. 5410, IC 5410, Kormoran',
                        prefixIcon: Icon(Icons.train_outlined,
                            color: theme.colorScheme.primary),
                        suffixIcon: _numberController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _numberController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchTrain(),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(10),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Data kursowania',
                                prefixIcon: Icon(Icons.calendar_today_outlined,
                                    size: 18, color: theme.colorScheme.primary),
                                border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              child: Text(
                                app_date.formatDateDisplay(_selectedDate),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _isSearching ? null : _searchTrain,
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Szukaj'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Wyszukiwanie pociągu w rozkładzie...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _searchTrain,
                          child: const Text('Spróbuj ponownie'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_hasSearched && _results.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Nie znaleziono pociągu dla wybranej daty.',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sprawdź numer lub nazwę pociągu oraz datę kursowania.',
                        style: TextStyle(
                            fontSize: 13, color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrainDetailsScreen(
                                result: ConnectionResult(
                                  route: item.route,
                                  fromStop: item.route.stations.isNotEmpty
                                      ? item.route.stations.first
                                      : StationOnRoute(
                                          stationId: 0,
                                          orderNumber: 1,
                                          raw: {}),
                                  toStop: item.route.stations.isNotEmpty
                                      ? item.route.stations.last
                                      : StationOnRoute(
                                          stationId: 0,
                                          orderNumber: 2,
                                          raw: {}),
                                  fromStationName: item.fromStationName,
                                  toStationName: item.toStationName,
                                  carrierName: item.carrierName ?? '',
                                  commercialCategory: item.category ?? '',
                                  operatingDate: item.operatingDate,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (item.category != null &&
                                          item.category!.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: categoryColor(
                                              item.category,
                                              isDark: theme.brightness ==
                                                  Brightness.dark,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.category!,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: categoryTextColor(
                                                  item.category,
                                                  isDark: theme.brightness ==
                                                      Brightness.dark),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        item.nationalNumber,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (item.trainName != null &&
                                          item.trainName!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.trainName!,
                                            style: TextStyle(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ] else
                                        const Spacer(),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.fromStationName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0),
                                        child: Icon(Icons.arrow_forward,
                                            size: 16,
                                            color: theme.colorScheme.outline),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item.toStationName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13),
                                          textAlign: TextAlign.end,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.departureTime,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .colorScheme.onSurfaceVariant),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _getShortCarrierName(
                                              item.carrierName),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.outline),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        item.arrivalTime,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
