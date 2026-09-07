import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainly/api/api_client.dart';
import 'package:trainly/api/plk_api.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';

class FixtureApi extends PlkApi {
  FixtureApi() : super(ApiClient());
  int routeCalls = 0;
  bool fail = false;
  Map<String, dynamic>? routeResponse;
  @override
  Future<Map<String, dynamic>> getScheduleRoute(
      int scheduleId, int orderId) async {
    routeCalls++;
    if (fail) throw StateError('secret_payload');
    return routeResponse ??
        {
          'nationalNumber': '3819',
          'commercialCategorySymbol': 'IC',
          'name': 'MEHOFFER'
        };
  }

  @override
  Future<Map<String, dynamic>> getDataVersion() async {
    if (fail) throw StateError('secret_payload');
    return {
      'timestamp': '2026-09-06T12:00:00',
      'dataVersion': 'secret_payload'
    };
  }
}

class FixtureState extends AppState {
  final fixtureApi = FixtureApi();
  TrainOperation? updatedOperation;
  int? requestedOperationId;
  String? requestedOperationDate;
  DateTime? searchedDate;
  TimeOfDay? searchedTime;
  Station? searchedFrom;
  Station? searchedTo;
  FixtureState() {
    api = fixtureApi;
  }
  @override
  Future<TrainOperation?> getTrainOperation(
      int scheduleId, int orderId, String operatingDate) async {
    requestedOperationId = orderId;
    requestedOperationDate = operatingDate;
    return updatedOperation;
  }

  @override
  Future<void> loadStationBoard(int stationId) async {}
  @override
  Future<void> loadDictionaries() async {}
  @override
  Future<List<ConnectionResult>> searchConnections(
      {required Station fromStation,
      required Station toStation,
      required DateTime date,
      required TimeOfDay time}) async {
    searchedFrom = fromStation;
    searchedTo = toStation;
    searchedDate = date;
    searchedTime = time;
    return [connectionFixture()];
  }

  @override
  Future<Map<String, dynamic>> getDisruptions() async => {
        'disruptions': [
          {
            'disruptionId': 1,
            'message': 'Awaria sieci trakcyjnej',
            'affectedRoutes': [
              {
                'scheduleId': 941965170,
                'orderId': 228097641,
                'trainOrderId': 124427125
              },
              {
                'name':
                    'Bardzo długa nazwa pociągu wymagająca zawinięcia na małym ekranie'
              },
              {'trainOrderId': 999999999},
            ],
            'rawMarker': 'secret_payload'
          }
        ],
      };
  @override
  Future<OperationStatistics> getOperationStatistics({String? date}) async =>
      OperationStatistics(
          totalTrains: 12345,
          notStarted: 2000,
          inProgress: 10000,
          completed: 300,
          cancelled: 40,
          partialCancelled: 5,
          generatedAt: '2026-09-06T12:00:00',
          raw: {'secret_payload': 1});
}

ConnectionResult connectionFixture(
    {bool shortTimes = false, bool noPosition = false}) {
  final stops = List.generate(
      16,
      (i) => StationOnRoute(
          stationId: 1000 + i,
          orderNumber: i + 1,
          arrivalTime: noPosition
              ? null
              : '${shortTimes ? '' : '2026-09-06T'}10:${(i * 2).toString().padLeft(2, '0')}:00',
          departureTime: noPosition
              ? null
              : '${shortTimes ? '' : '2026-09-06T'}10:${(i * 2).toString().padLeft(2, '0')}:30',
          departurePlatform: '4',
          departureTrack: '3',
          raw: {}));
  final operations = [0, 1, 2, 3, 4, 6, 8, 9, 10]
      .map((i) => OperationStation(
          stationId: noPosition ? 9000 + i : 1000 + i,
          plannedSequenceNumber: i + 1,
          actualSequenceNumber: i + 30,
          actualDeparture: noPosition
              ? null
              : '2026-09-06T10:${(i * 2).toString().padLeft(2, '0')}:30',
          isConfirmed: !noPosition,
          isCancelled: false,
          raw: {}))
      .toList()
      .reversed
      .toList();
  final route = TrainRoute(
      scheduleId: 1,
      orderId: 2,
      nationalNumber: '3819',
      name: 'MEHOFFER',
      stations: stops,
      operatingDates: ['2026-09-06'],
      connections: [],
      raw: {});
  return ConnectionResult(
      route: route,
      fromStop: stops.first,
      toStop: stops.last,
      fromStationName: 'Warszawa Centralna',
      toStationName: 'Kraków Główny',
      carrierName: 'PKP Intercity',
      commercialCategory: 'IC',
      operatingDate: '2026-09-06',
      operation: TrainOperation(
          scheduleId: 1,
          orderId: 2,
          trainOrderId: 3,
          operatingDate: '2026-09-06',
          trainStatus: 'P',
          stations: operations,
          raw: {}));
}
