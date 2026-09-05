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

  // Cache durations
  static const dictionaryCacheDuration = Duration(hours: 24);
  static const scheduleCacheDuration = Duration(minutes: 5);
  static const realtimeCacheDuration = Duration(seconds: 30);
  static const disruptionsCacheDuration = Duration(minutes: 5);

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // === Generic cache methods ===

  Future<void> _saveJson(String key, String tsKey, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
    await _prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  dynamic _loadJson(String key, String tsKey, Duration maxAge) {
    final ts = _prefs.getInt(tsKey);
    if (ts == null) return null;

    final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
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
    final data = _loadJson(_stationsKey, _stationsTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Carriers ===

  Future<void> saveCarriers(List<dynamic> carriers) async {
    await _saveJson(_carriersKey, _carriersTsKey, carriers);
  }

  List<dynamic>? loadCarriers() {
    final data = _loadJson(_carriersKey, _carriersTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Commercial Categories ===

  Future<void> saveCategories(List<dynamic> categories) async {
    await _saveJson(_categoriesKey, _categoriesTsKey, categories);
  }

  List<dynamic>? loadCategories() {
    final data = _loadJson(_categoriesKey, _categoriesTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Stop Types ===

  Future<void> saveStopTypes(List<dynamic> stopTypes) async {
    await _saveJson(_stopTypesKey, _stopTypesTsKey, stopTypes);
  }

  List<dynamic>? loadStopTypes() {
    final data = _loadJson(_stopTypesKey, _stopTypesTsKey, dictionaryCacheDuration);
    return data as List<dynamic>?;
  }

  // === Data Version ===

  Future<void> saveDataVersion(String version) async {
    await _prefs.setString(_dataVersionKey, version);
  }

  String? loadDataVersion() {
    return _prefs.getString(_dataVersionKey);
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
