import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/models/models.dart';
import 'package:trainly/models/train_position_resolver.dart';

void main() {
  test('Przyklad 1: Pociag miedzy stacjami', () {
    final now = DateTime(2026, 9, 6, 13, 20);

    final st1 = StationOnRoute(
      stationId: 1,
      orderNumber: 1,
      arrivalTime: '2026-09-06T13:00:00',
      departureTime: '2026-09-06T13:08:00',
      raw: {},
    );
    final st2 = StationOnRoute(
      stationId: 2,
      orderNumber: 2,
      arrivalTime: '2026-09-06T13:27:00',
      departureTime: '2026-09-06T13:28:00',
      raw: {},
    );

    final op = TrainOperation(
      scheduleId: 1,
      orderId: 1,
      trainOrderId: 1,
      operatingDate: '2026-09-06',
      trainStatus: 'P',
      stations: [
        OperationStation(
          stationId: 1,
          actualSequenceNumber: 1,
          actualDeparture: '2026-09-06T13:15:00', // 7 min delay
          departureDelayMinutes: 7,
          isConfirmed: true,
          isCancelled: false,
          raw: {},
        ),
      ],
      raw: {},
    );

    final names = {1: 'Leszno', 2: 'Rawicz'};

    final res = TrainPositionResolver.resolve(
      operation: op,
      routeStations: [st1, st2],
      stationNames: names,
      now: now,
    );

    expect(res.status, TrainStatusType.betweenStations);
    expect(res.previousStation?.stationId, 1);
    expect(res.nextStation?.stationId, 2);
    expect(res.delayMinutes, 7);
    expect(res.estimatedArrival, DateTime(2026, 9, 6, 13, 34)); // 13:27 + 7min
    expect(res.source, PositionSource.estimatedWithDelay);
    expect(res.description, 'W drodze do: Rawicz');
  });

  test('Test przyszlego pociagu', () {
    final now = DateTime(2026, 9, 6, 13, 13);

    final st1 = StationOnRoute(
      stationId: 1,
      orderNumber: 1,
      arrivalTime: '2026-09-06T14:40:00',
      departureTime: '2026-09-06T14:48:00',
      raw: {},
    );
    final st2 = StationOnRoute(
      stationId: 2,
      orderNumber: 2,
      arrivalTime: '2026-09-06T15:31:00',
      departureTime: '2026-09-06T15:33:00',
      raw: {},
    );

    final names = {1: 'Wroclaw', 2: 'Opole'};

    final res = TrainPositionResolver.resolve(
      operation: null,
      routeStations: [st1, st2],
      stationNames: names,
      now: now,
    );

    expect(res.status, TrainStatusType.notStarted);
    expect(res.description, 'Nie rozpoczął kursu');
  });

  test('Test zakonczonego pociagu', () {
    final now = DateTime(2026, 9, 6, 16, 00);

    final st1 = StationOnRoute(
      stationId: 1,
      orderNumber: 1,
      arrivalTime: '2026-09-06T14:40:00',
      departureTime: '2026-09-06T14:48:00',
      raw: {},
    );
    final st2 = StationOnRoute(
      stationId: 2,
      orderNumber: 2,
      arrivalTime: '2026-09-06T15:31:00',
      departureTime: '2026-09-06T15:33:00',
      raw: {},
    );

    final names = {1: 'Wroclaw', 2: 'Opole'};

    final op = TrainOperation(
      scheduleId: 1,
      orderId: 1,
      trainOrderId: 1,
      operatingDate: '2026-09-06',
      trainStatus: 'C',
      stations: [],
      raw: {},
    );

    final res = TrainPositionResolver.resolve(
      operation: op,
      routeStations: [st1, st2],
      stationNames: names,
      now: now,
    );

    expect(res.status, TrainStatusType.completed);
    expect(res.description, 'Kurs zakończony');
  });
}
