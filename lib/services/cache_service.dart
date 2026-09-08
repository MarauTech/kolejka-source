import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import '../models/models.dart';

class CacheService {
  static const cacheSchemaVersion = 2;
  static const schemaKey = 'api_cache_schema_version';
  static const maxEntryBytes = 512 * 1024;
  static const maxPersistentBytes = 1024 * 1024;
  static const _technical = [
    'cache_stations',
    'cache_carriers',
    'cache_categories',
    'cache_stop_types',
    'cache_nearest_station',
    'cache_disruptions',
    'cache_data_version',
  ];
  final _memory = <String, ({Object data, DateTime savedAt})>{};
  final _trainIndices = <String, ({List<dynamic> routes, DateTime savedAt})>{};

  static bool _isTechnicalKey(String key) =>
      _technical.contains(key) ||
      _technical.any((name) => key == '${name}_ts') ||
      key.startsWith(_trainIndexPrefix);
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

  /// Run before legacy getInstance(): it otherwise copies every old multi-MB
  /// train index over the platform channel before Dart can remove it.
  static SharedPreferencesAsync androidLegacyStore() => SharedPreferencesAsync(
        options: const SharedPreferencesAsyncAndroidOptions(
          backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
          originalSharedPreferencesOptions:
              AndroidSharedPreferencesStoreOptions(
                  fileName: 'FlutterSharedPreferences'),
        ),
      );

