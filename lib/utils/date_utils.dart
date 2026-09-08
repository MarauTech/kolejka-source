// Polish date and time utilities for Kolejka

/// Parse a duration/TimeSpan string like "08:32:00" or "1.08:32:00" to hours and minutes
String formatTimeSpan(String? timeSpan) {
  if (timeSpan == null || timeSpan.isEmpty) return '--:--';

  try {
    final parts = timeSpan.split(':');
    if (parts.length >= 2) {
      String hourPart = parts[0];
      if (hourPart.contains('.')) {
        final dayHour = hourPart.split('.');
        final days = int.parse(dayHour[0]);
        final hours = int.parse(dayHour[1]);
        final totalHours = days * 24 + hours;
        hourPart = totalHours.toString().padLeft(2, '0');
      }
      final hour = int.parse(hourPart) % 24;
      final minute = int.parse(parts[1]);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
  } catch (_) {}
  return '--:--';
}

/// Helper to parse PDP timestamps consistently without incorrect timezone shifts
DateTime? parsePdpDateTime(String? dateTimeStr) {
  if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
  try {
    // PDP returns times like "2026-09-06T16:51:00" (no 'Z' and no offset).
    // DateTime.parse will treat this as local time by default.
    // That means it's already in the "same" timezone if device is in Poland.
    // Just parse it and avoid .toLocal() which might shift if it was UTC.
    var parsed = DateTime.parse(dateTimeStr);
    if (parsed.isUtc) {
      // If it accidentally got parsed as UTC (e.g. string had Z), convert to local
      parsed = parsed.toLocal();
    }
    return parsed;
  } catch (_) {
    return null;
  }
}

/// Parse ISO 8601 datetime string and format as HH:mm
String formatDateTime(String? dateTimeStr) {
  final dt = parsePdpDateTime(dateTimeStr);
  if (dt == null) return '--:--';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Parse ISO 8601 datetime string and format as dd.MM.yyyy
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '--.--.----';
  try {
    final dt = DateTime.parse(dateStr).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  } catch (_) {
    return dateStr;
  }
}

/// Format DateTime as dd.MM.yyyy for display
String formatDateDisplay(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

/// Format hour and minute as HH:mm for display
String formatTimeDisplay(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Format date as yyyy-MM-dd for API requests
String formatDateForApi(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Quick date helpers
DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime tomorrow() {
  final t = today();
  return t.add(const Duration(days: 1));
}

/// Calculate travel time between two TimeSpan strings
String calculateTravelTime(String? departureTime, String? arrivalTime) {
  if (departureTime == null || arrivalTime == null) return '';

  try {
    final depMinutes = _timeSpanToMinutes(departureTime);
    final arrMinutes = _timeSpanToMinutes(arrivalTime);
    if (depMinutes == null || arrMinutes == null) return '';

    var diff = arrMinutes - depMinutes;
    if (diff < 0) diff += 24 * 60; // Handle day overflow

    final hours = diff ~/ 60;
    final minutes = diff % 60;

    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  } catch (_) {
    return '';
  }
}

/// Calculate travel time between two DateTime strings
String calculateTravelTimeFromDateTime(String? departure, String? arrival) {
  if (departure == null || arrival == null) return '';
  try {
    final dep = DateTime.parse(departure);
    final arr = DateTime.parse(arrival);
    final diff = arr.difference(dep);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  } catch (_) {
    return '';
  }
}

String formatDuration(Duration duration) {
  if (duration.isNegative) return '';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours > 0 ? '$hours h $minutes min' : '$minutes min';
}

/// Duration based on the same effective times that are displayed in results.
String effectiveTravelTime({
  required String plannedDeparture,
  required String plannedArrival,
  String? actualDeparture,
  String? actualArrival,
  required int departureDelay,
  required int arrivalDelay,
  required String operatingDate,
  int? departureDay,
  int? arrivalDay,
}) {
  DateTime? effective(String planned, String? actual, int delay, int? day) {
    final observed = parsePdpDateTime(actual);
    if (observed != null) return observed;
    final scheduled = scheduleDateTime(planned, operatingDate, day: day);
    return scheduled?.add(Duration(minutes: delay));
  }

  final departure = effective(
      plannedDeparture, actualDeparture, departureDelay, departureDay);
  var arrival =
      effective(plannedArrival, actualArrival, arrivalDelay, arrivalDay);
  if (departure == null || arrival == null) return '';
  if (arrival.isBefore(departure) &&
      !plannedDeparture.contains('T') &&
      !plannedArrival.contains('T')) {
    arrival = arrival.add(const Duration(days: 1));
  }
  return formatDuration(arrival.difference(departure));
}

int? _timeSpanToMinutes(String timeSpan) {
  try {
    final parts = timeSpan.split(':');
    if (parts.length >= 2) {
      String hourPart = parts[0];
      int dayOffset = 0;
      if (hourPart.contains('.')) {
        final dayHour = hourPart.split('.');
        dayOffset = int.parse(dayHour[0]);
        hourPart = dayHour[1];
      }
      final hours = int.parse(hourPart) + dayOffset * 24;
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    }
  } catch (_) {}
  return null;
}

/// Format delay in minutes with text description (No emoji)
String formatDelay(int? delayMinutes) {
  if (delayMinutes == null) return 'Wg rozkładu';
  if (delayMinutes == 0) return 'Planowo';
  if (delayMinutes > 0) return '+$delayMinutes min';
  return '$delayMinutes min';
}

/// Safely format any time string (HH:mm, HH:mm:ss, ISO8601, TimeSpan) to HH:mm without RangeError.
String formatTimeSafe(String? timeStr) {
  if (timeStr == null || timeStr.trim().isEmpty) return '--:--';
  final s = timeStr.trim();

  // If it is an ISO datetime string like "2026-09-06T12:30:00"
  if (s.contains('T')) {
    final dt = parsePdpDateTime(s);
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  // Otherwise format as TimeSpan
  return formatTimeSpan(s);
}

/// Schedule TimeSpan is relative to the operating day; operations use ISO dates.
DateTime? scheduleDateTime(String? value, String operatingDate, {int? day}) {
  if (value == null || value.isEmpty) return null;
  if (value.contains('T')) {
    final timestamp = parsePdpDateTime(value);
    final operatingDay = DateTime.tryParse(operatingDate);
    // Some operation responses stamp every planned stop with the service's
    // start date. An explicit route day fixes that date after midnight. Keep
    // already dated later stops intact, and never adjust actual timestamps.
    if (timestamp != null &&
        operatingDay != null &&
        day != null &&
        day > 0 &&
        timestamp.year == operatingDay.year &&
        timestamp.month == operatingDay.month &&
        timestamp.day == operatingDay.day) {
      return DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day + day,
          timestamp.hour,
          timestamp.minute,
          timestamp.second,
          timestamp.millisecond,
          timestamp.microsecond);
    }
    return timestamp;
  }
  final date = DateTime.tryParse(operatingDate);
  final minutes = _timeSpanToMinutes(value);
  if (date == null || minutes == null) return null;
  return DateTime(date.year, date.month, date.day).add(
      Duration(days: value.contains('.') ? 0 : (day ?? 0), minutes: minutes));
}

String delayedTime(String? planned, String? actual, int delay) {
  if (actual != null && formatTimeSafe(actual) != '--:--') {
    return formatTimeSafe(actual);
  }
  final formatted = formatTimeSafe(planned);
  if (formatted == '--:--' || delay == 0) return formatted;
  final parts = formatted.split(':');
  final time = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]))
      .add(Duration(minutes: delay));
  return formatTimeDisplay(time.hour, time.minute);
}

/// Single-train responses can omit delay fields while providing actual times.
int timeDelay(String? planned, String? actual, int? reported,
    {required String operatingDate, int? day}) {
  if (reported != null) return reported;
  final expected = scheduleDateTime(planned, operatingDate, day: day);
  final observed = parsePdpDateTime(actual);
  if (expected == null || observed == null) return 0;
  return observed.difference(expected).inMinutes;
}
