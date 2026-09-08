import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'api/plk_api.dart';
import 'models/models.dart';
import 'services/cache_service.dart';
import 'services/bounded_cache.dart';
import 'services/location_service.dart';
import 'utils/date_utils.dart' as app_date;

class AppState extends ChangeNotifier {
  bool _disposed = false;
  bool _clientInitialized = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_clientInitialized) _apiClient.close();
    super.dispose();
  }

  late final ApiClient _apiClient;
  late final PlkApi api;
  late final CacheService cache;
  late final LocationService locationService;

  List<Station> stations = [];
  Map<String, String> carrierNames = {}; // code -> name
  Map<String, String> categoryNames = {}; // code -> name
  Map<int, String> stopTypeNames = {}; // id -> description
  Map<int, String> stationNames = {}; // id -> name

  // Start Screen / Tablica State
  Station? currentStation;
  bool isStationFromGps = false;
  bool isDetectingLocation = false;
  String? locationMessage;
  List<StationBoardItem> stationDepartures = [];
  List<StationBoardItem> stationArrivals = [];
  DateTime? stationBoardLastUpdated;
  bool isStationBoardLoading = false;
  bool isStationBoardLoadingMore = false;
  bool stationBoardCanLoadMore = true;
  String? stationBoardError;

  // Favorites
  List<FavoriteStation> favoriteStations = [];
  List<FavoriteRoute> favoriteRoutes = [];
  List<Station> recentStations = [];

  // Theme
  ThemeMode themeMode = ThemeMode.system;
  bool liquidGlass = false;

  bool isLoading = false;
  String? error;
  bool _initialized = false;
  bool _servicesReady = false;
  Map<String, dynamic>? _cachedDisruptions;
  DateTime? _disruptionsLoadedAt;
  Map<String, dynamic>? get cachedDisruptions => _cachedDisruptions;

  int? get hourlyRemaining => _apiClient.hourlyRemaining;
  int? get dailyRemaining => _apiClient.dailyRemaining;

  Future<void> init() async {
    _apiClient = ApiClient();
    _clientInitialized = true;
    api = PlkApi(_apiClient);
    cache = CacheService();
    await cache.init();
    locationService = LocationService();
    _servicesReady = true;
    _cachedDisruptions = cache.loadDisruptions();

    _loadThemeMode();
    _loadFavorites();
  }

  void _loadThemeMode() {
    liquidGlass = cache.loadInterfaceStyle() == 'glass';
    final savedMode = cache.loadThemeMode();
    if (savedMode != null) {
      if (savedMode == 'light') themeMode = ThemeMode.light;
      if (savedMode == 'dark') themeMode = ThemeMode.dark;
      if (savedMode == 'system') themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await cache.saveThemeMode(mode.name);
    notifyListeners();
  }

  Future<void> setLiquidGlass(bool enabled) async {
    liquidGlass = enabled;
    notifyListeners();
    await cache.saveInterfaceStyle(enabled ? 'glass' : 'classic');
  }

  void _loadFavorites() {
    final favStationsJson = cache.loadFavoriteStations();
    favoriteStations =
        favStationsJson.map((e) => FavoriteStation.fromJson(e)).toList();

    final favRoutesJson = cache.loadFavoriteRoutes();
    favoriteRoutes =
        favRoutesJson.map((e) => FavoriteRoute.fromJson(e)).toList();
    recentStations =
        cache.loadRecentStations().map((e) => Station.fromJson(e)).toList();
  }

  Future<void> _rememberRecentStation(Station station) async {
    recentStations = [
      station,
      ...recentStations.where((candidate) => candidate.id != station.id),
    ].take(6).toList();
    await cache.saveRecentStations(
        recentStations.map((station) => station.toJson()).toList());
  }

  bool isStationFavorite(int stationId) {
    return favoriteStations.any((s) => s.id == stationId);
  }

  Future<void> toggleFavoriteStation(Station station) async {
    final index = favoriteStations.indexWhere((s) => s.id == station.id);
    if (index >= 0) {
      favoriteStations.removeAt(index);
    } else {
      favoriteStations.insert(
          0, FavoriteStation(id: station.id, name: station.name));
    }
    await cache
        .saveFavoriteStations(favoriteStations.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeFavoriteStation(int stationId) async {
    favoriteStations.removeWhere((s) => s.id == stationId);
    await cache
        .saveFavoriteStations(favoriteStations.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  bool isRouteFavorite(int fromId, int toId) {
    return favoriteRoutes
        .any((r) => r.fromStationId == fromId && r.toStationId == toId);
  }

  Future<void> toggleFavoriteRoute(Station from, Station to) async {
    final index = favoriteRoutes.indexWhere(
      (r) => r.fromStationId == from.id && r.toStationId == to.id,
    );
    if (index >= 0) {
      favoriteRoutes.removeAt(index);
    } else {
      favoriteRoutes.insert(
        0,
        FavoriteRoute(
          fromStationId: from.id,
          fromStationName: from.name,
          toStationId: to.id,
          toStationName: to.name,
        ),
      );
    }
    await cache
        .saveFavoriteRoutes(favoriteRoutes.map((r) => r.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeFavoriteRoute(int fromId, int toId) async {
    favoriteRoutes.removeWhere(
      (r) => r.fromStationId == fromId && r.toStationId == toId,
    );
    await cache
        .saveFavoriteRoutes(favoriteRoutes.map((r) => r.toJson()).toList());
    notifyListeners();
  }

  Future<void> checkDataVersion() async {
    try {
      final versionData = await api.getDataVersion();
      final newVersion = versionData['dataVersion'] as String?;
      if (newVersion == null) return;

      final cachedVersion = cache.loadDataVersion();
      if (cachedVersion != null && cachedVersion != newVersion) {
        await cache.clearDictionaryCache();
      }
      await cache.saveDataVersion(newVersion);
    } catch (e) {
      debugPrint('[AppState] checkDataVersion error: $e');
    }
  }

  Future<void> loadDictionaries() async {
    if (_initialized && stations.isNotEmpty) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await checkDataVersion();

      // Load stations
      final cachedStations = cache.loadStations();
      if (cachedStations != null && cachedStations.isNotEmpty) {
        stations = cachedStations
            .map((e) => Station.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final data = await api.getStations();
        final stationsList = data['stations'] as List<dynamic>? ?? [];
        stations = stationsList
            .map((e) => Station.fromJson(e as Map<String, dynamic>))
            .toList();
        await cache.saveStations(stationsList);
      }

      // Build station name lookup
      stationNames.clear();
      for (final s in stations) {
        stationNames[s.id] = s.name;
      }

      // Load carriers
      final cachedCarriers = cache.loadCarriers();
      if (cachedCarriers != null && cachedCarriers.isNotEmpty) {
        carrierNames = {};
        for (final c in cachedCarriers) {
          final map = c as Map<String, dynamic>;
          carrierNames[map['code'] as String? ?? ''] =
              map['name'] as String? ?? '';
        }
      } else {
        final data = await api.getCarriers();
        final carriersList = data['carriers'] as List<dynamic>? ?? [];
        carrierNames = {};
        for (final c in carriersList) {
          final map = c as Map<String, dynamic>;
          carrierNames[map['code'] as String? ?? ''] =
              map['name'] as String? ?? '';
        }
        await cache.saveCarriers(carriersList);
      }

      // Load commercial categories
      final cachedCategories = cache.loadCategories();
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        categoryNames = {};
        for (final c in cachedCategories) {
          final map = c as Map<String, dynamic>;
          categoryNames[map['code'] as String? ?? ''] =
              map['name'] as String? ?? '';
        }
      } else {
        final data = await api.getCommercialCategories();
        final categoriesList =
            data['commercialCategories'] as List<dynamic>? ?? [];
        categoryNames = {};
        for (final c in categoriesList) {
          final map = c as Map<String, dynamic>;
          categoryNames[map['code'] as String? ?? ''] =
              map['name'] as String? ?? '';
        }
        await cache.saveCategories(categoriesList);
      }

      // Load stop types
      final cachedStopTypes = cache.loadStopTypes();
      if (cachedStopTypes != null && cachedStopTypes.isNotEmpty) {
        stopTypeNames = {};
        for (final s in cachedStopTypes) {
          final map = s as Map<String, dynamic>;
          stopTypeNames[map['id'] as int? ?? 0] =
              map['description'] as String? ?? '';
        }
      } else {
        final data = await api.getStopTypes();
        final stopTypesList = data['stopTypes'] as List<dynamic>? ?? [];
        stopTypeNames = {};
        for (final s in stopTypesList) {
          final map = s as Map<String, dynamic>;
          stopTypeNames[map['id'] as int? ?? 0] =
              map['description'] as String? ?? '';
        }
        await cache.saveStopTypes(stopTypesList);
      }

      _initialized = true;

      // On first dictionary load, restore last selected station or detect GPS
      await _initializeInitialStation();
    } catch (e) {
      error = e.toString();
      debugPrint('[AppState] loadDictionaries error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeInitialStation() async {
    final saved = cache.loadLastSelectedStation() ?? cache.loadNearestStation();
    if (currentStation == null && saved != null) {
      final id = saved['id'] as int?;
      final name = saved['name'] as String?;
      if (id != null && name != null) {
        currentStation = Station(id: id, name: name);
      }
    }
    if (currentStation == null && stations.isNotEmpty) {
      currentStation = stations.firstWhere(
          (s) => s.name.toUpperCase().contains('WARSZAWA CENTRALNA'),
          orElse: () => stations.first);
    }
    if (currentStation != null) unawaited(loadStationBoard(currentStation!.id));
    // Keep the saved board usable while GPS runs in the background.
    unawaited(detectNearestStation());
  }

  int _stationSelectionVersion = 0;

  /// Detect nearest station using LocationService and OSM
  Future<void> detectNearestStation({bool forceRefresh = true}) async {
    if (isDetectingLocation) return;
    final selectionVersion = _stationSelectionVersion;
    isDetectingLocation = true;
    locationMessage = null;
    notifyListeners();

    try {
      if (!forceRefresh) {
        final cached = cache.loadNearestStation();
        if (cached != null) {
          final id = cached['id'] as int?;
          final name = cached['name'] as String?;
          if (id != null && name != null) {
            currentStation = Station(id: id, name: name);
            isStationFromGps = true;
            isDetectingLocation = false;
            notifyListeners();
            loadStationBoard(id);
            return;
          }
        }
      }

      final perm = await locationService.checkPermission();
      if (perm == LocationPermissionStatus.serviceDisabled) {
        locationMessage = 'Lokalizacja w telefonie jest wyłączona';
        isDetectingLocation = false;
        notifyListeners();
        return;
      }

      if (perm == LocationPermissionStatus.denied) {
        final req = await locationService.requestPermission();
        if (req != LocationPermissionStatus.granted) {
          locationMessage = 'Brak zgody na dostęp do lokalizacji';
          isDetectingLocation = false;
          notifyListeners();
          return;
        }
      } else if (perm == LocationPermissionStatus.permanentlyDenied) {
        locationMessage =
            'Uprawnienie lokalizacji zostało zablokowane w ustawieniach';
        isDetectingLocation = false;
        notifyListeners();
        return;
      }

      final nearestResult = await locationService.findNearestStation(stations);
      if (selectionVersion != _stationSelectionVersion) return;
      if (nearestResult != null) {
        currentStation = nearestResult.station;
        _activateStationBoard(nearestResult.station.id);
        isStationFromGps = true;
        await cache.saveNearestStation(
          nearestResult.station.id,
          nearestResult.station.name,
          nearestResult.userLatitude,
          nearestResult.userLongitude,
        );
        loadStationBoard(nearestResult.station.id);
      } else {
        locationMessage = 'Nie odnaleziono stacji kolejowej w pobliżu';
      }
    } catch (e) {
      debugPrint('[AppState] detectNearestStation error: $e');
      locationMessage = 'Nie udało się ustalić najbliższej stacji';
    } finally {
      isDetectingLocation = false;
      notifyListeners();
    }
  }

  /// Manually select station for station board
  Future<void> selectManualStation(Station station) async {
    _stationSelectionVersion++;
    currentStation = station;
    _activateStationBoard(station.id);
    isStationFromGps = false;
    locationMessage = null;
    await cache.saveLastSelectedStation(station.id, station.name);
    await _rememberRecentStation(station);
    notifyListeners();
    loadStationBoard(station.id);
  }

  // Memory cache for station board data to avoid rapid re-fetches
  final _stationBoardOpsCache = BoundedCache<int, Map<String, dynamic>>(3);
  final _stationBoardOpsCacheTime = BoundedCache<int, DateTime>(3);
  final _stationBoardSchedCache = BoundedCache<int, Map<String, dynamic>>(3);
  final _stationBoardSchedCacheTime = BoundedCache<int, DateTime>(3);
  final _stationBoardScheduleDayCache =
      BoundedCache<String, Map<String, dynamic>>(6);
  final Map<String, Future<void>> _stationBoardMoreInFlight = {};
  final _stationBoardLoadedThrough = BoundedCache<int, DateTime>(64);
  int _stationBoardLoadGeneration = 0;
  int? _boardStationId;
  final Map<
      int,
      ({
        List<StationBoardItem> departures,
        List<StationBoardItem> arrivals,
        DateTime? updated,
        bool canLoadMore
      })> _boardsByStation = BoundedCache(3);

  void _saveBoardSnapshot() {
    if (_boardStationId case final id?) {
      _boardsByStation[id] = (
        departures: [...stationDepartures],
        arrivals: [...stationArrivals],
        updated: stationBoardLastUpdated,
        canLoadMore: stationBoardCanLoadMore
      );
    }
  }

  void _activateStationBoard(int stationId) {
    if (_boardStationId == stationId) return;
    _saveBoardSnapshot();
    _boardStationId = stationId;
    _stationBoardLoadGeneration++;
    final saved = _boardsByStation[stationId];
    stationDepartures = [...?saved?.departures];
    stationArrivals = [...?saved?.arrivals];
    stationBoardLastUpdated = saved?.updated;
    stationBoardCanLoadMore = saved?.canLoadMore ?? true;
    stationBoardError = null;
    isStationBoardLoadingMore = false;
  }

  DateTime _boardItemDateTime(StationBoardItem item) {
    return app_date.scheduleDateTime(
            item.actualTime ?? item.plannedTime ?? item.time,
            item.operatingDate) ??
        DateTime.tryParse(item.operatingDate) ??
        DateTime(2100);
  }

  void _sortBoardItems() {
    stationDepartures
        .sort((a, b) => _boardItemDateTime(a).compareTo(_boardItemDateTime(b)));
    stationArrivals
        .sort((a, b) => _boardItemDateTime(a).compareTo(_boardItemDateTime(b)));
  }

  /// Load departures and arrivals for station board
  Future<void> loadStationBoard(int stationId) async {
    _activateStationBoard(stationId);
    final requestGeneration = ++_stationBoardLoadGeneration;
    isStationBoardLoading = true;
    isStationBoardLoadingMore = false;
    stationBoardCanLoadMore = true;
    stationBoardError = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      // Check memory cache
      Map<String, dynamic>? opsResponse;
      Map<String, dynamic>? schedResponse;

      final opsTime = _stationBoardOpsCacheTime[stationId];
      if (opsTime != null &&
          DateUtils.isSameDay(opsTime, now) &&
          now.difference(opsTime).inSeconds < 30) {
        opsResponse = _stationBoardOpsCache[stationId];
        if (kDebugMode) {
          debugPrint('[PDP] cache HIT operations for station $stationId');
        }
      }

      final schedTime = _stationBoardSchedCacheTime[stationId];
      if (schedTime != null &&
          DateUtils.isSameDay(schedTime, now) &&
          now.difference(schedTime).inMinutes < 15) {
        schedResponse = _stationBoardSchedCache[stationId];
        if (kDebugMode) {
          debugPrint('[PDP] cache HIT schedules for station $stationId');
        }
      }

      // Fetch what is missing in parallel
      final futures = <Future>[];

      late Future<Map<String, dynamic>> opsFuture;
      if (opsResponse == null) {
        opsFuture = api.getOperations(
          stations: stationId.toString(),
          withPlanned: true,
          fullRoutes: true, // Needed for destination/origin logic
        );
        futures.add(opsFuture.then((res) {
          opsResponse = res;
          _stationBoardOpsCache[stationId] = res;
          _stationBoardOpsCacheTime[stationId] = DateTime.now();
          if (kDebugMode) {
            debugPrint('[PDP] cache MISS operations for station $stationId');
          }
        }));
      }

      late Future<Map<String, dynamic>> schedFuture;
      if (schedResponse == null) {
        schedFuture = api.getSchedules(
          dateFrom: app_date.formatDateForApi(now),
          dateTo: app_date.formatDateForApi(now),
          stations: stationId.toString(),
          fullRoute: true,
        );
        futures.add(schedFuture.then((res) {
          schedResponse = res;
          _stationBoardSchedCache[stationId] = res;
          _stationBoardSchedCacheTime[stationId] = DateTime.now();
          if (kDebugMode) {
            debugPrint('[PDP] cache MISS schedules for station $stationId');
          }
        }));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      // A different station was selected while this request was in flight.
      // Ignore its response instead of replacing the current board.
      if (requestGeneration != _stationBoardLoadGeneration) return;

      final rawTrains = opsResponse!['trains'] as List<dynamic>? ?? [];
      final rawSchedules = schedResponse!['routes'] as List<dynamic>? ?? [];

      // Build a map of scheduleId_orderId -> RouteDto for quick lookup
      final Map<String, Map<String, dynamic>> scheduleData = {};
      for (final r in rawSchedules) {
        final route = r as Map<String, dynamic>;
        final schedId = route['scheduleId'];
        final ordId = route['orderId'];
        scheduleData['${schedId}_$ordId'] = route;
      }

      // An operation can be published before the station's bulk schedule is
      // updated. Resolve only missing, currently relevant routes by identity.
      final missingRoutes = <String, TrainOperation>{};
      for (final raw in rawTrains.whereType<Map<String, dynamic>>()) {
        final operation = TrainOperation.fromJson(raw);
        final key = '${operation.scheduleId}_${operation.orderId}';
        if (scheduleData.containsKey(key)) continue;
        if (operation.stations.any((stop) {
          if (stop.stationId != stationId) return false;
          return [
            stop.actualDeparture,
            stop.plannedDeparture,
            stop.actualArrival,
            stop.plannedArrival
          ].any((time) {
            final value = app_date.parsePdpDateTime(time);
            return value != null &&
                !value.isBefore(now.subtract(const Duration(hours: 1))) &&
                value.isBefore(now.add(const Duration(days: 1)));
          });
        })) {
          missingRoutes[key] = operation;
        }
      }
      final missing = missingRoutes.entries.toList();
      for (var start = 0; start < missing.length; start += 4) {
        await Future.wait(missing.skip(start).take(4).map((entry) async {
          try {
            scheduleData[entry.key] = await getScheduleRoute(
                entry.value.scheduleId, entry.value.orderId,
                operatingDate: entry.value.operatingDate);
          } catch (_) {/* Preserve the available operation times. */}
        }));
      }
      if (requestGeneration != _stationBoardLoadGeneration) return;

      final List<StationBoardItem> departures = [];
      final List<StationBoardItem> arrivals = [];

      for (final t in rawTrains) {
        final op = TrainOperation.fromJson(t as Map<String, dynamic>);
        final schedKey = '${op.scheduleId}_${op.orderId}';
        final sched = scheduleData[schedKey];

        // 1. Try to find departure/arrival train number and platform/track in the stations list from schedule
        String? depTrainNum;
        String? arrTrainNum;
        String? depPlatform;
        String? arrPlatform;
        String? depTrack;
        String? arrTrack;
        Map<String, dynamic>? scheduleStop;

        if (sched != null && sched['stations'] != null) {
          final stations = sched['stations'] as List<dynamic>;
          for (final st in stations) {
            final stationMap = st as Map<String, dynamic>;
            if (stationMap['stationId'] == stationId) {
              scheduleStop = stationMap;
              depTrainNum = stationMap['departureTrainNumber'] as String?;
              arrTrainNum = stationMap['arrivalTrainNumber'] as String?;
              depPlatform = stationMap['departurePlatform'] as String? ??
                  stationMap['platform'] as String?;
              arrPlatform = stationMap['arrivalPlatform'] as String? ??
                  stationMap['platform'] as String?;
              depTrack = stationMap['departureTrack'] as String? ??
                  stationMap['track'] as String?;
              arrTrack = stationMap['arrivalTrack'] as String? ??
                  stationMap['track'] as String?;
              break;
            }
          }
        }

        // Fallbacks for train number
        final natNum = sched?['nationalNumber'] as String?;
        final intDepNum = sched?['internationalDepartureNumber'] as String?;
        final intArrNum = sched?['internationalArrivalNumber'] as String?;

        final catSymbol = sched?['commercialCategorySymbol'] as String? ?? '';
        final carrierCode = sched?['carrierCode'] as String? ?? '';
        final trainNameRaw = sched?['name'] as String? ?? '';
        final carrierName = carrierCode.isNotEmpty
            ? (carrierNames[carrierCode] ?? carrierCode)
            : '';

        for (int i = 0; i < op.stations.length; i++) {
          final st = op.stations[i];
          if (st.stationId == stationId) {
            String? planned(String? live, String field, String dayField) {
              final value = app_date.parsePdpDateTime(live) ??
                  app_date.scheduleDateTime(
                      scheduleStop?[field]?.toString(), op.operatingDate,
                      day: (scheduleStop?[dayField] as num?)?.toInt());
              return value?.toIso8601String();
            }

            final plannedDeparture =
                planned(st.plannedDeparture, 'departureTime', 'departureDay');
            final plannedArrival =
                planned(st.plannedArrival, 'arrivalTime', 'arrivalDay');
            final actualDeparture = app_date
                .parsePdpDateTime(st.actualDeparture)
                ?.toIso8601String();
            final actualArrival =
                app_date.parsePdpDateTime(st.actualArrival)?.toIso8601String();
            final depTime = actualDeparture ?? plannedDeparture;
            final arrTime = actualArrival ?? plannedArrival;

            // Destination station (last stop)
            String destination = 'Nieznana stacja';
            String origin = 'Nieznana stacja';
            if (op.stations.isNotEmpty) {
              destination = getStationName(op.stations.last.stationId);
              origin = getStationName(op.stations.first.stationId);
            }

            // Display train number logic
            final departureDisplayNumber =
                depTrainNum ?? natNum ?? intDepNum ?? intArrNum ?? '';
            final arrivalDisplayNumber =
                arrTrainNum ?? natNum ?? intArrNum ?? intDepNum ?? '';

            // Effective platform & track
            final effectiveDepPlatform =
                (st.platform != null && st.platform!.isNotEmpty)
                    ? st.platform
                    : depPlatform;
            final effectiveDepTrack = (st.track != null && st.track!.isNotEmpty)
                ? st.track
                : depTrack;
            final effectiveArrPlatform =
                (st.platform != null && st.platform!.isNotEmpty)
                    ? st.platform
                    : arrPlatform;
            final effectiveArrTrack = (st.track != null && st.track!.isNotEmpty)
                ? st.track
                : arrTrack;

            // Keep today's earlier trains available for the expandable section.
            if (depTime != null && i < op.stations.length - 1) {
              final depDt = DateTime.tryParse(depTime)?.toLocal();
              final isOld = depDt == null ||
                  depDt.isBefore(DateUtils.dateOnly(now)) ||
                  (!DateUtils.isSameDay(depDt, now) &&
                      op.operatingDate != app_date.formatDateForApi(now));

              if (!isOld) {
                departures.add(StationBoardItem(
                  time: app_date.formatDateTime(depTime),
                  trainNumber: departureDisplayNumber,
                  trainName: trainNameRaw,
                  trainCategory: catSymbol,
                  carrier: carrierName,
                  direction: destination,
                  delayMinutes: st.departureDelayMinutes ??
                      (actualDeparture != null && plannedDeparture != null
                          ? app_date.timeDelay(
                              plannedDeparture, actualDeparture, null,
                              operatingDate: op.operatingDate)
                          : null),
                  isCancelled: st.isCancelled || op.trainStatus == 'X',
                  status: op.statusText,
                  scheduleId: op.scheduleId,
                  orderId: op.orderId,
                  operatingDate: op.operatingDate,
                  platform: effectiveDepPlatform,
                  track: effectiveDepTrack,
                  plannedTime: plannedDeparture,
                  actualTime: actualDeparture,
                  raw: op.raw,
                ));
              }
            }

            // Arrivals
            if (arrTime != null && i > 0) {
              final arrDt = DateTime.tryParse(arrTime)?.toLocal();
              final isOld = arrDt == null ||
                  arrDt.isBefore(DateUtils.dateOnly(now)) ||
                  (!DateUtils.isSameDay(arrDt, now) &&
                      op.operatingDate != app_date.formatDateForApi(now));

              if (!isOld) {
                arrivals.add(StationBoardItem(
                  time: app_date.formatDateTime(arrTime),
                  trainNumber: arrivalDisplayNumber,
                  trainName: trainNameRaw,
                  trainCategory: catSymbol,
                  carrier: carrierName,
                  direction: origin,
                  delayMinutes: st.arrivalDelayMinutes ??
                      (actualArrival != null && plannedArrival != null
                          ? app_date.timeDelay(
                              plannedArrival, actualArrival, null,
                              operatingDate: op.operatingDate)
                          : null),
                  isCancelled: st.isCancelled || op.trainStatus == 'X',
                  status: op.statusText,
                  scheduleId: op.scheduleId,
                  orderId: op.orderId,
                  operatingDate: op.operatingDate,
                  platform: effectiveArrPlatform,
                  track: effectiveArrTrack,
                  plannedTime: plannedArrival,
                  actualTime: actualArrival,
                  raw: op.raw,
                ));
              }
            }
          }
        }
      }

      _appendScheduledBoardItems(
          Station(id: stationId, name: getStationName(stationId)),
          DateUtils.dateOnly(now),
          schedResponse!,
          departures,
          arrivals);
      stationDepartures = departures;
      stationArrivals = arrivals;
      _sortBoardItems();
      stationBoardLastUpdated = DateTime.now();
      _stationBoardLoadedThrough[stationId] = DateUtils.dateOnly(now);
      _saveBoardSnapshot();
    } catch (e) {
      if (requestGeneration == _stationBoardLoadGeneration) {
        stationBoardError =
            'Nie udało się odświeżyć tablicy. Spróbuj ponownie.';
      }
      debugPrint('[AppState] loadStationBoard error: $e');
    } finally {
      if (requestGeneration == _stationBoardLoadGeneration) {
        isStationBoardLoading = false;
        notifyListeners();
      }
    }
  }

  void _appendScheduledBoardItems(
      Station station,
      DateTime date,
      Map<String, dynamic> response,
      List<StationBoardItem> departures,
      List<StationBoardItem> arrivals) {
    final routes = response['routes'] as List<dynamic>? ?? const [];
    final knownDepartures = {
      for (final item in departures)
        '${item.scheduleId}/${item.orderId}/${item.operatingDate}/d'
    };
    final knownArrivals = {
      for (final item in arrivals)
        '${item.scheduleId}/${item.orderId}/${item.operatingDate}/a'
    };
    for (final rawRoute in routes.whereType<Map<String, dynamic>>()) {
      final operatingDates = rawRoute['operatingDates'];
      if (operatingDates is List &&
          !operatingDates.contains(app_date.formatDateForApi(date))) {
        continue;
      }
      final scheduleId = (rawRoute['scheduleId'] as num?)?.toInt() ?? 0;
      final orderId = (rawRoute['orderId'] as num?)?.toInt() ?? 0;
      final routeStations = rawRoute['stations'] as List<dynamic>? ?? const [];
      if (routeStations.isEmpty) continue;
      final first = routeStations.first as Map<String, dynamic>;
      final last = routeStations.last as Map<String, dynamic>;
      final category = rawRoute['commercialCategorySymbol']?.toString() ?? '';
      final carrierCode = rawRoute['carrierCode']?.toString() ?? '';
      final carrier = carrierNames[carrierCode] ?? carrierCode;
      final name = rawRoute['name']?.toString() ?? '';
      for (final rawStop in routeStations.whereType<Map<String, dynamic>>()) {
        if ((rawStop['stationId'] as num?)?.toInt() != station.id) continue;
        StationBoardItem makeItem({required bool arrival}) {
          final time =
              (arrival ? rawStop['arrivalTime'] : rawStop['departureTime'])
                  ?.toString();
          final platform = (arrival
                      ? rawStop['arrivalPlatform']
                      : rawStop['departurePlatform'])
                  ?.toString() ??
              rawStop['platform']?.toString();
          final track =
              (arrival ? rawStop['arrivalTrack'] : rawStop['departureTrack'])
                      ?.toString() ??
                  rawStop['track']?.toString();
          final number = (arrival
                      ? rawStop['arrivalTrainNumber']
                      : rawStop['departureTrainNumber'])
                  ?.toString() ??
              rawRoute['nationalNumber']?.toString() ??
              '';
          return StationBoardItem(
            time: app_date.formatTimeSafe(time),
            trainNumber: number,
            trainName: name,
            trainCategory: category,
            carrier: carrier,
            direction: getStationName(
                ((arrival ? first : last)['stationId'] as num?)?.toInt() ?? 0),
            scheduleId: scheduleId,
            orderId: orderId,
            operatingDate: app_date.formatDateForApi(date),
            platform: platform,
            track: track,
            plannedTime: app_date
                .scheduleDateTime(time, app_date.formatDateForApi(date),
                    day: (rawStop[arrival ? 'arrivalDay' : 'departureDay']
                            as num?)
                        ?.toInt())
                ?.toIso8601String(),
            raw: rawRoute,
          );
        }

        if (rawStop['departureTime'] != null) {
          final item = makeItem(arrival: false);
          if (knownDepartures
              .add('$scheduleId/$orderId/${item.operatingDate}/d')) {
            departures.add(item);
          }
        }
        if (rawStop['arrivalTime'] != null) {
          final item = makeItem(arrival: true);
          if (knownArrivals
              .add('$scheduleId/$orderId/${item.operatingDate}/a')) {
            arrivals.add(item);
          }
        }
      }
    }
  }

  /// Lazily append one operating day of schedule data to the station board.
  /// Operations are deliberately not fetched for tomorrow: they are real-time
  /// data for the current day and would only increase API traffic.
  Future<void> loadNextStationBoardDay() async {
    final station = currentStation;
    if (station == null ||
        isStationBoardLoadingMore ||
        !stationBoardCanLoadMore) {
      return;
    }
    // A live overnight train is not proof that its whole day was fetched.
    final date = DateUtils.addDaysToDate(
        _stationBoardLoadedThrough[station.id] ?? DateTime.now(), 1);
    final dateKey = app_date.formatDateForApi(date);
    final cacheKey = '${station.id}/$dateKey';
    final active = _stationBoardMoreInFlight[cacheKey];
    if (active != null) return active;

    final future = _loadNextStationBoardDay(station, date, cacheKey);
    _stationBoardMoreInFlight[cacheKey] = future;
    try {
      await future;
    } finally {
      _stationBoardMoreInFlight.remove(cacheKey);
    }
  }

  Future<void> _loadNextStationBoardDay(
      Station station, DateTime date, String cacheKey) async {
    final generation = _stationBoardLoadGeneration;
    isStationBoardLoadingMore = true;
    stationBoardError = null;
    notifyListeners();
    try {
      final response = _stationBoardScheduleDayCache[cacheKey] ??
          await api.getSchedules(
            dateFrom: app_date.formatDateForApi(date),
            dateTo: app_date.formatDateForApi(date),
            stations: station.id.toString(),
            fullRoute: true,
          );
      _stationBoardScheduleDayCache[cacheKey] = response;
      final departures = [...stationDepartures];
      final arrivals = [...stationArrivals];
      _appendScheduledBoardItems(station, date, response, departures, arrivals);
      if (currentStation?.id != station.id ||
          generation != _stationBoardLoadGeneration) {
        return;
      }
      stationDepartures = departures;
      stationArrivals = arrivals;
      _stationBoardLoadedThrough[station.id] = date;
      stationBoardCanLoadMore =
          date.isBefore(DateUtils.addDaysToDate(DateTime.now(), 60));
      _sortBoardItems();
      _saveBoardSnapshot();
    } catch (e) {
      if (currentStation?.id == station.id &&
          generation == _stationBoardLoadGeneration) {
        stationBoardError =
            'Nie udało się pobrać kolejnego dnia. Spróbuj ponownie.';
      }
      debugPrint('[AppState] loadNextStationBoardDay error: $e');
    } finally {
      if (generation == _stationBoardLoadGeneration) {
        isStationBoardLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Normalize query for train number (extract pure number, e.g. 'IC 5410' -> '5410')
  static String normalizeTrainNumber(String query) {
    final cleaned = query.trim();
    final match = RegExp(r'\d+').firstMatch(cleaned);
    if (match != null) {
      return match.group(0)!;
    }
    return cleaned.toUpperCase();
  }

  /// Normalizes train name for search (lowercase, polish diacritics stripped, whitespace collapsed)
  static String normalizeText(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    const polish = 'ąćęłńóśźż';
    const latin = 'acelnoszz';
    for (int i = 0; i < polish.length; i++) {
      s = s.replaceAll(polish[i], latin[i]);
    }
    return s;
  }

  /// Search train by number or name strictly against real API records for a specific date
  Future<List<TrainSearchResult>> searchTrainByNumber(String query,
      {DateTime? date}) async {
    final searchDate = date ?? DateTime.now();
    final dateStr = app_date.formatDateForApi(searchDate);
    final rawQuery = query.trim();
    if (rawQuery.isEmpty) return [];

    final normalizedQuery = normalizeText(rawQuery);
    final queryDigits = RegExp(r'^\d+$').firstMatch(rawQuery)?.group(0) ??
        RegExp(r'\d+').firstMatch(rawQuery)?.group(0);

    // Check cached routes index for this date
    List<dynamic>? rawRoutes = cache.loadTrainIndex(dateStr);
    if (rawRoutes == null || rawRoutes.isEmpty) {
      try {
        final schedulesResp = await api.getSchedules(
          dateFrom: dateStr,
          dateTo: dateStr,
          fullRoute: true,
        );
        rawRoutes = schedulesResp['routes'] as List<dynamic>? ?? [];
        if (rawRoutes.isNotEmpty) {
          await cache.saveTrainIndex(dateStr, rawRoutes);
        }
      } catch (e) {
        debugPrint('[AppState] searchTrainByNumber fetch schedules error: $e');
        rethrow;
      }
    }

    final List<TrainSearchResult> results = [];
    _rememberRouteMetadata(dateStr, rawRoutes);
    final Set<String> seenKeys =
        {}; // Deduplication key: scheduleId_orderId_operatingDate

    for (final r in rawRoutes) {
      if (r is! Map<String, dynamic>) continue;
      final route = TrainRoute.fromJson(r);

      // 1. Mandatory operating date verification: train MUST operate on dateStr
      if (!route.operatingDates.contains(dateStr)) {
        debugPrint(
            '[AppState] Skipped invalid train result: ${route.scheduleId}/${route.orderId} does not operate on $dateStr');
        continue;
      }

      // 2. Must have valid stations route
      if (route.stations.isEmpty) {
        debugPrint(
            '[AppState] Skipped invalid train result: ${route.scheduleId}/${route.orderId} has empty stations');
        continue;
      }

      final natNum = route.nationalNumber?.trim();
      final rawName = route.name?.trim();

      bool isMatch = false;

      // A. Exact train number search if user entered digits (e.g. "5410" or "IC 5410")
      if (queryDigits != null && queryDigits.isNotEmpty) {
        // Check nationalNumber (primary)
        if (natNum != null && natNum.isNotEmpty && natNum == queryDigits) {
          isMatch = true;
        } else {
          // Check arrival/departure train number on stops
          for (final st in route.stations) {
            if (st.departureTrainNumber?.trim() == queryDigits ||
                st.arrivalTrainNumber?.trim() == queryDigits) {
              isMatch = true;
              break;
            }
          }
        }
      }

      // B. Train name search strictly in route.name if name exists
      if (!isMatch &&
          rawName != null &&
          rawName.isNotEmpty &&
          normalizedQuery.length >= 2) {
        final normName = normalizeText(rawName);
        if (normName == normalizedQuery || normName.contains(normalizedQuery)) {
          isMatch = true;
        }
      }

      if (isMatch) {
        // Deduplication key: scheduleId_orderId_operatingDate
        final dedupeKey = '${route.scheduleId}_${route.orderId}_$dateStr';
        if (seenKeys.contains(dedupeKey)) continue;
        seenKeys.add(dedupeKey);

        // Route origin and destination from full real route
        final firstStop = route.stations.first;
        final lastStop = route.stations.last;

        final fromName = getStationName(firstStop.stationId);
        final toName = getStationName(lastStop.stationId);

        // Real departure and arrival times from specific run
        final depTime = firstStop.departureTime != null
            ? app_date.formatTimeSpan(firstStop.departureTime)
            : (firstStop.arrivalTime != null
                ? app_date.formatTimeSpan(firstStop.arrivalTime)
                : '--:--');
        final arrTime = lastStop.arrivalTime != null
            ? app_date.formatTimeSpan(lastStop.arrivalTime)
            : (lastStop.departureTime != null
                ? app_date.formatTimeSpan(lastStop.departureTime)
                : '--:--');

        // Effective displayed number: strictly from API, NEVER the user query!
        final displayNumber = (natNum != null && natNum.isNotEmpty)
            ? natNum
            : (firstStop.departureTrainNumber?.trim() ??
                firstStop.arrivalTrainNumber?.trim() ??
                '');

        final result = TrainSearchResult(
          scheduleId: route.scheduleId,
          orderId: route.orderId,
          nationalNumber: displayNumber,
          trainName: rawName,
          carrierCode: route.carrierCode,
          carrierName: getCarrierName(route.carrierCode),
          category: route.commercialCategorySymbol,
          fromStationName: fromName,
          toStationName: toName,
          departureTime: depTime,
          arrivalTime: arrTime,
          operatingDates: route.operatingDates,
          operatingDate: dateStr,
          route: route,
        );

        // Debug log source of result as required
        debugPrint(
            '[TrainSearch] Result: scheduleId=${result.scheduleId}, orderId=${result.orderId}, nationalNumber=${result.nationalNumber}, name=${result.trainName}, operatingDate=${result.operatingDate}, firstStation=${result.fromStationName}, lastStation=${result.toStationName}');

        results.add(result);
      }
    }

    // Sort by departure time
    results.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return results;
  }

  String getStationName(int stationId) {
    return stationNames[stationId] ?? 'Nazwa stacji niedostępna';
  }

  String getCarrierName(String? code) {
    if (code == null) return '';
    return carrierNames[code] ?? code;
  }

  String getCategoryName(String? code) {
    if (code == null) return '';
    return categoryNames[code] ?? code;
  }

  /// Search for train connections between two stations
  Future<List<ConnectionResult>> searchConnections({
    required Station fromStation,
    required Station toStation,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final dateStr = app_date.formatDateForApi(date);

    Map<String, dynamic> schedulesResponse;
    try {
      schedulesResponse = await api.getSchedules(
        dateFrom: dateStr,
        dateTo: dateStr,
        fromStations: fromStation.id.toString(),
        toStations: toStation.id.toString(),
        fullRoute: true,
      );
    } catch (_) {
      schedulesResponse = await api.getSchedules(
        dateFrom: dateStr,
        dateTo: dateStr,
        stations: '${fromStation.id},${toStation.id}',
        fullRoute: true,
      );
    }

    final rawRoutes = schedulesResponse['routes'] as List<dynamic>? ?? [];
    final routes = rawRoutes
        .map((r) => TrainRoute.fromJson(r as Map<String, dynamic>))
        .toList();

    // Fetch real-time operations
    Map<String, TrainOperation> operationsMap = {};
    if (!DateUtils.dateOnly(date).isAfter(DateUtils.dateOnly(DateTime.now()))) {
      try {
        final opsResponse = await api.getOperations(
          stations: '${fromStation.id},${toStation.id}',
          withPlanned: true,
        );
        final rawTrains = opsResponse['trains'] as List<dynamic>? ?? [];
        for (final t in rawTrains) {
          final op = TrainOperation.fromJson(t as Map<String, dynamic>);
          // The live feed can contain another occurrence of the same train.
          // Never attach today's actual timestamps to tomorrow's schedule.
          if (op.operatingDate != dateStr) continue;
          final key = '${op.scheduleId}_${op.orderId}';
          operationsMap[key] = op;
        }
      } catch (e) {
        debugPrint('[AppState] searchOperations error: $e');
      }
    }
    final List<ConnectionResult> directResults = [];
    final List<TrainRoute> potentialTransferRoutes = [];

    for (final route in routes) {
      if (route.operatingDates.isNotEmpty &&
          !route.operatingDates.contains(dateStr)) {
        continue;
      }

      int fromIndex = -1;
      int toIndex = -1;

      for (int i = 0; i < route.stations.length; i++) {
        final s = route.stations[i];
        if (s.stationId == fromStation.id && fromIndex == -1) {
          fromIndex = i;
        }
        if (s.stationId == toStation.id && toIndex == -1) {
          toIndex = i;
        }
      }

      if (fromIndex != -1 && toIndex != -1 && fromIndex < toIndex) {
        final fromStop = route.stations[fromIndex];
        final toStop = route.stations[toIndex];
        final opKey = '${route.scheduleId}_${route.orderId}';
        final operation = operationsMap[opKey];

        directResults.add(ConnectionResult(
          route: route,
          fromStop: fromStop,
          toStop: toStop,
          fromStationName: fromStation.name,
          toStationName: toStation.name,
          carrierName: getCarrierName(route.carrierCode),
          commercialCategory: route.commercialCategorySymbol ?? '',
          operation: operation,
          isDirect: true,
          transfersCount: 0,
          operatingDate: dateStr,
        ));
      } else {
        potentialTransferRoutes.add(route);
      }
    }

    if (directResults.isNotEmpty) {
      directResults.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      return directResults;
    }

    // Transfers
    final List<ConnectionResult> transferResults = [];
    for (final route1 in potentialTransferRoutes) {
      int fromIndex = -1;
      for (int i = 0; i < route1.stations.length; i++) {
        if (route1.stations[i].stationId == fromStation.id) {
          fromIndex = i;
          break;
        }
      }
      if (fromIndex == -1) continue;

      for (int k = fromIndex + 1; k < route1.stations.length; k++) {
        final transferStationId = route1.stations[k].stationId;
        final transferArrival = route1.stations[k].arrivalTime;
        if (transferArrival == null) continue;

        for (final route2 in potentialTransferRoutes) {
          if (route2 == route1) continue;

          int transferIndex2 = -1;
          int toIndex2 = -1;
          for (int m = 0; m < route2.stations.length; m++) {
            if (route2.stations[m].stationId == transferStationId &&
                transferIndex2 == -1) {
              transferIndex2 = m;
            }
            if (route2.stations[m].stationId == toStation.id &&
                toIndex2 == -1) {
              toIndex2 = m;
            }
          }

          if (transferIndex2 != -1 &&
              toIndex2 != -1 &&
              transferIndex2 < toIndex2) {
            final transferDeparture =
                route2.stations[transferIndex2].departureTime;
            if (transferDeparture == null) continue;

            if (transferDeparture.compareTo(transferArrival) > 0) {
              final leg2 = ConnectionResult(
                route: route2,
                fromStop: route2.stations[transferIndex2],
                toStop: route2.stations[toIndex2],
                fromStationName: getStationName(transferStationId),
                toStationName: toStation.name,
                carrierName: getCarrierName(route2.carrierCode),
                commercialCategory: route2.commercialCategorySymbol ?? '',
                isDirect: false,
                transfersCount: 1,
                operatingDate: dateStr,
              );

              transferResults.add(ConnectionResult(
                route: route1,
                fromStop: route1.stations[fromIndex],
                toStop: route1.stations[k],
                fromStationName: fromStation.name,
                toStationName: toStation.name,
                carrierName: getCarrierName(route1.carrierCode),
                commercialCategory: route1.commercialCategorySymbol ?? '',
                isDirect: false,
                transfersCount: 1,
                secondLeg: leg2,
                operatingDate: dateStr,
              ));
              break;
            }
          }
        }
      }
    }

    transferResults.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return transferResults;
  }

  /// Get disruptions data
  Future<Map<String, dynamic>> getDisruptions() async {
    if (_cachedDisruptions != null &&
        _disruptionsLoadedAt != null &&
        DateTime.now().difference(_disruptionsLoadedAt!).inSeconds < 30) {
      return _cachedDisruptions!;
    }
    final data = await api.getDisruptions();
    _cachedDisruptions = data;
    _disruptionsLoadedAt = DateTime.now();
    if (_servicesReady) await cache.saveDisruptions(data);
    return data;
  }

  final _affectedTrainLookups =
      BoundedCache<String, Future<Map<String, dynamic>>>(64);
  final _routeLookupTimes = BoundedCache<String, DateTime>(64);
  final _routeMetadata =
      BoundedCache<String, Map<String, Map<String, dynamic>>>(2);
  final _routeMetadataTimes = BoundedCache<String, DateTime>(2);
  final Map<String, Future<bool>> _disruptionIndexLoads = {};
  final Map<String, DateTime> _disruptionIndexTimes = {};

  /// Large alerts need one daily index, instead of a request for every train.
  Future<bool> prepareAffectedTrains(List<Map<String, dynamic>> refs) async {
    final unresolved = refs.where((ref) =>
        (ref['nationalNumber'] ?? ref['trainNumber'] ?? '').toString().isEmpty);
    if (unresolved.length <= 8) return true;
    final dates = unresolved
        .map((ref) => (ref['operatingDate'] ??
                ref['od'] ??
                app_date.formatDateForApi(DateTime.now()))
            .toString())
        .toSet();
    for (final date in dates) {
      final loaded = _disruptionIndexTimes[date];
      if (loaded != null && DateTime.now().difference(loaded).inMinutes >= 5) {
        _disruptionIndexLoads.remove(date);
      }
      _disruptionIndexLoads.putIfAbsent(date, () {
        _disruptionIndexTimes[date] = DateTime.now();
        return _loadDisruptionIndex(date);
      });
      if (!await _disruptionIndexLoads[date]!) return false;
    }
    return true;
  }

  Future<bool> _loadDisruptionIndex(String date) async {
    _expireRouteMetadata(date);
    if ((_routeMetadata[date]?.isNotEmpty ?? false)) return true;
    try {
      final saved = _servicesReady ? cache.loadTrainIndex(date) : null;
      final routes = saved != null && saved.isNotEmpty
          ? saved
          : (await api.getSchedules(
                  dateFrom: date,
                  dateTo: date,
                  fullRoute: true))['routes'] as List<dynamic>? ??
              [];
      _rememberRouteMetadata(date, routes);
      if (_servicesReady && routes.isNotEmpty) {
        await cache.saveTrainIndex(date, routes);
      }
      return true;
    } catch (error) {
      debugPrint('[Disruptions] Train index unavailable: $error');
      return false;
    }
  }

  void _rememberRouteMetadata(String date, List<dynamic> routes) {
    _routeMetadata[date] = {
      for (final route in routes.whereType<Map<String, dynamic>>())
        '${route['scheduleId']}/${route['orderId']}': route,
    };
    _routeMetadataTimes[date] = DateTime.now();
  }

  void _expireRouteMetadata(String date) {
    final saved = _routeMetadataTimes[date];
    if (saved == null ||
        DateTime.now().difference(saved) > CacheService.scheduleCacheDuration) {
      _routeMetadata.remove(date);
      _routeMetadataTimes.remove(date);
    }
  }

  Future<Map<String, dynamic>> getScheduleRoute(int sid, int oid,
      {String? operatingDate}) async {
    final date = operatingDate ?? app_date.formatDateForApi(DateTime.now());
    _expireRouteMetadata(date);
    if (!_routeMetadata.containsKey(date) && _servicesReady) {
      _rememberRouteMetadata(date, cache.loadTrainIndex(date) ?? []);
    }
    final known = _routeMetadata[date]?['$sid/$oid'];
    if (known != null) return known;
    final key = '$sid/$oid/$date';
    final loaded = _routeLookupTimes[key];
    if (loaded != null && DateTime.now().difference(loaded).inMinutes >= 5) {
      _affectedTrainLookups.remove(key);
    }
    if (!_affectedTrainLookups.containsKey(key)) {
      _routeLookupTimes[key] = DateTime.now();
      _affectedTrainLookups[key] = api.getScheduleRoute(sid, oid);
    }
    // Keeping failures briefly prevents a rebuild from retrying an unavailable
    // route for every chip. A subsequent load can retry after the cache expires.
    return _affectedTrainLookups[key]!;
  }

  Future<Map<String, dynamic>> resolveAffectedTrain(
      Map<String, dynamic> ref) async {
    final sid = int.tryParse('${ref['scheduleId'] ?? ref['sid']}');
    final oid = int.tryParse('${ref['orderId'] ?? ref['oid']}');
    final number = ref['nationalNumber'] ?? ref['trainNumber'];
    if (number != null && number.toString().isNotEmpty) return ref;
    if (sid == null || oid == null) return ref;
    final date = ref['operatingDate'] ?? ref['od'];
    for (final item in [...stationDepartures, ...stationArrivals]) {
      if (item.scheduleId == sid &&
          item.orderId == oid &&
          (date == null || item.operatingDate == date) &&
          item.trainNumber.isNotEmpty) {
        return {
          ...ref,
          'nationalNumber': item.trainNumber,
          'commercialCategorySymbol': item.trainCategory,
          'name': item.trainName
        };
      }
    }
    try {
      final route =
          await getScheduleRoute(sid, oid, operatingDate: date?.toString());
      return {
        ...ref,
        'nationalNumber': route['nationalNumber'],
        'commercialCategorySymbol': route['commercialCategorySymbol'],
        'name': route['name']
      };
    } catch (_) {
      return ref;
    }
  }

  /// Get operations statistics
  Future<OperationStatistics> getOperationStatistics({String? date}) async {
    final data = await api.getOperationStatistics(date: date);
    return OperationStatistics.fromJson(data);
  }

  /// Get specific train operation
  Future<TrainOperation?> getTrainOperation(
      int scheduleId, int orderId, String operatingDate) async {
    try {
      final data =
          await api.getTrainOperation(scheduleId, orderId, operatingDate);
      return TrainOperation.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }
}
