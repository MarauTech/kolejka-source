import 'models.dart';

/// Operations belong to one train occurrence on one operating day.
bool operationMatchesRoute(
    TrainOperation operation, TrainRoute route, String date) {
  if (operation.scheduleId != route.scheduleId ||
      operation.operatingDate != date) {
    return false;
  }
  final trainId = route.trainOrderId;
  if (trainId != null && trainId > 0) {
    return operation.trainOrderId == trainId ||
        (operation.trainOrderId == 0 && operation.orderId == trainId);
  }
  return operation.orderId == route.orderId ||
      operation.trainOrderId == route.orderId;
}

/// A notice is derived only from a change in published station-level identity.
String? routeStopNotice(StationOnRoute stop, StationOnRoute? previous,
    {String? destination}) {
  final beforeNumber =
      (stop.arrivalTrainNumber ?? previous?.departureTrainNumber ?? '').trim();
  final afterNumber = (stop.departureTrainNumber ?? '').trim();
  final beforeCategory = (stop.arrivalCommercialCategory ??
          previous?.departureCommercialCategory ??
          '')
      .trim();
  final afterCategory = (stop.departureCommercialCategory ?? '').trim();
  final changedNumber = beforeNumber.isNotEmpty &&
      afterNumber.isNotEmpty &&
      beforeNumber != afterNumber;
  final changedCategory = beforeCategory.isNotEmpty &&
      afterCategory.isNotEmpty &&
      beforeCategory != afterCategory;
  if (afterNumber.isEmpty || (!changedNumber && !changedCategory)) return null;
  final designation =
      [if (afterCategory.isNotEmpty) afterCategory, afterNumber].join(' ');
  final direction = destination == null || destination.trim().isEmpty
      ? ''
      : ' w kierunku $destination';
  return 'Kursuje z tego miejsca jako $designation$direction';
}
