import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'api/plk_api.dart';
import 'models/models.dart';
import 'services/cache_service.dart';
import 'utils/date_utils.dart' as app_date;

class AppState extends ChangeNotifier {
  late final ApiClient _apiClient;
  late final PlkApi api;
  late final CacheService cache;

  List<Station> stations = [];
  Map<String, String> carrierNames = {}; // code -> name
  Map<String, String> categoryNames = {}; // code -> name
  Map<int, String> stopTypeNames = {}; // id -> description
  Map<int, String> stationNames = {}; // id -> name

  bool isLoading = false;
  String? error;
  bool _initialized = false;

  Future<void> init() async {
    _apiClient = ApiClient();
    api = PlkApi(_apiClient);
    cache = CacheService();
    await cache.init();
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
          carrierNames[map['code'] as String? ?? ''] = map['name'] as String? ?? '';
        }
      } else {
        final data = await api.getCarriers();
        final carriersList = data['carriers'] as List<dynamic>? ?? [];
        carrierNames = {};
        for (final c in carriersList) {
          final map = c as Map<String, dynamic>;
          carrierNames[map['code'] as String? ?? ''] = map['name'] as String? ?? '';
        }
        await cache.saveCarriers(carriersList);
      }

      // Load commercial categories
      final cachedCategories = cache.loadCategories();
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        categoryNames = {};
        for (final c in cachedCategories) {
          final map = c as Map<String, dynamic>;
          categoryNames[map['code'] as String? ?? ''] = map['name'] as String? ?? '';
        }
      } else {
        final data = await api.getCommercialCategories();
        final categoriesList = data['commercialCategories'] as List<dynamic>? ?? [];
        categoryNames = {};
        for (final c in categoriesList) {
          final map = c as Map<String, dynamic>;
          categoryNames[map['code'] as String? ?? ''] = map['name'] as String? ?? '';
        }
        await cache.saveCategories(categoriesList);
      }

      // Load stop types
      final cachedStopTypes = cache.loadStopTypes();
      if (cachedStopTypes != null && cachedStopTypes.isNotEmpty) {
        stopTypeNames = {};
        for (final s in cachedStopTypes) {
          final map = s as Map<String, dynamic>;
          stopTypeNames[map['id'] as int? ?? 0] = map['description'] as String? ?? '';
        }
      } else {
        final data = await api.getStopTypes();
        final stopTypesList = data['stopTypes'] as List<dynamic>? ?? [];
        stopTypeNames = {};
        for (final s in stopTypesList) {
          final map = s as Map<String, dynamic>;
          stopTypeNames[map['id'] as int? ?? 0] = map['description'] as String? ?? '';
        }
        await cache.saveStopTypes(stopTypesList);
      }

      _initialized = true;
    } catch (e) {
      error = e.toString();
      debugPrint('[AppState] loadDictionaries error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String getStationName(int stationId) {
    return stationNames[stationId] ?? 'Stacja $stationId';
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
    
    // Fetch schedules from API
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
      // Fallback to stations query
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

    // Fetch real-time operations for delay and status
    Map<String, TrainOperation> operationsMap = {};
    try {
      final opsResponse = await api.getOperations(
        stations: '${fromStation.id},${toStation.id}',
        withPlanned: true,
      );
      final rawTrains = opsResponse['trains'] as List<dynamic>? ?? [];
      for (final t in rawTrains) {
        final op = TrainOperation.fromJson(t as Map<String, dynamic>);
        final key = '${op.scheduleId}_${op.orderId}';
        operationsMap[key] = op;
      }
    } catch (e) {
      debugPrint('[AppState] searchOperations error: $e');
    }

    final List<ConnectionResult> directResults = [];
    final List<TrainRoute> potentialTransferRoutes = [];

    for (final route in routes) {
      // Check operating dates if available
      if (route.operatingDates.isNotEmpty && !route.operatingDates.contains(dateStr)) {
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

      // Direct connection check: fromStation must appear BEFORE toStation
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
          commercialCategory: getCategoryName(route.commercialCategorySymbol),
          operation: operation,
          isDirect: true,
          transfersCount: 0,
          operatingDate: dateStr,
        ));
      } else {
        potentialTransferRoutes.add(route);
      }
    }

    // If direct connections found, sort by departure time and return
    if (directResults.isNotEmpty) {
      directResults.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      return directResults;
    }

    // If no direct connections found, search for 1-transfer connections
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
            if (route2.stations[m].stationId == transferStationId && transferIndex2 == -1) {
              transferIndex2 = m;
            }
            if (route2.stations[m].stationId == toStation.id && toIndex2 == -1) {
              toIndex2 = m;
            }
          }

          if (transferIndex2 != -1 && toIndex2 != -1 && transferIndex2 < toIndex2) {
            final transferDeparture = route2.stations[transferIndex2].departureTime;
            if (transferDeparture == null) continue;

            // Transfer time check: at least 5 minutes, max 180 minutes
            if (transferDeparture.compareTo(transferArrival) > 0) {
              final leg2 = ConnectionResult(
                route: route2,
                fromStop: route2.stations[transferIndex2],
                toStop: route2.stations[toIndex2],
                fromStationName: getStationName(transferStationId),
                toStationName: toStation.name,
                carrierName: getCarrierName(route2.carrierCode),
                commercialCategory: getCategoryName(route2.commercialCategorySymbol),
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
                commercialCategory: getCategoryName(route1.commercialCategorySymbol),
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

  /// Get departures and arrivals board for a station
  Future<Map<String, List<StationBoardItem>>> getStationBoard(int stationId) async {
    final response = await api.getOperations(
      stations: stationId.toString(),
      withPlanned: true,
      fullRoutes: true,
    );

    final rawTrains = response['trains'] as List<dynamic>? ?? [];
    final List<StationBoardItem> departures = [];
    final List<StationBoardItem> arrivals = [];

    for (final t in rawTrains) {
      final op = TrainOperation.fromJson(t as Map<String, dynamic>);
      for (int i = 0; i < op.stations.length; i++) {
        final st = op.stations[i];
        if (st.stationId == stationId) {
          // Check departure
          final depTime = st.actualDeparture ?? st.plannedDeparture;
          final arrTime = st.actualArrival ?? st.plannedArrival;

          // Destination station (last stop)
          String destination = 'Nieznana stacja';
          String origin = 'Nieznana stacja';
          if (op.stations.isNotEmpty) {
            destination = getStationName(op.stations.last.stationId);
            origin = getStationName(op.stations.first.stationId);
          }

          if (depTime != null && i < op.stations.length - 1) {
            departures.add(StationBoardItem(
              time: app_date.formatDateTime(depTime),
              trainNumber: op.trainOrderId.toString(),
              trainCategory: '',
              carrier: '',
              direction: destination,
              delayMinutes: st.departureDelayMinutes,
              isCancelled: st.isCancelled || op.trainStatus == 'X',
              status: op.statusText,
              scheduleId: op.scheduleId,
              orderId: op.orderId,
              operatingDate: op.operatingDate,
              raw: op.raw,
            ));
          }

          if (arrTime != null && i > 0) {
            arrivals.add(StationBoardItem(
              time: app_date.formatDateTime(arrTime),
              trainNumber: op.trainOrderId.toString(),
              trainCategory: '',
              carrier: '',
              direction: origin,
              delayMinutes: st.arrivalDelayMinutes,
              isCancelled: st.isCancelled || op.trainStatus == 'X',
              status: op.statusText,
              scheduleId: op.scheduleId,
              orderId: op.orderId,
              operatingDate: op.operatingDate,
              raw: op.raw,
            ));
          }
        }
      }
    }

    departures.sort((a, b) => a.time.compareTo(b.time));
    arrivals.sort((a, b) => a.time.compareTo(b.time));

    return {
      'departures': departures,
      'arrivals': arrivals,
    };
  }

  /// Get disruptions data
  Future<Map<String, dynamic>> getDisruptions() async {
    return await api.getDisruptions();
  }

  /// Get operations statistics
  Future<OperationStatistics> getOperationStatistics({String? date}) async {
    final data = await api.getOperationStatistics(date: date);
    return OperationStatistics.fromJson(data);
  }

  /// Get specific train operation
  Future<TrainOperation?> getTrainOperation(int scheduleId, int orderId, String operatingDate) async {
    try {
      final data = await api.getTrainOperation(scheduleId, orderId, operatingDate);
      return TrainOperation.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