  static Future<void> migrateLegacyAndroid(SharedPreferencesAsync store) async {
    const schema = 'flutter.$schemaKey';
    final version = await store.getAll(allowList: {schema});
    if (version[schema] == cacheSchemaVersion) return;
    // Fetch names only. The large values never enter Dart or a message codec.
    final keys = await store.getKeys();
    final technical = keys
        .where((key) =>
            key.startsWith('flutter.') &&
            _isTechnicalKey(key.substring('flutter.'.length)))
        .toSet();
    if (technical.isNotEmpty) await store.clear(allowList: technical);
    await store.setInt(schema, cacheSchemaVersion);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.get(schemaKey) != cacheSchemaVersion) {
      for (final key in _prefs.getKeys().where(_isTechnicalKey).toList()) {
        await _prefs.remove(key);
      }
      await _prefs.setInt(schemaKey, cacheSchemaVersion);
    }
    _isInitialized = true;
  }

  Future<void> _remove(String key, {bool timestamp = true}) async {
    try {
      // Start both removals before yielding, so a fresh fetch cannot have its
      // newly written timestamp removed by an older invalidation.
      await Future.wait([
        _prefs.remove(key),
        if (timestamp) _prefs.remove('${key}_ts'),
      ]);
    } catch (_) {
      if (kDebugMode) debugPrint('[Cache] Could not remove entry: $key');
    }
  }

  T? _read<T>(String key, T Function(dynamic) parse, {Duration? maxAge}) {
    if (!_isInitialized) return null;
    try {
      final memory = _memory[key];
      if (memory != null) {
        if (maxAge == null ||
            DateTime.now().difference(memory.savedAt) <= maxAge) {
          return parse(memory.data);
        }
        _memory.remove(key);
      }
      final raw = _prefs.get(key);
      if (raw == null) return null;
      if (maxAge != null) {
        final ts = _prefs.get('${key}_ts');
        if (ts is! int) throw const FormatException('Invalid cache timestamp');
        final age =
            DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
        if (age.isNegative || age > maxAge) {
          unawaited(_remove(key));
          return null;
        }
      }
      if (raw is! String) throw const FormatException('Invalid cache value');
      return parse(jsonDecode(raw));
    } on FormatException {
      _memory.remove(key);
      unawaited(_remove(key));
    } on TypeError {
      _memory.remove(key);
      unawaited(_remove(key));
    } on ArgumentError {
      _memory.remove(key);
      unawaited(_remove(key));
    }
    return null;
  }

  List<dynamic> _list(
      dynamic value, void Function(Map<String, dynamic>) validate) {
    if (value is! List) throw const FormatException('Expected list');
    for (final item in value) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Expected record');
      }
      validate(item);
    }
    return value;
  }

  String? _string(String key) {
    if (!_isInitialized) return null;
    final value = _prefs.get(key);
    if (value is String) return value;
    if (value != null) unawaited(_remove(key, timestamp: false));
    return null;
  }

  Map<String, dynamic> _station(dynamic value) {
    final map = value as Map<String, dynamic>;
    if (map['id'] is! int || map['name'] is! String) {
      throw const FormatException('Invalid station');
    }
    return map;
  }

  // === Generic cache methods ===
  Future<void> saveDisruptions(Map<String, dynamic> data) async {
    if (_isInitialized) {
      await _saveJson('cache_disruptions', 'cache_disruptions_ts', data);
    }
  }

  Map<String, dynamic>? loadDisruptions() {
    if (!_isInitialized) return null;
    // Stale data is retained for offline reading, always with its source date.
    return _read('cache_disruptions', (value) {
      final map = value as Map<String, dynamic>;
      _list(map['disruptions'] ?? [], (row) {
        Disruption.fromJson(row);
      });
      for (final field in ['stations', 'disruptionTypes']) {
        if (map[field] != null && map[field] is! Map<String, dynamic>) {
          throw const FormatException('Invalid disruption dictionary');
        }
      }
      if (map['generatedAt'] != null && map['generatedAt'] is! String) {
        throw const FormatException('Invalid snapshot date');
      }
      return map;
    });
  }

  Future<void> _saveJson(String key, String tsKey, dynamic data) async {
    final encoded = jsonEncode(data);
    final size = utf8.encode(encoded).length;
    if (size > maxEntryBytes) {
      _memory[key] = (data: data as Object, savedAt: DateTime.now());
      await _remove(key);
      return;
    }
    _memory.remove(key);
    var total = size;
    final entries = <String>[];
    for (final candidate in _technical) {
      if (candidate == key) continue;
      final value = _prefs.get(candidate);
      if (value is String) {
        total += utf8.encode(value).length;
        entries.add(candidate);
      }
    }
    entries.sort((a, b) {
      final ta = _prefs.get('${a}_ts');
      final tb = _prefs.get('${b}_ts');
      return (ta is int ? ta : 0).compareTo(tb is int ? tb : 0);
    });
    for (final candidate in entries) {
      if (total <= maxPersistentBytes) break;
      total -= utf8.encode(_prefs.get(candidate) as String).length;
      await _remove(candidate);
    }
    await _prefs.setString(key, encoded);
    await _prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  // === Stations ===

  Future<void> saveStations(List<dynamic> stations) async {
    await _saveJson(_stationsKey, _stationsTsKey, stations);
  }

  List<dynamic>? loadStations() {
    return _read(
        _stationsKey,
        (value) => _list(value, (row) {
              final station = Station.fromJson(_station(row));
              if (station.id <= 0 || station.name.trim().isEmpty) {
                throw const FormatException('Invalid station model');
              }
            }),
        maxAge: dictionaryCacheDuration);
  }

  // === Carriers ===

  Future<void> saveCarriers(List<dynamic> carriers) async {
    await _saveJson(_carriersKey, _carriersTsKey, carriers);
  }

  List<dynamic>? loadCarriers() {
    return _read(
        _carriersKey,
        (value) => _list(value, (row) {
              Carrier.fromJson(row);
            }),
        maxAge: dictionaryCacheDuration);
  }

  // === Commercial Categories ===

  Future<void> saveCategories(List<dynamic> categories) async {
    await _saveJson(_categoriesKey, _categoriesTsKey, categories);
  }

  List<dynamic>? loadCategories() {
    return _read(
        _categoriesKey,
        (value) => _list(value, (row) {
              CommercialCategory.fromJson(row);
            }),
        maxAge: dictionaryCacheDuration);
  }

  // === Stop Types ===

  Future<void> saveStopTypes(List<dynamic> stopTypes) async {
    await _saveJson(_stopTypesKey, _stopTypesTsKey, stopTypes);
  }

  List<dynamic>? loadStopTypes() {
    return _read(
        _stopTypesKey,
        (value) => _list(value, (row) {
              StopType.fromJson(row);
            }),
        maxAge: dictionaryCacheDuration);
  }

  // === Data Version ===

  Future<void> saveDataVersion(String version) async {
    await _prefs.setString(_dataVersionKey, version);
  }

  String? loadDataVersion() {
    return _string(_dataVersionKey);
  }

  // === Last Selected Station ===

  Future<void> saveLastSelectedStation(int id, String name) async {
    await _prefs.setString(
        _lastSelectedStationKey, jsonEncode({'id': id, 'name': name}));
  }

  Map<String, dynamic>? loadLastSelectedStation() {
    return _read(_lastSelectedStationKey, _station);
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
    return _read(_nearestStationKey, _station,
        maxAge: nearestStationCacheDuration);
  }

  // === Favorite Stations ===

  Future<void> saveFavoriteStations(List<Map<String, dynamic>> stations) async {
    await _prefs.setString(_favoriteStationsKey, jsonEncode(stations));
  }

  List<Map<String, dynamic>> loadFavoriteStations() {
    return _preferences(_favoriteStationsKey);
  }

  // === Favorite Routes ===

  Future<void> saveFavoriteRoutes(List<Map<String, dynamic>> routes) async {
    await _prefs.setString(_favoriteRoutesKey, jsonEncode(routes));
  }

  List<Map<String, dynamic>> loadFavoriteRoutes() {
    return _preferences(_favoriteRoutesKey, routes: true);
  }

  Future<void> saveRecentStations(List<Map<String, dynamic>> stations) async {
    if (!_isInitialized) return;
    await _prefs.setString(_recentStationsKey, jsonEncode(stations));
  }

  List<Map<String, dynamic>> loadRecentStations() {
    return _preferences(_recentStationsKey);
  }

  List<Map<String, dynamic>> _preferences(String key, {bool routes = false}) {
    return _read(key, (value) {
          if (value is! List) {
            throw const FormatException('Invalid preferences');
          }
          final valid = <Map<String, dynamic>>[];
          for (final item in value) {
            if (item is! Map<String, dynamic>) continue;
            final row = Map<String, dynamic>.from(item);
            // A broken optional timestamp must not destroy a valid favorite.
            if (row['savedAt'] is! String) row.remove('savedAt');
            final idKeys = routes ? ['fromStationId', 'toStationId'] : ['id'];
            final nameKeys =
                routes ? ['fromStationName', 'toStationName'] : ['name'];
            for (final field in idKeys) {
              if (row[field] is String) {
                row[field] = int.tryParse(row[field] as String);
              }
            }
            if (idKeys.any((field) =>
                    row[field] is! int || (row[field] as int) <= 0) ||
                nameKeys.any((field) =>
                    row[field] is! String ||
                    (row[field] as String).trim().isEmpty)) {
              continue;
            }
            valid.add(row);
          }
          if (jsonEncode(valid) != jsonEncode(value)) {
            unawaited(_repairPreferences(key, valid));
          }
          return valid;
        }) ??
        [];
  }

  Future<void> _repairPreferences(
      String key, List<Map<String, dynamic>> data) async {
    try {
      await _prefs.setString(key, jsonEncode(data));
    } catch (_) {
      if (kDebugMode) debugPrint('[Cache] Could not repair entry: $key');
    }
  }

  // === Theme Mode ===

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  String? loadThemeMode() {
    return _string(_themeModeKey);
  }

  Future<void> saveInterfaceStyle(String style) =>
      _prefs.setString('interface_style', style);

  String? loadInterfaceStyle() => _string('interface_style');

  // === Train Schedule Index Cache ===

  Future<void> saveTrainIndex(String date, List<dynamic> routes) async {
    // Full nationwide schedules stay in memory, bounded to two recent days.
    _trainIndices.remove(date);
    _trainIndices[date] = (routes: routes, savedAt: DateTime.now());
    while (_trainIndices.length > 2) {
      _trainIndices.remove(_trainIndices.keys.first);
    }
  }

  List<dynamic>? loadTrainIndex(String date) {
    final entry = _trainIndices[date];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.savedAt) > scheduleCacheDuration) {
      _trainIndices.remove(date);
      return null;
    }
    try {
      return _list(entry.routes, (row) {
        TrainRoute.fromJson(row);
      });
    } on TypeError {
      _trainIndices.remove(date);
    } on FormatException {
      _trainIndices.remove(date);
    }
    return null;
  }

  /// Clear dictionary caches (when data version changes)
  Future<void> clearDictionaryCache() async {
    for (final key in [
      _stationsKey,
      _carriersKey,
      _categoriesKey,
      _stopTypesKey
    ]) {
      _memory.remove(key);
    }
    await _prefs.remove(_stationsKey);
    await _prefs.remove(_stationsTsKey);
    await _prefs.remove(_carriersKey);
    await _prefs.remove(_carriersTsKey);
    await _prefs.remove(_categoriesKey);
    await _prefs.remove(_categoriesTsKey);
    await _prefs.remove(_stopTypesKey);
    await _prefs.remove(_stopTypesTsKey);
  }

  /// Clear technical caches without erasing user preferences.
  Future<void> clearAll() async {
    _memory.clear();
    _trainIndices.clear();
    for (final key in _prefs.getKeys().where(_isTechnicalKey).toList()) {
      await _prefs.remove(key);
    }
  }
}
