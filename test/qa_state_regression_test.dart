import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainly/api/plk_api.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/services/cache_service.dart';
import 'api_resilience_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'Station change clears old board immediately; failure and late replies cannot relabel it',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheService();
    await cache.init();
    final now = DateTime.now().add(const Duration(minutes: 15));
    final date = now.toIso8601String().split('T').first;
    final pendingB = Completer<ResponseBody>();
    final adapter = ResponseAdapter((request) {
      if (request.path.endsWith('/operations')) {
        if (request.queryParameters['stations'] == '2') return pendingB.future;
        return jsonResponse({
          'trains': [
            {
              'scheduleId': 2026,
              'orderId': 42,
              'operatingDate': date,
              'stations': [
                {'stationId': 1, 'actualDeparture': now.toIso8601String()},
                {'stationId': 3}
              ]
            }
          ]
        });
      }
      return jsonResponse({
        'routes': [
          {
            'scheduleId': 2026,
            'orderId': 42,
            'nationalNumber': '5410',
            'commercialCategorySymbol': 'IC',
            'stations': []
          }
        ]
      });
    });
    final state = AppState()
      ..cache = cache
      ..api = PlkApi(clientFor(adapter))
      ..currentStation = Station(id: 1, name: 'Kędzierzyn-Koźle');
    await state.loadStationBoard(1);
    expect(state.stationDepartures.single.trainNumber, '5410');
    final selectB =
        state.selectManualStation(Station(id: 2, name: 'Warszawa Centralna'));
    expect(state.currentStation!.id, 2);
    expect(state.stationDepartures, isEmpty);
    await selectB;
    await state.selectManualStation(Station(id: 1, name: 'Kędzierzyn-Koźle'));
    expect(state.stationDepartures.single.trainNumber, '5410');
    pendingB.complete(jsonResponse({}, 429));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(state.currentStation!.id, 1);
    expect(state.stationDepartures.single.trainNumber, '5410');
    expect(state.stationBoardError, isNull);
    expect(
        adapter.calls, 4); // A+B operations and schedules, cached A on return.
    state.dispose();
  });

  test(
      'Missing bulk schedule resolves actual departure, local number and platform by route identity',
      () async {
    final now = DateTime.now().add(const Duration(minutes: 25));
    final date = now.toIso8601String().split('T').first;
    final hhmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final adapter = ResponseAdapter((request) {
      if (request.path.contains('/route/')) {
        return jsonResponse({
          'scheduleId': 2026,
          'orderId': 503588516,
          'nationalNumber': '36100',
          'commercialCategorySymbol': 'TLK',
          'name': 'PLANTY',
          'stations': [
            {
              'stationId': 67009,
              'departureTime': hhmm,
              'departureDay': 0,
              'departureTrainNumber': '36101',
              'departurePlatform': '1',
              'departureTrack': '5'
            },
            {'stationId': 9}
          ]
        });
      }
      if (request.path.endsWith('/operations')) {
        return jsonResponse({
          'trains': [
            {
              'scheduleId': 2026,
              'orderId': 503588516,
              'operatingDate': date,
              'stations': [
                {'stationId': 67009, 'actualDeparture': now.toIso8601String()},
                {'stationId': 9}
              ]
            }
          ]
        });
      }
      return jsonResponse({'routes': []});
    });
    final state = AppState()..api = PlkApi(clientFor(adapter));
    await state.loadStationBoard(67009);
    final item = state.stationDepartures.single;
    expect(item.trainNumber, '36101');
    expect(item.trainName, 'PLANTY');
    expect(item.trainCategory, 'TLK');
    expect(item.platform, '1');
    expect(item.track, '5');
    expect(item.time, hhmm);
    expect(DateTime.parse(item.actualTime!).day, now.day);
    expect(DateTime.parse(item.plannedTime!).minute, now.minute);
    await state.loadStationBoard(67009);
    expect(adapter.calls, 3); // No repeated metadata lookup on refresh.
    state.dispose();
  });

  test(
      'Train index metadata serves all 96 disruption references without extra HTTP',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheService();
    await cache.init();
    final routes = [
      for (var i = 0; i < 96; i++)
        {
          'scheduleId': 1,
          'orderId': i,
          'nationalNumber': '${1000 + i}',
          'commercialCategorySymbol': 'IC',
          'operatingDates': ['2026-09-07'],
          'stations': [
            {'stationId': 1},
            {'stationId': 2}
          ]
        }
    ];
    final adapter = ResponseAdapter((_) => jsonResponse({'routes': routes}));
    final state = AppState()
      ..cache = cache
      ..api = PlkApi(clientFor(adapter));
    final refs = [
      for (var i = 0; i < 96; i++) {'sid': 1, 'oid': i, 'od': '2026-09-07'}
    ];
    expect(await state.prepareAffectedTrains(refs), isTrue);
    for (var repeat = 0; repeat < 2; repeat++) {
      final resolved = await Future.wait([
        for (var i = 0; i < 96; i++)
          state.resolveAffectedTrain({'sid': 1, 'oid': i, 'od': '2026-09-07'})
      ]);
      expect(resolved.last['nationalNumber'], '1095');
    }
    expect(adapter.calls, 1);
    state.dispose();
  });

  test(
      'Disruptions and favorites survive recreating the cache without duplicates',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheService();
    await cache.init();
    await cache.saveDisruptions({
      'ts': '2026-09-07T13:00:00Z',
      'disruptions': [
        {'message': 'Awaria'}
      ]
    });
    final state = AppState()..cache = cache;
    final from = Station(id: 1, name: 'Opole'),
        to = Station(id: 2, name: 'Gliwice');
    await state.toggleFavoriteStation(from);
    await state.toggleFavoriteStation(from);
    await state.toggleFavoriteStation(from);
    await state.toggleFavoriteRoute(from, to);
    final reloaded = CacheService();
    await reloaded.init();
    expect(reloaded.loadDisruptions()!['disruptions'], [
      {'message': 'Awaria'}
    ]);
    expect(reloaded.loadFavoriteStations(), hasLength(1));
    expect(reloaded.loadFavoriteRoutes(), hasLength(1));
    await state.removeFavoriteRoute(1, 2);
    expect(reloaded.loadFavoriteRoutes(), isEmpty);
    state.dispose();
  });
}
