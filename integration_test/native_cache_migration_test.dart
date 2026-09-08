import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:trainly/services/cache_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Large legacy Android cache migrates without exporting values or losing preferences',
      (tester) async {
    final package = await PackageInfo.fromPlatform();
    expect(package.packageName, 'com.trainly.qa',
        reason: 'Run only in the isolated QA application.');
    final store = SharedPreferencesAsync(
        options: const SharedPreferencesAsyncAndroidOptions(
      backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
      originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
          fileName: 'KolejkaMigrationFixture'),
    ));
    final fixtureKeys = {
      'flutter.${CacheService.schemaKey}',
      'flutter.cache_train_index_2026-09-07',
      'flutter.cache_train_index_2026-09-08',
      'flutter.cache_favorite_stations',
      'flutter.cache_theme_mode',
    };
    await store.clear(allowList: fixtureKeys);
    await store.setString('flutter.cache_favorite_stations',
        '[{"stationId":60608,"stationName":"Opole Główne"}]');
    await store.setString('flutter.cache_theme_mode', 'light');
    final large = 'ż' * (8 * 1024 * 1024);
    await store.setString('flutter.cache_train_index_2026-09-07', large);
    await store.setString('flutter.cache_train_index_2026-09-08', large);
    final elapsed = Stopwatch()..start();
    await CacheService.migrateLegacyAndroid(store);
    elapsed.stop();
    expect(await store.getKeys(), {
      'flutter.${CacheService.schemaKey}',
      'flutter.cache_favorite_stations',
      'flutter.cache_theme_mode',
    });
    expect(await store.getString('flutter.cache_theme_mode'), 'light');
    expect(await store.getString('flutter.cache_favorite_stations'),
        contains('Opole Główne'));
    await CacheService.migrateLegacyAndroid(store);
    expect(tester.takeException(), isNull);
    // Only timing and fixture size, never preference contents.
    // ignore: avoid_print
    print(
        'ANDROID LEGACY MIGRATION: 32 MiB UTF-8 fixture, ${elapsed.elapsedMilliseconds} ms, preferences preserved');
    await store.clear(allowList: fixtureKeys);
  });
}
