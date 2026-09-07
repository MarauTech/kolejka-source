import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _stationsKey = 'cache_stations';
  static const _carriersKey = 'cache_carriers';
  static const _categoriesKey = 'cache_categories';
  static const _stopTypesKey = 'cache_stop_types';
  static const _dataVersionKey = 'cache_data_version';

  static const _stationsTsKey = 'cache_stations_ts';
  static const _carriersTsKey = 'cache_carriers_ts';
  static const _categoriesTsKey = 'cache_categories_ts';
  static const _stopTypesTsKey = 'cache_stop_types_ts';

  static const _lastSelectedStationKey = 'cache_last_selected_station';
  static const _nearestStationKey = 'cache_nearest_station';
  static const _nearestStationTsKey = 'cache_nearest_station_ts';
  static const _favoriteStationsKey = 'cache_favorite_stations';
  static const _favoriteRoutesKey = 'cache_favorite_routes';
  static const _recentStationsKey = 'cache_recent_stations';
  static const _themeModeKey = 'cache_theme_mode';
  static const _trainIndexPrefix = 'cache_train_index_';

  // Cache durations
  static const dictionaryCacheDuration = Duration(hours: 24);
  static const scheduleCacheDuration = Duration(minutes: 5);
  static const realtimeCacheDuration = Duration(seconds: 30);
  static const disruptionsCacheDuration = Duration(minutes: 5);
  static const nearestStationCacheDuration = Duration(minutes: 30);

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // === Generic cache methods ===

  Future<void> _saveJson(String key, String tsKey, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
    await _prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  dynamic _loadJson(String key, String tsKey, Duration maxAge) {
    final ts = _prefs.getInt(tsKey);
    if (ts == null) return null;

    final age =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age > maxAge) return null;

    final raw = _prefs.getString(key);
    if (raw == null) return null;

    return jsonDecode(raw);
  }

  // === Stations ===

  Future<void> saveStations(List<dynamic> stations) async {
    await _saveJson(_stationsKey, _stationsTsKey, stations);
  }

  List<dynamic>? loadStations() {
    final data =
        _loadJson(_stationsKey, _stationsTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Carriers ===

  Future<void> saveCarriers(List<dynamic> carriers) async {
    await _saveJson(_carriersKey, _carriersTsKey, carriers);
  }

  List<dynamic>? loadCarriers() {
    final data =
        _loadJson(_carriersKey, _carriersTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Commercial Categories ===

  Future<void> saveCategories(List<dynamic> categories) async {
    await _saveJson(_categoriesKey, _categoriesTsKey, categories);
  }

  List<dynamic>? loadCategories() {
    final data =
        _loadJson(_categoriesKey, _categoriesTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Stop Types ===

  Future<void> saveStopTypes(List<dynamic> stopTypes) async {
    await _saveJson(_stopTypesKey, _stopTypesTsKey, stopTypes);
  }

  List<dynamic>? loadStopTypes() {
    final data =
        _loadJson(_stopTypesKey, _stopTypesTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Data Version ===

  Future<void> saveDataVersion(String version) async {
    await _prefs.setString(_dataVersionKey, version);
  }

  String? loadDataVersion() {
    return _prefs.getString(_dataVersionKey);
  }

  // === Last Selected Station ===

  Future<void> saveLastSelectedStation(int id, String name) async {
    await _prefs.setString(
        _lastSelectedStationKey, jsonEncode({'id': id, 'name': name}));
  }

  Map<String, dynamic>? loadLastSelectedStation() {
    final raw = _prefs.getString(_lastSelectedStationKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // === Nearest Station Cache ===

  Future<void> saveNearestStation(
      int id, String name, double lat, double lon) async {
    await _saveJson(_nearestStationKey, _nearestStationTsKey, {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
    });
  }

  Map<String, dynamic>? loadNearestStation() {
    final data = _loadJson(
        _nearestStationKey, _nearestStationTsKey, nearestStationCacheDuration);
    return data as Map<String, dynamic>?;
  }

  // === Favorite Stations ===

  Future<void> saveFavoriteStations(List<Map<String, dynamic>> stations) async {
    await _prefs.setString(_favoriteStationsKey, jsonEncode(stations));
  }

  List<Map<String, dynamic>> loadFavoriteStations() {
    final raw = _prefs.getString(_favoriteStationsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      return list?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  // === Favorite Routes ===

  Future<void> saveFavoriteRoutes(List<Map<String, dynamic>> routes) async {
    await _prefs.setString(_favoriteRoutesKey, jsonEncode(routes));
  }

  List<Map<String, dynamic>> loadFavoriteRoutes() {
    final raw = _prefs.getString(_favoriteRoutesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      return list?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentStations(List<Map<String, dynamic>> stations) async {
    if (!_isInitialized) return;
    await _prefs.setString(_recentStationsKey, jsonEncode(stations));
  }

  List<Map<String, dynamic>> loadRecentStations() {
    if (!_isInitialized) return [];
    final raw = _prefs.getString(_recentStationsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // === Theme Mode ===

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  String? loadThemeMode() {
    return _prefs.getString(_themeModeKey);
  }

  // === Train Schedule Index Cache ===

  Future<void> saveTrainIndex(String date, List<dynamic> routes) async {
    final key = '$_trainIndexPrefix$date';
    await _prefs.setString(key, jsonEncode(routes));
  }

  List<dynamic>? loadTrainIndex(String date) {
    final key = '$_trainIndexPrefix$date';
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Clear dictionary caches (when data version changes)
  Future<void> clearDictionaryCache() async {
    await _prefs.remove(_stationsKey);
    await _prefs.remove(_stationsTsKey);
    await _prefs.remove(_carriersKey);
    await _prefs.remove(_carriersTsKey);
    await _prefs.remove(_categoriesKey);
    await _prefs.remove(_categoriesTsKey);
    await _prefs.remove(_stopTypesKey);
    await _prefs.remove(_stopTypesTsKey);
  }

  /// Clear all caches
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
