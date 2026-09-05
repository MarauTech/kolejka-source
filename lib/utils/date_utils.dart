/// Parse a duration/TimeSpan string like "08:32:00" or "1.08:32:00" to hours and minutes
String formatTimeSpan(String? timeSpan) {
  if (timeSpan == null || timeSpan.isEmpty) return '--:--';

  // Handle formats: "HH:mm:ss", "D.HH:mm:ss"
  try {
    final parts = timeSpan.split(':');
    if (parts.length >= 2) {
      String hourPart = parts[0];
      // Handle day offset: "1.08" means day 1, hour 8
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

/// Parse ISO 8601 datetime string and format as HH:mm
String formatDateTime(String? dateTimeStr) {
  if (dateTimeStr == null || dateTimeStr.isEmpty) return '--:--';
  try {
    final dt = DateTime.parse(dateTimeStr).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '--:--';
  }
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

/// Format date as yyyy-MM-dd for API requests
String formatDateForApi(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Format duration string
String formatDuration(String? duration) {
  if (duration == null || duration.isEmpty) return '';
  return duration;
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

/// Format delay in minutes with color indication text
String formatDelay(int? delayMinutes) {
  if (delayMinutes == null || delayMinutes == 0) return 'Planowo';
  if (delayMinutes > 0) return '+$delayMinutes min';
  return '$delayMinutes min';
}
