import 'package:trainly/models/models.dart';
import 'station_mapping.dart';
import 'package:trainly/utils/date_utils.dart' as app_date;

enum TrainStatusType {
  notStarted,
  inProgress,
  atStation,
  betweenStations,
  completed,
  cancelled,
  partialCancelled,
}

enum PositionSource { live, estimatedWithDelay, scheduleOnly }

class TrainPositionResult {
  final TrainStatusType status;
  final StationOnRoute? previousStation;
  final StationOnRoute? nextStation;
  final StationOnRoute? currentStation;
  final double progress;
  final int delayMinutes;
  final DateTime? estimatedArrival;
  final DateTime? estimatedDeparture;
  final PositionSource source;
  final String description;

  TrainPositionResult({
    required this.status,
    this.previousStation,
    this.nextStation,
    this.currentStation,
    required this.progress,
    required this.delayMinutes,
    this.estimatedArrival,
    this.estimatedDeparture,
    required this.source,
    required this.description,
  });
}

class TrainPositionResolver {
  static TrainPositionResult resolve({
    required TrainOperation? operation,
    required List<StationOnRoute> routeStations,
    required Map<int, String> stationNames,
    required DateTime now,
    String? operatingDate,
  }) {
    final date = operatingDate ?? operation?.operatingDate ?? '';
    // 1. Zabezpieczenia na start
    if (routeStations.isEmpty) {
      return TrainPositionResult(
        status: TrainStatusType.notStarted,
        progress: 0,
        delayMinutes: 0,
        source: PositionSource.scheduleOnly,
        description: 'Brak danych o rozkładzie',
      );
    }

    if (operation?.trainStatus == 'X') {
      return TrainPositionResult(
        status: TrainStatusType.cancelled,
        progress: 0,
        delayMinutes: 0,
        source: PositionSource.scheduleOnly,
        description: 'Pociąg odwołany',
      );
    }

    if (operation?.trainStatus == 'Q') {
      return TrainPositionResult(
        status: TrainStatusType.partialCancelled,
        progress: 0,
        delayMinutes: 0,
        source: PositionSource.scheduleOnly,
        description: 'Pociąg częściowo odwołany',
      );
    }

    // 2. Parsowanie czasów planowych pierwszej i ostatniej stacji
    final firstDep = app_date.scheduleDateTime(
            routeStations.first.departureTime, date,
            day: routeStations.first.departureDay) ??
        app_date.scheduleDateTime(routeStations.first.arrivalTime, date,
            day: routeStations.first.arrivalDay);
    final lastArr = app_date.scheduleDateTime(
            routeStations.last.arrivalTime, date,
            day: routeStations.last.arrivalDay) ??
        app_date.scheduleDateTime(routeStations.last.departureTime, date,
            day: routeStations.last.departureDay);

    // 3. Przed rozpoczęciem kursu
    if (firstDep != null && now.isBefore(firstDep)) {
      if (operation == null ||
          (operation.trainStatus != 'P' && operation.trainStatus != 'C')) {
        return TrainPositionResult(
          status: TrainStatusType.notStarted,
          progress: 0,
          delayMinutes: 0,
          source: PositionSource.scheduleOnly,
          description: 'Nie rozpoczął kursu',
        );
      }
    }

    // 4. Budowanie "StationData" z połączeniem z operations (po stabilnym stationId)

    final stationsData = <_InternalStationData>[];
    for (int i = 0; i < routeStations.length; i++) {
      final planned = routeStations[i];
      final opSt =
          operationForStop(planned, routeStations, operation?.stations ?? []);

      DateTime? pArr = app_date.scheduleDateTime(planned.arrivalTime, date,
          day: planned.arrivalDay);
      DateTime? pDep = app_date.scheduleDateTime(planned.departureTime, date,
          day: planned.departureDay);

      // Fallback if one of the times is missing
      if (pArr == null && pDep != null) pArr = pDep;
      if (pDep == null && pArr != null) pDep = pArr;

      stationsData.add(_InternalStationData(
        planned: planned,
        name: stationNames[planned.stationId] ?? 'Stacja bez nazwy',
        plannedArr: pArr,
        plannedDep: pDep,
        actualArr: app_date.parsePdpDateTime(opSt?.actualArrival),
        actualDep: app_date.parsePdpDateTime(opSt?.actualDeparture),
        arrivalDelay: app_date.timeDelay(
            opSt?.plannedArrival ?? planned.arrivalTime,
            opSt?.actualArrival,
            opSt?.arrivalDelayMinutes,
            operatingDate: date,
            day: planned.arrivalDay),
        departureDelay: app_date.timeDelay(
            opSt?.plannedDeparture ?? planned.departureTime,
            opSt?.actualDeparture,
            opSt?.departureDelayMinutes,
            operatingDate: date,
            day: planned.departureDay),
        isConfirmed: opSt?.isConfirmed ?? false,
      ));
    }

    // 5. Znajdź ostatnią potwierdzoną stację
    int lastConfirmedIndex = -1;
    bool hasActualDep = false;

    for (int i = 0; i < stationsData.length; i++) {
      final s = stationsData[i];

      if (s.actualDep != null && !s.actualDep!.isAfter(now)) {
        lastConfirmedIndex = i;
        hasActualDep = true;
      } else if (s.actualArr != null && !s.actualArr!.isAfter(now)) {
        lastConfirmedIndex = i;
        hasActualDep = false;
      } else if (s.isConfirmed) {
        // Zabezpieczenie przed API PLK: sprawdzenie czy czas nie jest w przyszlosci
        final refTime =
            s.actualArr ?? s.plannedArr ?? s.actualDep ?? s.plannedDep;
        if (refTime == null || !refTime.isAfter(now)) {
          lastConfirmedIndex = i;
          hasActualDep = false;
        } else {
          // If a confirmed station is in the future, we stop advancing lastConfirmedIndex
          break;
        }
      }
    }

    // 6. Ustalenie bieżącego opóźnienia
    int activeDelay = 0;
    if (lastConfirmedIndex >= 0) {
      final lastS = stationsData[lastConfirmedIndex];
      if (hasActualDep) {
        activeDelay = lastS.departureDelay;
      } else {
        activeDelay = lastS.arrivalDelay;
      }
    }
    if (operation?.trainStatus == 'C') {
      activeDelay = stationsData.last.arrivalDelay;
    }

    // 7. Zakończenie kursu
    if (operation?.trainStatus == 'C' ||
        lastConfirmedIndex == stationsData.length - 1) {
      return TrainPositionResult(
        status: TrainStatusType.completed,
        progress: 1.0,
        delayMinutes: activeDelay,
        source: lastConfirmedIndex >= 0
            ? PositionSource.live
            : PositionSource.scheduleOnly,
        description: 'Kurs zakończony',
      );
    }

    // Dodatkowy warunek zakończenia (gdy nie ma operations, ale czas minął)
    if (operation == null &&
        lastArr != null &&
        now.isAfter(lastArr.add(Duration(minutes: activeDelay)))) {
      return TrainPositionResult(
        status: TrainStatusType.completed,
        progress: 1.0,
        delayMinutes: activeDelay,
        source: PositionSource.scheduleOnly,
        description: 'Kurs powinien być zakończony',
      );
    }

    // 8. Wyliczanie aktualnego odcinka (od początku trasy!)
    for (int i = 0; i < stationsData.length - 1; i++) {
      final a = stationsData[i];
      final b = stationsData[i + 1];

      // Jeśli nextStation to ta sama stacja (błąd logiki API), przeskocz
      if (a.planned.stationId == b.planned.stationId) continue;

      if (a.plannedDep == null || b.plannedArr == null) continue;

      int currentDelay = activeDelay;

      DateTime correctedDepA = a.actualDep ??
          a.plannedDep!.add(Duration(
              minutes: i <= lastConfirmedIndex
                  ? (a.actualDep != null ? 0 : currentDelay)
                  : currentDelay));
      DateTime correctedArrB = b.actualArr ??
          b.plannedArr!.add(Duration(
              minutes: i + 1 <= lastConfirmedIndex ? 0 : currentDelay));
      DateTime correctedDepB = b.actualDep ??
          (b.plannedDep?.add(Duration(
                  minutes: i + 1 <= lastConfirmedIndex ? 0 : currentDelay)) ??
              correctedArrB);

      // Jesteśmy pomiędzy stacjami A i B
      if ((now.isAfter(correctedDepA) || now.isAtSameMomentAs(correctedDepA)) &&
          now.isBefore(correctedArrB)) {
        double progress = 0.0;
        final duration = correctedArrB.difference(correctedDepA).inSeconds;
        final elapsed = now.difference(correctedDepA).inSeconds;
        if (duration > 0) {
          progress = (elapsed / duration).clamp(0.0, 1.0);
        }

        final source = lastConfirmedIndex >= 0
            ? PositionSource.estimatedWithDelay
            : PositionSource.scheduleOnly;

        return TrainPositionResult(
          status: TrainStatusType.betweenStations,
          previousStation: a.planned,
          nextStation: b.planned,
          progress: progress,
          delayMinutes: currentDelay,
          estimatedArrival: correctedArrB,
          source: source,
          description: 'W drodze do: ${b.name}',
        );
      }

      // Jesteśmy na stacji B (oczekujemy na odjazd)
      if ((now.isAfter(correctedArrB) || now.isAtSameMomentAs(correctedArrB)) &&
          now.isBefore(correctedDepB)) {
        final source = lastConfirmedIndex >= 0
            ? PositionSource.estimatedWithDelay
            : PositionSource.scheduleOnly;

        return TrainPositionResult(
          status: TrainStatusType.atStation,
          currentStation: b.planned,
          nextStation:
              i + 2 < stationsData.length ? stationsData[i + 2].planned : null,
          progress: 1.0,
          delayMinutes: currentDelay,
          estimatedDeparture: correctedDepB,
          source: source,
          description: 'Na stacji: ${b.name}',
        );
      }
    }

    // 9. Jeśli żaden warunek nie złapał, a mamy operations - wyznacz odcinek na podstawie ostatniej potwierdzonej stacji
    if (lastConfirmedIndex >= 0 &&
        lastConfirmedIndex + 1 < stationsData.length) {
      final prev = stationsData[lastConfirmedIndex];
      final nxt = stationsData[lastConfirmedIndex + 1];
      if (!hasActualDep) {
        return TrainPositionResult(
          status: TrainStatusType.atStation,
          currentStation: prev.planned,
          nextStation: nxt.planned,
          progress: 0,
          delayMinutes: activeDelay,
          source: PositionSource.live,
          description: 'Na stacji: ${prev.name}',
        );
      }
      return TrainPositionResult(
        status: TrainStatusType.betweenStations,
        previousStation: prev.planned,
        nextStation: nxt.planned,
        progress: 0.5,
        delayMinutes: activeDelay,
        source: PositionSource.live,
        description: 'W drodze do: ${nxt.name}',
      );
    }

    return TrainPositionResult(
      status: TrainStatusType.inProgress,
      progress: 0.0,
      delayMinutes: activeDelay,
      source:
          operation != null ? PositionSource.live : PositionSource.scheduleOnly,
      description: 'W trasie',
    );
  }
}

class _InternalStationData {
  final StationOnRoute planned;
  final String name;
  final DateTime? plannedArr;
  final DateTime? plannedDep;
  final DateTime? actualArr;
  final DateTime? actualDep;
  final int arrivalDelay;
  final int departureDelay;
  final bool isConfirmed;

  _InternalStationData({
    required this.planned,
    required this.name,
    this.plannedArr,
    this.plannedDep,
    this.actualArr,
    this.actualDep,
    this.arrivalDelay = 0,
    this.departureDelay = 0,
    this.isConfirmed = false,
  });
}
