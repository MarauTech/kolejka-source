// Polish railway formatting utilities for Kolejka

/// Converts an integer (1-3999) to Roman numeral string.
String toRoman(int number) {
  if (number <= 0 || number > 3999) return number.toString();

  const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const numerals = [
    'M',
    'CM',
    'D',
    'CD',
    'C',
    'XC',
    'L',
    'XL',
    'X',
    'IX',
    'V',
    'IV',
    'I'
  ];

  var num = number;
  final buffer = StringBuffer();
  for (int i = 0; i < values.length; i++) {
    while (num >= values[i]) {
      buffer.write(numerals[i]);
      num -= values[i];
    }
  }
  return buffer.toString();
}

/// Converts a platform string to Roman numeral representation.
///
/// Examples:
///   '1'   -> 'I'
///   '2'   -> 'II'
///   '3'   -> 'III'
///   '4'   -> 'IV'
///   '5'   -> 'V'
///   '6'   -> 'VI'
///   '7'   -> 'VII'
///   '8'   -> 'VIII'
///   '9'   -> 'IX'
///   '10'  -> 'X'
///   '1a'  -> 'Ia'
///   '2B'  -> 'IIB'
///   'IV'  -> 'IV'
///   null  -> ''
String formatPlatform(String? platform) {
  if (platform == null) return '';
  final p = platform.trim();
  if (p.isEmpty || p == '-') return '';

  // Check if it is already roman numerals (only I, V, X, L, C, D, M, case-insensitive)
  final isAlreadyRoman = RegExp(r'^[IVXLCDMivxlcdm]+$').hasMatch(p);
  if (isAlreadyRoman) {
    return p.toUpperCase();
  }

  // Extract leading digits and trailing suffix (e.g. '1a' -> '1' and 'a')
  final match = RegExp(r'^(\d+)(.*)$').firstMatch(p);
  if (match != null) {
    final numStr = match.group(1);
    final suffix = match.group(2) ?? '';
    final numVal = int.tryParse(numStr ?? '');
    if (numVal != null && numVal > 0) {
      return '${toRoman(numVal)}$suffix';
    }
  }

  return p;
}

/// Formats platform and track into standard railway format.
///
/// Examples:
///   ('4', '3') -> 'Per. IV / Tor 3'
///   ('1', null) -> 'Per. I'
///   (null, '5') -> 'Tor 5'
///   (null, null) -> null
String? formatPlatformTrack(String? platform, String? track,
    {bool compact = false}) {
  final p = formatPlatform(platform);
  final t = track?.trim();

  final hasP = p.isNotEmpty;
  final hasT = t != null && t.isNotEmpty && t != '-';

  if (hasP && hasT) {
    return compact ? 'Per. $p/$t' : 'Per. $p / Tor $t';
  } else if (hasP) {
    return 'Per. $p';
  } else if (hasT) {
    return 'Tor $t';
  }
  return null;
}
