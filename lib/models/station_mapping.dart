import 'models.dart';

/// Matches occurrences, never positions in independently filtered API lists.
OperationStation? operationForStop(StationOnRoute stop,
    List<StationOnRoute> route, List<OperationStation> operations) {
  final candidates = operations.where((s) => s.stationId == stop.stationId);
  final exact = candidates.where((s) =>
      stop.orderNumber > 0 && s.plannedSequenceNumber == stop.orderNumber);
  if (exact.length == 1) return exact.single;
  if (exact.isNotEmpty) return null;
  // A station ID alone is safe only when it identifies a unique occurrence
  // on both sides. Actual sequence is a different ordering, not a route index.
  if (route.where((s) => s.stationId == stop.stationId).length == 1 &&
      candidates.length == 1 &&
      candidates.single.plannedSequenceNumber == null) {
    return candidates.single;
  }
  return null;
}
