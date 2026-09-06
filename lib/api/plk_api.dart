import 'api_client.dart';

class PlkApi {
  final ApiClient _client;

  PlkApi(this._client);

  // === DICTIONARIES ===

  /// Get all stations (pageSize=10000 to get all at once)
  Future<Map<String, dynamic>> getStations(
      {String? search, int pageSize = 10000}) async {
    final response =
        await _client.get('/api/v1/dictionaries/stations', queryParameters: {
      if (search != null) 'search': search,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get all carriers
  Future<Map<String, dynamic>> getCarriers() async {
    final response = await _client.get('/api/v1/dictionaries/carriers');
    return response.data as Map<String, dynamic>;
  }

  /// Get commercial categories
  Future<Map<String, dynamic>> getCommercialCategories() async {
    final response =
        await _client.get('/api/v1/dictionaries/commercial-categories');
    return response.data as Map<String, dynamic>;
  }

  /// Get stop types
  Future<Map<String, dynamic>> getStopTypes() async {
    final response = await _client.get('/api/v1/dictionaries/stop-types');
    return response.data as Map<String, dynamic>;
  }

  /// Get cities
  Future<Map<String, dynamic>> getCities({String? search}) async {
    final response =
        await _client.get('/api/v1/dictionaries/cities', queryParameters: {
      if (search != null) 'search': search,
    });
    return response.data as Map<String, dynamic>;
  }

  // === SCHEDULES ===

  /// Get schedules with from/to city names (best for connection search)
  Future<Map<String, dynamic>> getSchedules({
    String? dateFrom,
    String? dateTo,
    String? stations,
    String? from,
    String? to,
    String? fromStations,
    String? toStations,
    String? carriersInclude,
    String? carriersExclude,
    bool? fullRoute,
    bool dictionaries = true,
  }) async {
    final response = await _client.get('/api/v1/schedules', queryParameters: {
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      if (stations != null) 'stations': stations,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (fromStations != null) 'fromStations': fromStations,
      if (toStations != null) 'toStations': toStations,
      if (carriersInclude != null) 'carriersInclude': carriersInclude,
      if (carriersExclude != null) 'carriersExclude': carriersExclude,
      if (fullRoute != null) 'fullRoute': fullRoute,
      'dictionaries': dictionaries,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get route details for a specific train
  Future<Map<String, dynamic>> getScheduleRoute(
      int scheduleId, int orderId) async {
    final response =
        await _client.get('/api/v1/schedules/route/$scheduleId/$orderId');
    return response.data as Map<String, dynamic>;
  }

  /// Get list of route IDs for a specific date
  Future<Map<String, dynamic>> getRouteIds(String date) async {
    final response = await _client.get('/api/v1/schedules/routes/$date');
    return response.data as Map<String, dynamic>;
  }

  // === OPERATIONS (Real-time) ===

  /// Get real-time operations data
  Future<Map<String, dynamic>> getOperations({
    String? stations,
    String? carriersInclude,
    String? carriersExclude,
    bool fullRoutes = false,
    bool withPlanned = true,
    int? page,
    int? pageSize,
  }) async {
    final response = await _client.get('/api/v1/operations', queryParameters: {
      if (stations != null) 'stations': stations,
      if (carriersInclude != null) 'carriersInclude': carriersInclude,
      if (carriersExclude != null) 'carriersExclude': carriersExclude,
      'fullRoutes': fullRoutes,
      'withPlanned': withPlanned,
      if (page != null) 'page': page,
      if (pageSize != null) 'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get specific train operation data
  Future<Map<String, dynamic>> getTrainOperation(
    int scheduleId,
    int orderId,
    String operatingDate,
  ) async {
    final response = await _client.get(
      '/api/v1/operations/train/$scheduleId/$orderId/$operatingDate',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get operation statistics
  Future<Map<String, dynamic>> getOperationStatistics({String? date}) async {
    final response =
        await _client.get('/api/v1/operations/statistics', queryParameters: {
      if (date != null) 'date': date,
    });
    return response.data as Map<String, dynamic>;
  }

  // === DISRUPTIONS ===

  /// Get disruptions
  Future<Map<String, dynamic>> getDisruptions({
    String? dateFrom,
    String? dateTo,
    String? stations,
    String? carriersInclude,
    String? carriersExclude,
    bool dictionaries = true,
  }) async {
    final response = await _client.get('/api/v1/disruptions', queryParameters: {
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      if (stations != null) 'stations': stations,
      if (carriersInclude != null) 'carriersInclude': carriersInclude,
      if (carriersExclude != null) 'carriersExclude': carriersExclude,
      'dictionaries': dictionaries,
    });
    return response.data as Map<String, dynamic>;
  }

  // === DATA VERSION ===

  /// Get current data version
  Future<Map<String, dynamic>> getDataVersion() async {
    final response = await _client.get('/api/v1/data-version');
    return response.data as Map<String, dynamic>;
  }

  // === FIELD DICTIONARIES ===

  /// Get field dictionary for schedules endpoint
  Future<Map<String, dynamic>> getFieldsSchedules() async {
    final response = await _client.get('/api/v1/fields/schedules');
    return response.data as Map<String, dynamic>;
  }

  /// Get field dictionary for operations endpoint
  Future<Map<String, dynamic>> getFieldsOperations() async {
    final response = await _client.get('/api/v1/fields/operations');
    return response.data as Map<String, dynamic>;
  }

  /// Get field dictionary for disruptions endpoint
  Future<Map<String, dynamic>> getFieldsDisruptions() async {
    final response = await _client.get('/api/v1/fields/disruptions');
    return response.data as Map<String, dynamic>;
  }
}
