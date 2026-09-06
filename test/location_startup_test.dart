import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/services/cache_service.dart';
import 'package:trainly/services/location_service.dart';
import 'fixtures.dart';

class MemoryCache extends CacheService {
  @override
  Future<void> saveNearestStation(
      int id, String name, double lat, double lon) async {}
  @override
  Future<void> saveLastSelectedStation(int id, String name) async {}
}

class PendingLocation extends LocationService {
  final result = Completer<NearestStationResult?>();
  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.granted;
  @override
  Future<NearestStationResult?> findNearestStation(List<Station> stations) =>
      result.future;
}

void main() {
  for (final succeeds in [false, true]) {
    test('GPS completes and preserves fallback on failure: $succeeds',
        () async {
      final location = PendingLocation();
      final state = FixtureState()
        ..cache = MemoryCache()
        ..locationService = location
        ..currentStation = Station(id: 1, name: 'Ostatnia stacja');
      final pending = state.detectNearestStation();
      expect(state.isDetectingLocation, isTrue);
      expect(state.currentStation?.id, 1);
      location.result.complete(succeeds
          ? NearestStationResult(
              station: Station(id: 2, name: 'Najbliższa'),
              distanceKm: 1,
              userLatitude: 52,
              userLongitude: 21)
          : null);
      await pending;
      expect(state.isDetectingLocation, isFalse);
      expect(state.currentStation?.id, succeeds ? 2 : 1);
      expect(state.isStationFromGps, succeeds);
      state.dispose();
    });
  }
  test('Manual station selection wins over a pending GPS response', () async {
    final location = PendingLocation();
    final state = FixtureState()
      ..cache = MemoryCache()
      ..locationService = location;
    final pending = state.detectNearestStation();
    await state.selectManualStation(Station(id: 3, name: 'Wybrana ręcznie'));
    location.result.complete(NearestStationResult(
        station: Station(id: 2, name: 'GPS'),
        distanceKm: 1,
        userLatitude: 52,
        userLongitude: 21));
    await pending;
    expect(state.currentStation?.id, 3);
    expect(state.isStationFromGps, isFalse);
    state.dispose();
  });
}
