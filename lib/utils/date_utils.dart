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
  if (delayMinutes == null || delayMinutes == 0) return 'Planowo';
  if (delayMinutes > 0) return '+$delayMinutes min';
  return '$delayMinutes min';
}
