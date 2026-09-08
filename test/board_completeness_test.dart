import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/api/plk_api.dart';
import 'package:trainly/app_state.dart';
import 'package:trainly/models/models.dart';
import 'api_resilience_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Every API page is loaded without changing filters', () async {
    final adapter = ResponseAdapter((request) {
      expect(request.queryParameters['stations'], '1');
      final page = request.queryParameters['page'] as int? ?? 1;
      return jsonResponse({
        'trains': [
          {'orderId': page}
        ],
        'stations': {'$page': 'Station $page'},
        'pagination': {
          'page': page,
          'totalPages': 3,
          'totalCount': 3,
          'hasNextPage': page < 3
        },
      });
    });
    final result =
        await PlkApi(clientFor(adapter)).getOperations(stations: '1');
    expect((result['trains'] as List).length, 3);
    expect((result['stations'] as Map).length, 3);
    expect(adapter.calls, 3);
  });
  test(
      'A repeated page fails visibly rather than returning an incomplete board',
      () async {
    final adapter = ResponseAdapter((request) => jsonResponse({
          'trains': [
            {'orderId': 1}
          ],
          'pagination': {'page': 1, 'hasNextPage': true},
        }));
    await expectLater(
        PlkApi(clientFor(adapter)).getOperations(), throwsFormatException);
    expect(adapter.calls, 2);
  });
  test(
      'Board includes schedule-only services, earlier trains and separate runs with the same number',
      () async {
    final now = DateTime.now();
    final date = now.toIso8601String().split('T').first;
    final tomorrow = DateTime(now.year, now.month, now.day + 1)
        .toIso8601String()
        .split('T')
        .first;
    Map<String, dynamic> route(int order, String time, {String? day}) => {
          'scheduleId': 2026,
          'orderId': order,
          'nationalNumber': '1234',
          'operatingDates': [day ?? date],
          'commercialCategorySymbol': 'R',
          'stations': [
            {'stationId': 1, 'orderNumber': 1, 'departureTime': time},
            {'stationId': 2, 'orderNumber': 2, 'arrivalTime': '23:59'},
          ],
        };
    final adapter =
        ResponseAdapter((request) => request.path.endsWith('/operations')
            ? jsonResponse({
                'trains': [
                  {
                    'scheduleId': 2026,
                    'orderId': 1,
                    'operatingDate': date,
                    'trainStatus': 'C',
                    'stations': [
                      {
                        'stationId': 1,
                        'plannedDeparture': '${date}T00:05:00',
                        'actualDeparture': '${date}T00:07:00'
                      },
                      {'stationId': 2, 'plannedArrival': '${date}T00:30:00'},
                    ],
                  }
                ]
              })
            : jsonResponse({
                'routes': [
                  route(1, '00:05'),
                  route(2, '23:00'),
                  route(2, '23:00'),
                  route(3, '23:15'),
                  route(4, '23:45', day: tomorrow)
                ]
              }));
    final state = AppState()
      ..api = PlkApi(clientFor(adapter))
      ..currentStation = Station(id: 1, name: 'A');
    await state.loadStationBoard(1);
    expect(state.stationBoardError, isNull);
    expect(state.stationDepartures.map((r) => r.orderId), [1, 2, 3]);
    expect(state.stationDepartures.first.actualTime, contains('00:07'));
    expect(
        state.stationDepartures.every((r) => r.trainNumber == '1234'), isTrue);
    state.dispose();
  });
}
