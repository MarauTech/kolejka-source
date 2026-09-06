import 'package:flutter/material.dart';

/// Returns the badge background color for a given train commercial category symbol.
///
/// Mapping:
///   Os, R, RP, PR, KW, LKA (REGIO, RE, POLREGIO) = red
///   IR, KM                                       = green
///   TLK, IC, EC, EN                              = orange
///   EIC                                          = light blue
///   EIP                                          = dark blue (navy)
///   SKM, KD, KML                                 = yellow
///   KS                                           = blue
///   other / unknown                              = neutral grey
Color categoryColor(String? symbol, {bool isDark = false}) {
  final cat = (symbol ?? '').toUpperCase().trim();

  // Red group: Os, R, RP, PR, KW, LKA / REGIO / POLREGIO / RE
  if (cat == 'OS' ||
      cat == 'R' ||
      cat == 'REGIO' ||
      cat == 'RP' ||
      cat == 'PR' ||
      cat == 'KW' ||
      cat == 'ŁKA' ||
      cat == 'LKA' ||
      cat == 'POLREGIO' ||
      cat == 'RE') {
    return isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
  }

  // Green group: IR, KM
  if (cat == 'IR' || cat == 'KM') {
    return isDark ? const Color(0xFF43A047) : const Color(0xFF2E7D32);
  }

  // Orange group: TLK, IC, EC, EN
  if (cat == 'TLK' || cat == 'IC' || cat == 'EC' || cat == 'EN') {
    return isDark ? const Color(0xFFFB8C00) : const Color(0xFFE65100);
  }

  // Light blue group: EIC
  if (cat == 'EIC') {
    return isDark ? const Color(0xFF81D4FA) : const Color(0xFF81C9EE);
  }

  // Dark blue (navy) group: EIP
  if (cat == 'EIP') {
    return isDark ? const Color(0xFF3949AB) : const Color(0xFF1A237E);
  }

  // Yellow group: SKM, KD, KMŁ
  if (cat == 'SKM' || cat == 'KD' || cat == 'KMŁ' || cat == 'KML') {
    return isDark ? const Color(0xFFFBC02D) : const Color(0xFFF4C542);
  }

  // Blue group: KŚ
  if (cat == 'KŚ' || cat == 'KS') {
    return isDark ? const Color(0xFF1E88E5) : const Color(0xFF1565C0);
  }

  // Unknown / other: neutral grey
  return isDark ? const Color(0xFF78909C) : const Color(0xFF546E7A);
}

/// Returns a text color that is readable on top of [categoryColor].
/// For yellow categories (SKM, KD, KML), returns dark text for high contrast.
Color categoryTextColor(String? symbol, {bool isDark = false}) {
  final luminance = categoryColor(symbol, isDark: isDark).computeLuminance();
  return (luminance + 0.05) / 0.05 > 1.05 / (luminance + 0.05)
      ? Colors.black
      : Colors.white;
}
