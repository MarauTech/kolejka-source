import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/utils/date_utils.dart' as app_date;
import 'package:trainly/models/models.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/services/location_service.dart';

void main() {
  group('Date and Time Utils Tests', () {
    test('formatTimeSpan handles standard HH:mm:ss format', () {
      expect(app_date.formatTimeSpan('08:32:00'), '08:32');
      expect(app_date.formatTimeSpan('14:05:30'), '14:05');
      expect(app_date.formatTimeSpan(''), '--:--');
      expect(app_date.formatTimeSpan(null), '--:--');
    });

    test('calculateTravelTime calculates duration between two time spans', () {
      final result = app_date.calculateTravelTime('08:32:00', '11:07:00');
      expect(result, '2 h 35 min');
    });

    test('formatDelay formats on-time and delay minutes without emoji', () {
      expect(app_date.formatDelay(0), 'Planowo');
      expect(app_date.formatDelay(12), '+12 min');
      expect(app_date.formatDelay(null), 'Planowo');
    });
  });

  group('Train Number Normalization Tests', () {
    test('Extracts pure digits from train queries', () {
      expect(AppState.normalizeTrainNumber('5410'), '5410');
      expect(AppState.normalizeTrainNumber('IC 5410'), '5410');
      expect(AppState.normalizeTrainNumber('TLK 35100'), '35100');
      expect(AppState.normalizeTrainNumber('KM 19432'), '19432');
      expect(AppState.normalizeTrainNumber('EIP 1300'), '1300');
      expect(AppState.normalizeTrainNumber('Kormoran'), 'KORMORAN');
    });

    test('NormalizeText handles polish characters and whitespace', () {
      expect(AppState.normalizeText('  Kormoran  '), 'kormoran');
      expect(AppState.normalizeText('ŁÓDŹ FABRYCZNA'), 'lodz fabryczna');
      expect(
          AppState.normalizeText('Pociąg   Pośpieszny'), 'pociag pospieszny');
    });
  });

  group('Location and OSM Matching Tests', () {
    test('Normalize station names for PLK and OSM matching', () {
      expect(
        LocationService.normalizeStationName('Stacja PKP Warszawa Centralna'),
        'warszawa centralna',
      );
      expect(
        LocationService.normalizeStationName('Kraków Główny'),
        'krakow glowny',
      );
      expect(
        LocationService.normalizeStationName('Przystanek Łódź Fabryczna'),
        'lodz fabryczna',
      );
    });

    test('Haversine distance calculation is accurate', () {
      // Warsaw (52.2297, 21.0122) to Krakow (50.0647, 19.9450) is ~250-260 km
      final dist =
          LocationService.haversineDistance(52.2297, 21.0122, 50.0647, 19.9450);
      expect(dist, greaterThan(240));
      expect(dist, lessThan(270));
    });

    test('Fuzzy station matching finds PLK station', () {
      final service = LocationService();
      final stations = [
        Station(id: 1, name: 'WARSZAWA CENTRALNA'),
        Station(id: 2, name: 'KRAKÓW GŁÓWNY'),
        Station(id: 3, name: 'GDAŃSK GŁÓWNY'),
      ];

      final match1 = service.matchPlkStation('Warszawa Centralna', stations);
      expect(match1?.id, 1);

      final match2 =
          service.matchPlkStation('Stacja kolejowa Kraków Główny', stations);
      expect(match2?.id, 2);
    });
  });

  group('Train Position Tests', () {
    test('Calculates atStation status correctly', () {
      final op = TrainOperation(
        scheduleId: 1,
        orderId: 1,
        trainOrderId: 5410,
        operatingDate: '2025-04-14',
        trainStatus: 'P',
        stations: [
          OperationStation(
            stationId: 10,
            actualSequenceNumber: 1,
            actualArrival: '2025-04-14T10:00:00',
            actualDeparture: '2025-04-14T10:02:00',
            isConfirmed: true,
            isCancelled: false,
            raw: {},
          ),
          OperationStation(
            stationId: 20,
            actualSequenceNumber: 2,
            actualArrival: '2025-04-14T10:30:00',
            actualDeparture: null, // At station 20!
            isConfirmed: true,
            isCancelled: false,
            raw: {},
          ),
          OperationStation(
            stationId: 30,
            actualSequenceNumber: 3,
            isConfirmed: false,
            isCancelled: false,
            raw: {},
          ),
        ],
        raw: {},
      );

      final pos = TrainPositionInfo.compute(
        operation: op,
        routeStations: [
          StationOnRoute(stationId: 10, orderNumber: 1, raw: {}),
          StationOnRoute(stationId: 20, orderNumber: 2, raw: {}),
          StationOnRoute(stationId: 30, orderNumber: 3, raw: {}),
        ],
        stationNames: {10: 'Gdańsk', 20: 'Tczew', 30: 'Malbork'},
      );

      expect(pos.type, TrainStatusType.betweenStations);
      expect(pos.currentStationId, 20);
      expect(pos.description, contains('Ostatnia stacja: Tczew'));
    });

    test('Calculates betweenStations status correctly', () {
      final op = TrainOperation(
        scheduleId: 1,
        orderId: 1,
        trainOrderId: 5410,
        operatingDate: '2025-04-14',
        trainStatus: 'P',
        stations: [
          OperationStation(
            stationId: 10,
            actualSequenceNumber: 1,
            actualArrival: '2025-04-14T10:00:00',
            actualDeparture: '2025-04-14T10:02:00', // Departed station 10
            isConfirmed: true,
            isCancelled: false,
            raw: {},
          ),
          OperationStation(
            stationId: 20,
            actualSequenceNumber: 2,
            actualArrival: null, // Not arrived at station 20 yet
            actualDeparture: null,
            isConfirmed: false,
            isCancelled: false,
            raw: {},
          ),
        ],
        raw: {},
      );

      final pos = TrainPositionInfo.compute(
        operation: op,
        routeStations: [
          StationOnRoute(stationId: 10, orderNumber: 1, raw: {}),
          StationOnRoute(stationId: 20, orderNumber: 2, raw: {}),
        ],
        stationNames: {10: 'Gdańsk', 20: 'Tczew'},
        nowOverride: DateTime.parse('2025-04-14T11:00:00'),
      );

      expect(pos.type, TrainStatusType.betweenStations);
      expect(pos.currentStationId, 10);
      expect(pos.nextStationId, 20);
      expect(pos.description, contains('Ostatnia stacja: Gdańsk'));
    });

    test('IC 8314 Regression: Future station cannot be marked as reached even if isConfirmed', () {
      final op = TrainOperation(
        scheduleId: 1,
        orderId: 1,
        trainOrderId: 8314,
        operatingDate: '2026-09-06',
        trainStatus: 'P',
        stations: [
          OperationStation(
            stationId: 10, // Szczecin
            actualSequenceNumber: 1,
            actualDeparture: '2026-09-06T06:42:00',
            isConfirmed: true,
            isCancelled: false,
            raw: {},
          ),
          OperationStation(
            stationId: 20, // Kędzierzyn
            actualSequenceNumber: 20,
            actualArrival: '2026-09-06T12:00:00',
            actualDeparture: '2026-09-06T12:05:00',
            isConfirmed: true,
            isCancelled: false,
            raw: {},
          ),
          OperationStation(
            stationId: 30, // Przemyśl (future!)
            actualSequenceNumber: 28,
            actualArrival: '2026-09-06T16:51:00', // This time is in the future
            actualDeparture: null,
            isConfirmed: true, // Suppose API mistakenly returns true or it's a confirmed planned track
            isCancelled: false,
            raw: {},
          ),
        ],
        raw: {},
      );

      final pos = TrainPositionInfo.compute(
        operation: op,
        routeStations: [
          StationOnRoute(stationId: 10, orderNumber: 1, raw: {}),
          StationOnRoute(stationId: 20, orderNumber: 20, raw: {}),
          StationOnRoute(stationId: 30, orderNumber: 28, raw: {}),
        ],
        stationNames: {10: 'Szczecin', 20: 'Kędzierzyn-Koźle', 30: 'Przemyśl Główny'},
        nowOverride: DateTime.parse('2026-09-06T12:20:00'), // Current time is 12:20
      );

      expect(pos.currentStationId, 20); // Should stop at Kędzierzyn-Koźle
      expect(pos.nextStationId, 30);
      expect(pos.description, contains('Kędzierzyn-Koźle'));
      expect(pos.description, isNot(contains('Przemyśl Główny (odjazd'))); // Przemyśl is not the last station
    });
  });

  group('Favorites Models Tests', () {
    test('FavoriteStation toJson and fromJson', () {
      final fav = FavoriteStation(id: 100, name: 'Poznań Główny');
      final json = fav.toJson();
      final restored = FavoriteStation.fromJson(json);

      expect(restored.id, 100);
      expect(restored.name, 'Poznań Główny');
    });

    test('FavoriteRoute toJson and fromJson', () {
      final route = FavoriteRoute(
        fromStationId: 100,
        fromStationName: 'Poznań Główny',
        toStationId: 200,
        toStationName: 'Wrocław Główny',
      );
      final json = route.toJson();
      final restored = FavoriteRoute.fromJson(json);

      expect(restored.fromStationId, 100);
      expect(restored.toStationId, 200);
      expect(restored.fromStationName, 'Poznań Główny');
      expect(restored.toStationName, 'Wrocław Główny');
    });
  });

  group('No Emoji Verification', () {
    test('Zero emojis and disallowed unicode symbols across all lib files', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      // Regex matching common emoji unicode ranges and forbidden symbols
      final emojiPattern = RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[↔→←↑↓•]',
        unicode: true,
      );

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final matches = emojiPattern.allMatches(content).toList();
        expect(
          matches.isEmpty,
          isTrue,
          reason:
              'File ${file.path} contains forbidden emoji/symbol: ${matches.map((m) => m.group(0)).join(', ')}',
        );
      }
    });
  });
}
