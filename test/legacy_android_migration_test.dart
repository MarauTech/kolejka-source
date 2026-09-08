import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainly/services/cache_service.dart';

class LegacyStore implements SharedPreferencesAsync {
  final values = <String, Object?>{
    'flutter.cache_train_index_2026-09-07': 'large payload must never be read',
    'flutter.cache_train_index_2026-09-07_ts': 12,
    'flutter.cache_stations': 'old dictionary',
    'flutter.cache_favorite_stations': 'passenger favorites',
    'flutter.cache_favorite_routes': 'passenger routes',
    'flutter.cache_theme_mode': 'dark',
    'flutter.interface_style': 'glass',
    'another_plugin_setting': 'preserve',
  };
  final _calls = [0, 0];
  int get writes => _calls[0];
  int get keyReads => _calls[1];
  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async {
    expect(allowList, {'flutter.${CacheService.schemaKey}'});
    return {
      for (final key in allowList!)
        if (values.containsKey(key)) key: values[key]
    };
  }

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async {
    _calls[1]++;
    return values.keys.toSet();
  }

  @override
  Future<void> clear({Set<String>? allowList}) async {
    expect(allowList, isNotNull);
    _calls[0]++;
    for (final key in allowList!) {
      values.remove(key);
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
      'Android migration removes technical keys in one batch before any large values are decoded',
      () async {
    final store = LegacyStore();
    await CacheService.migrateLegacyAndroid(store);
    expect(store.writes, 1);
    expect(store.values.keys.where((k) => k.contains('train_index')), isEmpty);
    expect(
        store.values['flutter.cache_favorite_stations'], 'passenger favorites');
    expect(store.values['flutter.cache_favorite_routes'], 'passenger routes');
    expect(store.values['flutter.cache_theme_mode'], 'dark');
    expect(store.values['flutter.interface_style'], 'glass');
    expect(store.values['another_plugin_setting'], 'preserve');
    await CacheService.migrateLegacyAndroid(store);
    expect(store.writes, 1);
    expect(store.keyReads, 1);
  });
}
