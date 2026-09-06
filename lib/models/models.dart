import '../utils/date_utils.dart' as app_date;

/// Station from /api/v1/dictionaries/stations
class Station {
  final int id;
  final String name;

  Station({required this.id, required this.name});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Carrier from /api/v1/dictionaries/carriers
class Carrier {
  final String code;
  final String name;
  final String? validFrom;
  final String? validTo;

  Carrier(
      {required this.code, required this.name, this.validFrom, this.validTo});

  factory Carrier.fromJson(Map<String, dynamic> json) {
    return Carrier(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      validFrom: json['validFrom'] as String?,
      validTo: json['validTo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'validFrom': validFrom,
        'validTo': validTo,
      };
}

/// Commercial category from /api/v1/dictionaries/commercial-categories
class CommercialCategory {
  final String code;
  final String name;
  final String? carrierCode;
  final String? speedCategoryCode;

  CommercialCategory({
    required this.code,
    required this.name,
    this.carrierCode,
    this.speedCategoryCode,
  });

  factory CommercialCategory.fromJson(Map<String, dynamic> json) {
    return CommercialCategory(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      carrierCode: json['carrierCode'] as String?,
      speedCategoryCode: json['speedCategoryCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'carrierCode': carrierCode,
        'speedCategoryCode': speedCategoryCode,
      };
}

/// Stop type from /api/v1/dictionaries/stop-types
class StopType {
  final int id;
  final String description;

  StopType({required this.id, required this.description});

  factory StopType.fromJson(Map<String, dynamic> json) {
    return StopType(
      id: json['id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
      };
}

/// Station on a route from /api/v1/schedules
class StationOnRoute {
  final int stationId;
  final int orderNumber;
  final String? arrivalCommercialCategory;
  final String? arrivalTrainNumber;
  final String? arrivalPlatform;
  final String? arrivalTrack;
  final int? arrivalDay;
  final String? arrivalTime;
  final String? departureCommercialCategory;
  final String? departureTrainNumber;
  final String? departurePlatform;
  final String? departureTrack;
  final int? departureDay;
  final String? departureTime;
  final int? stopTypeId;
  final String? stopTypeName;
  final Map<String, dynamic> raw;

  StationOnRoute({
    required this.stationId,
    required this.orderNumber,
    this.arrivalCommercialCategory,
    this.arrivalTrainNumber,
    this.arrivalPlatform,
    this.arrivalTrack,
    this.arrivalDay,
    this.arrivalTime,
    this.departureCommercialCategory,
    this.departureTrainNumber,
    this.departurePlatform,
    this.departureTrack,
    this.departureDay,
    this.departureTime,
    this.stopTypeId,
    this.stopTypeName,
    required this.raw,
  });

  factory StationOnRoute.fromJson(Map<String, dynamic> json) {
    return StationOnRoute(
      stationId: json['stationId'] as int? ?? 0,
      orderNumber: json['orderNumber'] as int? ?? 0,
      arrivalCommercialCategory: json['arrivalCommercialCategory'] as String?,
      arrivalTrainNumber: json['arrivalTrainNumber'] as String?,
      arrivalPlatform: json['arrivalPlatform'] as String?,
      arrivalTrack: json['arrivalTrack'] as String?,
      arrivalDay: json['arrivalDay'] as int?,
      arrivalTime: json['arrivalTime'] as String?,
      departureCommercialCategory:
          json['departureCommercialCategory'] as String?,
      departureTrainNumber: json['departureTrainNumber'] as String?,
      departurePlatform: json['departurePlatform'] as String?,
      departureTrack: json['departureTrack'] as String?,
      departureDay: json['departureDay'] as int?,
      departureTime: json['departureTime'] as String?,
      stopTypeId: json['stopTypeId'] as int?,
      stopTypeName: json['stopTypeName'] as String?,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Route from /api/v1/schedules response
class TrainRoute {
  final int scheduleId;
  final int orderId;
  final int? trainOrderId;
  final String? name;
  final String? carrierCode;
  final String? nationalNumber;
  final String? internationalArrivalNumber;
  final String? internationalDepartureNumber;
  final String? commercialCategorySymbol;
  final List<String> operatingDates;
  final List<StationOnRoute> stations;
  final List<Map<String, dynamic>> connections;
  final Map<String, dynamic> raw;

  TrainRoute({
    required this.scheduleId,
    required this.orderId,
    this.trainOrderId,
    this.name,
    this.carrierCode,
    this.nationalNumber,
    this.internationalArrivalNumber,
    this.internationalDepartureNumber,
    this.commercialCategorySymbol,
    required this.operatingDates,
    required this.stations,
    required this.connections,
    required this.raw,
  });

  factory TrainRoute.fromJson(Map<String, dynamic> json) {
    return TrainRoute(
      scheduleId: json['scheduleId'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      trainOrderId: json['trainOrderId'] as int?,
      name: json['name'] as String?,
      carrierCode: json['carrierCode'] as String?,
      nationalNumber: json['nationalNumber'] as String?,
      internationalArrivalNumber: json['internationalArrivalNumber'] as String?,
      internationalDepartureNumber:
          json['internationalDepartureNumber'] as String?,
      commercialCategorySymbol: json['commercialCategorySymbol'] as String?,
      operatingDates: (json['operatingDates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      stations: (json['stations'] as List<dynamic>?)
              ?.map((e) => StationOnRoute.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      connections: (json['connections'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Operation station from /api/v1/operations
class OperationStation {
  final int stationId;
  final int? plannedSequenceNumber;
  final int actualSequenceNumber;
  final String? plannedArrival;
  final String? plannedDeparture;
  final int? arrivalDelayMinutes;
  final int? departureDelayMinutes;
  final String? actualArrival;
  final String? actualDeparture;
  final bool isConfirmed;
  final bool isCancelled;
  final String? platform;
  final String? track;
  final Map<String, dynamic> raw;

  OperationStation({
    required this.stationId,
    this.plannedSequenceNumber,
    required this.actualSequenceNumber,
    this.plannedArrival,
    this.plannedDeparture,
    this.arrivalDelayMinutes,
    this.departureDelayMinutes,
    this.actualArrival,
    this.actualDeparture,
    required this.isConfirmed,
    required this.isCancelled,
    this.platform,
    this.track,
    required this.raw,
  });

  factory OperationStation.fromJson(Map<String, dynamic> json) {
    return OperationStation(
      stationId: json['stationId'] as int? ?? 0,
      plannedSequenceNumber: json['plannedSequenceNumber'] as int?,
      actualSequenceNumber: json['actualSequenceNumber'] as int? ?? 0,
      plannedArrival: json['plannedArrival'] as String?,
      plannedDeparture: json['plannedDeparture'] as String?,
      arrivalDelayMinutes: json['arrivalDelayMinutes'] as int?,
      departureDelayMinutes: json['departureDelayMinutes'] as int?,
      actualArrival: json['actualArrival'] as String?,
      actualDeparture: json['actualDeparture'] as String?,
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      isCancelled: json['isCancelled'] as bool? ?? false,
      platform: json['platform'] as String? ??
          json['arrivalPlatform'] as String? ??
          json['departurePlatform'] as String?,
      track: json['track'] as String? ??
          json['arrivalTrack'] as String? ??
          json['departureTrack'] as String?,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Train operation from /api/v1/operations
class TrainOperation {
  final int scheduleId;
  final int orderId;
  final int trainOrderId;
  final String operatingDate;
  final String? trainStatus;
  final List<OperationStation> stations;
  final Map<String, dynamic> raw;

  TrainOperation({
    required this.scheduleId,
    required this.orderId,
    required this.trainOrderId,
    required this.operatingDate,
    this.trainStatus,
    required this.stations,
    required this.raw,
  });

  factory TrainOperation.fromJson(Map<String, dynamic> json) {
    return TrainOperation(
      scheduleId: json['scheduleId'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      trainOrderId: json['trainOrderId'] as int? ?? 0,
      operatingDate: json['operatingDate'] as String? ?? '',
      trainStatus: json['trainStatus'] as String?,
      stations: (json['stations'] as List<dynamic>?)
              ?.map((e) => OperationStation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      raw: json,
    );
  }

  String get statusText {
    switch (trainStatus) {
      case 'S':
        return 'Jeszcze nie rozpoczął kursu';
      case 'P':
        return 'W trasie';
      case 'C':
        return 'Kurs zakończony';
      case 'X':
        return 'Odwołany';
      case 'Q':
        return 'Częściowo odwołany';
      default:
        return 'Status nieznany';
    }
  }

  Map<String, dynamic> toJson() => raw;
}

/// Enum for Train Position status
enum TrainStatusType {
  notStarted,
  inProgress,
  atStation,
  betweenStations,
  completed,
  cancelled,
  partialCancelled,
}

/// Real-time train position indicator on the route
class TrainPositionInfo {
  final TrainStatusType type;
  final String description;
  final int? currentStationId;
  final String? currentStationName;
  final int? nextStationId;
  final String? nextStationName;
  final int lastVisitedOrderNumber;

  TrainPositionInfo({
    required this.type,
    required this.description,
    this.currentStationId,
    this.currentStationName,
    this.nextStationId,
    this.nextStationName,
    this.lastVisitedOrderNumber = 0,
  });

  static TrainPositionInfo compute({
    required TrainOperation? operation,
    required List<StationOnRoute> routeStations,
    required Map<int, String> stationNames,
    DateTime? nowOverride,
  }) {
    if (operation == null) {
      return TrainPositionInfo(
        type: TrainStatusType.notStarted,
        description: 'Brak danych o bieżącym kursie',
      );
    }

    if (operation.trainStatus == 'X') {
      return TrainPositionInfo(
        type: TrainStatusType.cancelled,
        description: 'Pociąg odwołany',
      );
    }

    if (operation.trainStatus == 'Q') {
      return TrainPositionInfo(
        type: TrainStatusType.partialCancelled,
        description: 'Pociąg częściowo odwołany',
      );
    }

    if (operation.trainStatus == 'S') {
      return TrainPositionInfo(
        type: TrainStatusType.notStarted,
        description: 'Jeszcze nie rozpoczął kursu',
      );
    }

    if (operation.trainStatus == 'C') {
      return TrainPositionInfo(
        type: TrainStatusType.completed,
        description: 'Kurs zakończony',
        lastVisitedOrderNumber: routeStations.length,
      );
    }

    // Train is in progress ('P') or fallback
    final now = nowOverride ?? DateTime.now();

    StationOnRoute? lastReachedStation;
    OperationStation? lastReachedOp;
    StationOnRoute? nextStation;

    // Loop through the FULL planned route to ensure proper order
    for (int i = 0; i < routeStations.length; i++) {
      final plannedStation = routeStations[i];
      
      // Find matching operation station
      OperationStation? opSt;
      try {
        opSt = operation.stations.firstWhere(
            (s) => s.stationId == plannedStation.stationId);
      } catch (_) {}

      if (opSt != null) {
        final actualDepDt = app_date.parsePdpDateTime(opSt.actualDeparture);
        final actualArrDt = app_date.parsePdpDateTime(opSt.actualArrival);
        
        bool isReached = false;
        
        if (actualDepDt != null && actualDepDt.isBefore(now) || actualDepDt?.isAtSameMomentAs(now) == true) {
          isReached = true;
        } else if (actualArrDt != null && actualArrDt.isBefore(now) || actualArrDt?.isAtSameMomentAs(now) == true) {
          isReached = true;
        }

        if (isReached) {
          lastReachedStation = plannedStation;
          lastReachedOp = opSt;
        } else if (lastReachedStation != null && nextStation == null) {
          // The first station in the planned route that is NOT reached after lastReached
          nextStation = plannedStation;
        }
      } else {
        // No operation data for this planned station
        if (lastReachedStation != null && nextStation == null) {
          nextStation = plannedStation;
        }
      }
    }

    if (lastReachedStation != null && lastReachedOp != null) {
      final stName = stationNames[lastReachedStation.stationId] ?? 'stacji';
      final nextName = nextStation != null ? (stationNames[nextStation.stationId] ?? 'kolejnej stacji') : 'końca trasy';
      
      String timeStr = '';
      if (lastReachedOp.actualDeparture != null && app_date.parsePdpDateTime(lastReachedOp.actualDeparture) != null) {
        final t = app_date.parsePdpDateTime(lastReachedOp.actualDeparture)!;
        timeStr = ' (odjazd ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')})';
      } else if (lastReachedOp.actualArrival != null && app_date.parsePdpDateTime(lastReachedOp.actualArrival) != null) {
        final t = app_date.parsePdpDateTime(lastReachedOp.actualArrival)!;
        timeStr = ' (przyjazd ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')})';
      }

      return TrainPositionInfo(
        type: TrainStatusType.betweenStations,
        description: 'Ostatnia stacja: $stName$timeStr\nNastępna: $nextName',
        currentStationId: lastReachedStation.stationId,
        currentStationName: stName,
        nextStationId: nextStation?.stationId,
        nextStationName: nextStation != null ? stationNames[nextStation.stationId] : null,
        lastVisitedOrderNumber: lastReachedStation.orderNumber,
      );
    }

    return TrainPositionInfo(
      type: TrainStatusType.inProgress,
      description: 'W trasie',
    );
  }
}

/// Operation statistics from /api/v1/operations/statistics
class OperationStatistics {
  final String? generatedAt;
  final String? date;
  final int totalTrains;
  final int notStarted;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int partialCancelled;
  final Map<String, dynamic> raw;

  OperationStatistics({
    this.generatedAt,
    this.date,
    required this.totalTrains,
    required this.notStarted,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.partialCancelled,
    required this.raw,
  });

  factory OperationStatistics.fromJson(Map<String, dynamic> json) {
    return OperationStatistics(
      generatedAt: json['generatedAt'] as String?,
      date: json['date'] as String?,
      totalTrains: json['totalTrains'] as int? ?? 0,
      notStarted: json['notStarted'] as int? ?? 0,
      inProgress: json['inProgress'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
      partialCancelled: json['partialCancelled'] as int? ?? 0,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Disruption from /api/v1/disruptions
class Disruption {
  final int disruptionId;
  final String? disruptionTypeCode;
  final int? startStationId;
  final int? endStationId;
  final String? message;
  final List<Map<String, dynamic>> affectedRoutes;
  final Map<String, dynamic> raw;

  Disruption({
    required this.disruptionId,
    this.disruptionTypeCode,
    this.startStationId,
    this.endStationId,
    this.message,
    required this.affectedRoutes,
    required this.raw,
  });

  factory Disruption.fromJson(Map<String, dynamic> json) {
    return Disruption(
      disruptionId: (json['disruptionId'] as num?)?.toInt() ?? 0,
      disruptionTypeCode: json['disruptionTypeCode'] as String?,
      startStationId: json['startStationId'] as int?,
      endStationId: json['endStationId'] as int?,
      message: json['message'] as String?,
      affectedRoutes: (json['affectedRoutes'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Data version from /api/v1/data-version
class DataVersion {
  final String? dataVersion;
  final String? schedulesVersion;
  final String? operationsVersion;
  final String? timestamp;

  DataVersion({
    this.dataVersion,
    this.schedulesVersion,
    this.operationsVersion,
    this.timestamp,
  });

  factory DataVersion.fromJson(Map<String, dynamic> json) {
    return DataVersion(
      dataVersion: json['dataVersion'] as String?,
      schedulesVersion: json['schedulesVersion'] as String?,
      operationsVersion: json['operationsVersion'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// Station departure or arrival item for station board
class StationBoardItem {
  final String time; // HH:mm or TimeSpan
  final String trainNumber;
  final String trainCategory;
  final String carrier;
  final String direction; // Destination for departure, Origin for arrival
  final int? delayMinutes;
  final bool isCancelled;
  final String status;
  final int scheduleId;
  final int orderId;
  final String operatingDate;
  final String? platform;
  final String? track;
  final String? plannedTime;
  final String? actualTime;
  final Map<String, dynamic> raw;

  StationBoardItem({
    required this.time,
    required this.trainNumber,
    required this.trainCategory,
    required this.carrier,
    required this.direction,
    this.delayMinutes,
    this.isCancelled = false,
    this.status = '',
    required this.scheduleId,
    required this.orderId,
    required this.operatingDate,
    this.platform,
    this.track,
    this.plannedTime,
    this.actualTime,
    required this.raw,
  });
}

/// Search result for connection between two stations (direct or with transfer)
class ConnectionResult {
  final TrainRoute route;
  final StationOnRoute fromStop;
  final StationOnRoute toStop;
  final String fromStationName;
  final String toStationName;
  final String carrierName;
  final String commercialCategory;
  final TrainOperation? operation;
  final bool isDirect;
  final int transfersCount;
  final ConnectionResult? secondLeg; // For 1-transfer connections
  final String operatingDate;

  ConnectionResult({
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.fromStationName,
    required this.toStationName,
    required this.carrierName,
    required this.commercialCategory,
    this.operation,
    this.isDirect = true,
    this.transfersCount = 0,
    this.secondLeg,
    this.operatingDate = '',
  });

  String get departureTime => fromStop.departureTime ?? '';
  String get arrivalTime =>
      (secondLeg != null
          ? secondLeg!.toStop.arrivalTime
          : toStop.arrivalTime) ??
      '';

  String get trainNumber {
    return fromStop.departureTrainNumber ??
        route.nationalNumber ??
        route.name ??
        '';
  }

  String get trainName => route.name ?? '';
  String get trainCategory => commercialCategory;
  String get carrier => carrierName;

  String get relationStart {
    if (route.stations.isNotEmpty) {
      return route.stations.first.departureTrainNumber ?? '';
    }
    return fromStationName;
  }

  String get relationEnd {
    if (route.stations.isNotEmpty) {
      return route.stations.last.arrivalTrainNumber ?? '';
    }
    return toStationName;
  }

  String get duration {
    return app_date.calculateTravelTime(departureTime, arrivalTime);
  }

  int get departureDelay {
    if (operation != null) {
      for (final st in operation!.stations) {
        if (st.stationId == fromStop.stationId) {
          return st.departureDelayMinutes ?? 0;
        }
      }
    }
    return 0;
  }

  int get arrivalDelay {
    if (operation != null) {
      for (final st in operation!.stations) {
        if (st.stationId == toStop.stationId) {
          return st.arrivalDelayMinutes ?? 0;
        }
      }
    }
    return 0;
  }

  int get delay =>
      departureDelay > arrivalDelay ? departureDelay : arrivalDelay;

  bool get isCancelled {
    if (operation != null) {
      if (operation!.trainStatus == 'X') return true;
      for (final st in operation!.stations) {
        if (st.stationId == fromStop.stationId ||
            st.stationId == toStop.stationId) {
          if (st.isCancelled) return true;
        }
      }
    }
    return false;
  }

  String? get trainStatus => operation?.trainStatus;

  String get trainStatusText {
    if (isCancelled) return 'Odwołany';
    if (operation != null) return operation!.statusText;
    return 'Planowo';
  }

  int get fromStationId => fromStop.stationId;
  int get toStationId => toStop.stationId;

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': route.scheduleId,
      'orderId': route.orderId,
      'trainOrderId': route.trainOrderId,
      'name': route.name,
      'carrierCode': route.carrierCode,
      'carrierName': carrierName,
      'commercialCategory': commercialCategory,
      'nationalNumber': route.nationalNumber,
      'fromStation': fromStationName,
      'fromStationId': fromStationId,
      'departureTime': departureTime,
      'toStation': toStationName,
      'toStationId': toStationId,
      'arrivalTime': arrivalTime,
      'duration': duration,
      'isDirect': isDirect,
      'transfersCount': transfersCount,
      'departureDelay': departureDelay,
      'arrivalDelay': arrivalDelay,
      'isCancelled': isCancelled,
      'status': trainStatusText,
      'rawRoute': route.raw,
      if (operation != null) 'rawOperation': operation!.raw,
    };
  }
}

/// Model for Favorite Station
class FavoriteStation {
  final int id;
  final String name;
  final DateTime savedAt;

  FavoriteStation({
    required this.id,
    required this.name,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  factory FavoriteStation.fromJson(Map<String, dynamic> json) {
    return FavoriteStation(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'savedAt': savedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteStation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for Favorite Route
class FavoriteRoute {
  final int fromStationId;
  final String fromStationName;
  final int toStationId;
  final String toStationName;
  final DateTime savedAt;

  FavoriteRoute({
    required this.fromStationId,
    required this.fromStationName,
    required this.toStationId,
    required this.toStationName,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      fromStationId: json['fromStationId'] as int? ?? 0,
      fromStationName: json['fromStationName'] as String? ?? '',
      toStationId: json['toStationId'] as int? ?? 0,
      toStationName: json['toStationName'] as String? ?? '',
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromStationId': fromStationId,
        'fromStationName': fromStationName,
        'toStationId': toStationId,
        'toStationName': toStationName,
        'savedAt': savedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteRoute &&
          runtimeType == other.runtimeType &&
          fromStationId == other.fromStationId &&
          toStationId == other.toStationId;

  @override
  int get hashCode => Object.hash(fromStationId, toStationId);
}

/// Train search result by train number
class TrainSearchResult {
  final int scheduleId;
  final int orderId;
  final String nationalNumber;
  final String? trainName;
  final String? carrierCode;
  final String? carrierName;
  final String? category;
  final String fromStationName;
  final String toStationName;
  final String departureTime;
  final String arrivalTime;
  final List<String> operatingDates;
  final String operatingDate;
  final TrainRoute route;
  final TrainOperation? operation;

  TrainSearchResult({
    required this.scheduleId,
    required this.orderId,
    required this.nationalNumber,
    this.trainName,
    this.carrierCode,
    this.carrierName,
    this.category,
    required this.fromStationName,
    required this.toStationName,
    required this.departureTime,
    required this.arrivalTime,
    required this.operatingDates,
    required this.operatingDate,
    required this.route,
    this.operation,
  });
}
