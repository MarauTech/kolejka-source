import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final station = {'id': 60608, 'name': 'Opole Główne'};
  final favorite = {
    'fromStationId': 1,
    'fromStationName': 'A',
    'toStationId': 2,
    'toStationName': 'B'
  };

  test('Current schema survives restart with dictionaries and preferences',
      () async {
    SharedPreferences.setMockInitialValues({});
    final first = CacheService();
    await first.init();
    await first.saveStations([station]);
    await first.saveFavoriteStations([station]);
    await first.saveFavoriteRoutes([favorite]);
    await first.saveThemeMode('light');
    final restarted = AppState();
    await restarted.init();
    expect(restarted.cache.loadStations(), [station]);
    expect(restarted.favoriteStations.single.id, 60608);
    expect(restarted.favoriteRoutes.single.toStationId, 2);
    expect(restarted.themeMode, ThemeMode.light);
    restarted.dispose();
  });

  for (final corrupt in [
    '{broken',
    '{}',
    '[17]',
    '[{}]',
    '[{"id":"wrong","name":"A"}]',
    17
  ]) {
    test('Invalid dictionary $corrupt is evicted without touching valid data',
        () async {
      SharedPreferences.setMockInitialValues({
        CacheService.schemaKey: CacheService.cacheSchemaVersion,
        'cache_stations': corrupt,
        'cache_stations_ts': DateTime.now().millisecondsSinceEpoch,
        'cache_carriers': '[{"code":"IC","name":"Intercity"}]',
        'cache_carriers_ts': DateTime.now().millisecondsSinceEpoch,
        'cache_favorite_stations': jsonEncode([station]),
      });
      final cache = CacheService();
      await cache.init();
      expect(cache.loadStations(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('cache_stations'), isFalse);
      expect(cache.loadCarriers()!.single['code'], 'IC');
      expect(cache.loadFavoriteStations().single['id'], 60608);
      await cache.saveStations([station]);
      final restart = CacheService();
      await restart.init();
      expect(restart.loadStations(), [station]);
    });
  }

  test('Old schema clears only API caches and preserves every user setting',
      () async {
    SharedPreferences.setMockInitialValues({
      CacheService.schemaKey: 1,
      'cache_stations': 'old format',
      'cache_train_index_2026-09-08': 'legacy nationwide JSON',
      'cache_favorite_stations': jsonEncode([station]),
      'cache_favorite_routes': jsonEncode([favorite]),
      'cache_recent_stations': jsonEncode([station]),
      'cache_last_selected_station': jsonEncode(station),
      'cache_theme_mode': 'dark',
      'location_permission_permanently_denied': true,
    });
    final state = AppState();
    await state.init();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(CacheService.schemaKey), 2);
    expect(prefs.containsKey('cache_train_index_2026-09-08'), isFalse);
    expect(state.favoriteStations.single.id, 60608);
    expect(state.favoriteRoutes.single.toStationId, 2);
    expect(state.recentStations.single.id, 60608);
    expect(state.cache.loadLastSelectedStation()!['id'], 60608);
    expect(state.themeMode, ThemeMode.dark);
    expect(prefs.getBool('location_permission_permanently_denied'), isTrue);
    state.dispose();
  });

  test('Bad optional favorite timestamp and mixed records cannot break startup',
      () async {
    SharedPreferences.setMockInitialValues({
      'cache_favorite_stations': jsonEncode([
        17,
        {...station, 'savedAt': 123}
      ]),
      'cache_favorite_routes': jsonEncode([
        {...favorite, 'savedAt': []}
      ]),
      'cache_recent_stations': jsonEncode([false, station]),
      'cache_theme_mode': 9,
      'cache_disruptions': 12,
    });
    for (var restart = 0; restart < 4; restart++) {
      final state = AppState();
      await state.init();
      expect(state.favoriteStations.single.id, 60608);
      expect(state.favoriteRoutes.single.toStationId, 2);
      expect(state.recentStations.single.id, 60608);
      state.dispose();
    }
  });

  test('Wrong timestamp and malformed disruption model are removed', () async {
    SharedPreferences.setMockInitialValues({
      CacheService.schemaKey: 2,
      'cache_stations': jsonEncode([station]),
      'cache_stations_ts': 'yesterday',
      'cache_disruptions': '{"disruptions":[{"affectedRoutes":[false]}]}',
    });
    final cache = CacheService();
    await cache.init();
    expect(cache.loadStations(), isNull);
    expect(cache.loadDisruptions(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('cache_disruptions'), isFalse);
  });

  test('Oversized responses stay in memory and route indices are bounded',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheService();
    await cache.init();
    final large = [
      {'id': 1, 'name': 'A' * (CacheService.maxEntryBytes + 1)}
    ];
    await cache.saveStations(large);
    expect(cache.loadStations(), large);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('cache_stations'), isFalse);
    for (var i = 1; i <= 3; i++) {
      await cache.saveTrainIndex('2026-09-0$i', []);
    }
    expect(cache.loadTrainIndex('2026-09-01'), isNull);
    expect(cache.loadTrainIndex('2026-09-02'), isEmpty);
    expect(prefs.getKeys().any((k) => k.startsWith('cache_train_index_')),
        isFalse);
    await cache.saveFavoriteStations([station]);
    await cache.clearAll();
    expect(cache.loadFavoriteStations().single['id'], 60608);
  });
}
