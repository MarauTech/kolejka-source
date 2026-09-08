import '../widgets/journey_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/station_search.dart';
import '../widgets/connection_results.dart';

class SearchScreen extends StatefulWidget {
  final Station? initialFromStation;
  final Station? initialToStation;
  final bool searchOnStart;
  const SearchScreen(
      {super.key,
      this.initialFromStation,
      this.initialToStation,
      this.searchOnStart = false});
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
  bool _editSearch = true;
  List<ConnectionResult>? _results;
  DateTime? _searchedAt;
  String? _error;
  DateTime? _loadedThrough;
  bool _isLoadingMore = false;
  String? _moreMessage;
  bool _moreFailed = false;
  int _request = 0;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _fromStation = widget.initialFromStation;
    _toStation = widget.initialToStation;
    final now = DateTime.now();
    _selectedDate = DateUtils.dateOnly(now);
    _selectedTime = TimeOfDay.fromDateTime(now);
    if (widget.searchOnStart && _fromStation != null && _toStation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _performSearch();
      });
    }
  }

  void _changed(VoidCallback change) {
    setState(() {
      change();
      _request++;
      _isSearching = false;
      _results = null;
      _error = null;
      _isLoadingMore = false;
      _loadedThrough = null;
      _moreMessage = null;
      _moreFailed = false;
    });
  }

  void _swapStations() => _changed(() {
        final old = _fromStation;
        _fromStation = _toStation;
        _toStation = old;
      });
  void _setNow() => _changed(() {
        final now = DateTime.now();
        _selectedDate = DateUtils.dateOnly(now);
        _selectedTime = TimeOfDay.fromDateTime(now);
      });
  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showJourneyPicker(
        context: context,
        initial: _selectedDate,
        firstDate: now.subtract(const Duration(days: 1)),
        lastDate: now.add(const Duration(days: 60)));
    if (mounted && picked != null) _changed(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showJourneyPicker(
      context: context,
      initial: DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, _selectedTime.hour, _selectedTime.minute),
      time: true,
    );
    if (mounted && picked != null) {
      _changed(() => _selectedTime = TimeOfDay.fromDateTime(picked));
    }
  }

  Future<void> _performSearch() async {
    if (_isSearching) return;
    final from = _fromStation, to = _toStation;
    if (from == null || to == null || from.id == to.id) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(from == null || to == null
              ? 'Wybierz stację początkową i docelową.'
              : 'Stacja początkowa i docelowa muszą być różne.')));
      return;
    }
    FocusScope.of(context).unfocus();
    final date = _selectedDate, time = _selectedTime;
    final request = ++_request;
    setState(() {
      _isSearching = true;
      _error = null;
      _isLoadingMore = false;
      _moreMessage = null;
      _moreFailed = false;
    });
    try {
      final results = await context.read<AppState>().searchConnections(
          fromStation: from, toStation: to, date: date, time: time);
      if (!mounted || request != _request) return;
      setState(() {
        _results = results;
        _editSearch = false;
        _searchedAt =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        _loadedThrough = DateUtils.dateOnly(date);
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = error is ApiException && error.statusCode == 429
              ? 'Źródło rozkładów jest chwilowo przeciążone. Spróbuj ponownie za minutę.'
              : error is ApiException && error.isConnectionError
                  ? 'Brak połączenia z internetem. Sprawdź połączenie i spróbuj ponownie.'
                  : 'Nie udało się wyszukać połączeń. Spróbuj ponownie.';
          if (_results != null) {
            _error =
                '$_error Wyświetlam ostatnio pobrane wyniki; mogą być nieaktualne.';
          }
        });
      }
    } finally {
      if (mounted && request == _request) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadNextDay() async {
    if (_isSearching ||
        _isLoadingMore ||
        _results == null ||
        _loadedThrough == null) {
      return;
    }
    final from = _fromStation!, to = _toStation!;
    final request = _request;
    final date = DateUtils.addDaysToDate(_loadedThrough!, 1);
    setState(() {
      _isLoadingMore = true;
      _moreMessage = null;
      _moreFailed = false;
    });
    try {
      final next = await context.read<AppState>().searchConnections(
          fromStation: from,
          toStation: to,
          date: date,
          time: const TimeOfDay(hour: 0, minute: 0));
      if (!mounted || request != _request) return;
      String key(ConnectionResult result) =>
          '${result.route.scheduleId}/${result.route.orderId}/${result.operatingDate}/'
          '${result.fromStop.orderNumber}/${result.toStop.orderNumber}/'
          '${result.secondLeg?.route.scheduleId}/${result.secondLeg?.route.orderId}/'
          '${result.secondLeg?.operatingDate}/${result.secondLeg?.fromStop.orderNumber}/'
          '${result.secondLeg?.toStop.orderNumber}';
      final known = _results!.map(key).toSet();
      final added = next.where((result) => known.add(key(result))).toList();
      setState(() {
        _results = [..._results!, ...added];
        _loadedThrough = date;
        if (added.isEmpty) {
          _moreMessage =
              'Brak nowych połączeń na ${app_date.formatDateDisplay(date)}. Możesz sprawdzić kolejny dzień.';
        }
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _moreFailed = true;
        _moreMessage = error is ApiException && error.statusCode == 429
            ? 'Źródło rozkładów jest przeciążone. Spróbuj ponownie za minutę.'
            : 'Nie udało się pobrać kolejnego dnia. Sprawdź połączenie i spróbuj ponownie.';
      });
    } finally {
      if (mounted && request == _request) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _searchFavoriteRoute(FavoriteRoute favorite) {
    _changed(() {
      _fromStation =
          Station(id: favorite.fromStationId, name: favorite.fromStationName);
      _toStation =
          Station(id: favorite.toStationId, name: favorite.toStationName);
      final now = DateTime.now();
      _selectedDate = DateUtils.dateOnly(now);
      _selectedTime = TimeOfDay.fromDateTime(now);
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final favorite = _fromStation != null &&
        _toStation != null &&
        state.isRouteFavorite(_fromStation!.id, _toStation!.id);
    final canFavorite = _fromStation != null &&
        _toStation != null &&
        _fromStation!.id != _toStation!.id;
    final favoriteButton = canFavorite
        ? IconButton(
            key: const ValueKey('favorite-current-route'),
            tooltip: favorite
                ? 'Usuń trasę z ulubionych'
                : 'Dodaj trasę do ulubionych',
            icon: Icon(
                favorite ? Icons.star_rounded : Icons.star_outline_rounded),
            color: favorite
                ? Colors.amber.shade700
                : theme.colorScheme.onSurfaceVariant,
            onPressed: () =>
                state.toggleFavoriteRoute(_fromStation!, _toStation!))
        : null;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Połączenia kolejowe',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_results == null || _editSearch) ...[
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Text('Zaplanuj podróż',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.75)),
                ),
                child: Row(children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 2, 4),
                    child: Column(children: [
                      StationSearchField(
                          key: const ValueKey('origin-field'),
                          label: 'Skąd jedziesz?',
                          marker: 'A',
                          stations: state.stations,
                          selectedStation: _fromStation,
                          onStationSelected: (s) =>
                              _changed(() => _fromStation = s)),
                      StationSearchField(
                          key: const ValueKey('destination-field'),
                          label: 'Dokąd jedziesz?',
                          marker: 'B',
                          stations: state.stations,
                          selectedStation: _toStation,
                          onStationSelected: (s) =>
                              _changed(() => _toStation = s)),
                    ]),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (favoriteButton != null) favoriteButton,
                      IconButton.filledTonal(
                          tooltip: 'Zamień stacje',
                          onPressed: _swapStations,
                          icon: const Icon(Icons.swap_vert, size: 20)),
                    ]),
                  )
                ]),
              ),
              if (state.isLoading && state.stations.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Wczytywanie stacji…')),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: JourneyField(
                        key: const ValueKey('connection-date'),
                        label: 'Data',
                        value: app_date.formatDateDisplay(_selectedDate),
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate)),
                const SizedBox(width: 10),
                Expanded(
                    child: JourneyField(
                        key: const ValueKey('connection-time'),
                        label: 'Godzina',
                        value: app_date.formatTimeDisplay(
                            _selectedTime.hour, _selectedTime.minute),
                        icon: Icons.schedule,
                        onTap: _pickTime)),
              ]),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: _setNow, child: const Text('Teraz'))),
              const SizedBox(height: 10),
              ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: FilledButton.icon(
                      onPressed: _isSearching ? null : _performSearch,
                      style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('Wyszukaj połączenia',
                          style: TextStyle(fontWeight: FontWeight.bold)))),
            ] else
              _ConnectionSummary(
                  from: _fromStation!.name,
                  to: _toStation!.name,
                  departure: _searchedAt!,
                  favoriteButton: favoriteButton!,
                  onEdit: () => setState(() => _editSearch = true)),
            if (_isSearching)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Expanded(child: Text('Wyszukiwanie połączeń...'))
                  ])),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_error!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onErrorContainer))),
                    ]),
              ),
            if (_results != null)
              ConnectionResults(
                  results: _results!,
                  selectedDeparture: _searchedAt!,
                  showSearchDate: _editSearch,
                  searchKey: _request,
                  loadingMore: _isLoadingMore,
                  moreMessage: _moreMessage,
                  moreFailed: _moreFailed,
                  nextDay: _loadedThrough == null
                      ? null
                      : DateUtils.addDaysToDate(_loadedThrough!, 1),
                  onLoadNextDay: _isSearching ||
                          _loadedThrough == null ||
                          !_loadedThrough!.isBefore(
                              DateUtils.addDaysToDate(DateTime.now(), 60))
                      ? null
                      : _loadNextDay),
            const SizedBox(height: 16),
            if (_results == null && !_isSearching && _error == null)
              ExpansionTile(
                key: const ValueKey('favorite-routes-section'),
                initiallyExpanded: _results == null && !_isSearching,
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(Icons.star_border,
                    size: 20, color: theme.colorScheme.primary),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text('Ulubione trasy',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                children: [
                  if (state.favoriteRoutes.isEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Brak ulubionych tras',
                          style: TextStyle(fontSize: 13)),
                    ),
                    if (_fromStation == null ||
                        _toStation == null ||
                        _fromStation!.id == _toStation!.id)
                      Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 12),
                          child: Text(
                              'Wybierz stacje i zapisz trasę gwiazdką, aby wracać do niej jednym dotknięciem.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant))),
                    if (_fromStation != null &&
                        _toStation != null &&
                        _fromStation!.id != _toStation!.id)
                      Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                              onPressed: () => state.toggleFavoriteRoute(
                                  _fromStation!, _toStation!),
                              child: const Text('Dodaj bieżącą trasę',
                                  style: TextStyle(fontSize: 12)))),
                  ],
                  ...state.favoriteRoutes.map((f) => Row(children: [
                        Expanded(
                            child: InkWell(
                                onTap: () => _searchFavoriteRoute(f),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Text(
                                        '${f.fromStationName} → ${f.toStationName}',
                                        style:
                                            const TextStyle(fontSize: 13))))),
                        IconButton(
                            tooltip: 'Usuń trasę',
                            onPressed: () => state.removeFavoriteRoute(
                                f.fromStationId, f.toStationId),
                            icon: const Icon(Icons.close, size: 18)),
                      ])),
                ],
              ),
            const SizedBox(height: 16),
          ])),
    );
  }
}

class _ConnectionSummary extends StatelessWidget {
  final String from;
  final String to;
  final DateTime departure;
  final VoidCallback onEdit;
  final Widget favoriteButton;

  const _ConnectionSummary({
    required this.from,
    required this.to,
    required this.departure,
    required this.onEdit,
    required this.favoriteButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Icon(Icons.trip_origin,
                            size: 12, color: colors.onSurfaceVariant)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(from,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant))),
                  ]),
                  const SizedBox(height: 7),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.location_on_outlined,
                            size: 14, color: colors.primary)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(to,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700))),
                  ]),
                ])),
            const SizedBox(width: 6),
            favoriteButton,
          ]),
          const SizedBox(height: 4),
          Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(app_date.formatDateDisplay(departure),
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant)),
                ]),
                Text(
                    'Od ${app_date.formatTimeDisplay(departure.hour, departure.minute)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary)),
                Tooltip(
                    message: 'Zmień trasę lub termin',
                    child: TextButton(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: const Text('Zmień'))),
              ]),
        ]),
      ),
    );
  }
}
