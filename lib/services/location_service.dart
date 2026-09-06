import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  error,
}

class NearestStationResult {
  final Station station;
  final double distanceKm;
  final double userLatitude;
  final double userLongitude;

  NearestStationResult({
    required this.station,
    required this.distanceKm,
    required this.userLatitude,
    required this.userLongitude,
  });
}

class LocationService {
  final Dio _dio;

  LocationService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'User-Agent': 'KolejkaApp/1.0 (PKP PLK Train Schedule)',
                'Accept': 'application/json',
              },
            ));

  /// Check current permission status
  Future<LocationPermissionStatus> checkPermission() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      final permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionStatus.granted;
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.permanentlyDenied;
        case LocationPermission.unableToDetermine:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      debugPrint('[LocationService] checkPermission error: $e');
      return LocationPermissionStatus.error;
    }
  }

  /// Request permission from user
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionStatus.granted;
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.permanentlyDenied;
        case LocationPermission.unableToDetermine:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      return LocationPermissionStatus.error;
    }
  }

  /// Get current position with timeout
  Future<Position?> getCurrentPosition() async {
    try {
      final status = await checkPermission();
      if (status != LocationPermissionStatus.granted) return null;

      // Try last known position first as quick cache
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        final age = DateTime.now().difference(position.timestamp);
        if (age.inMinutes < 10) {
          return position;
        }
      }

      // Query current position with 8s timeout
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return position;
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e');
      // If error, try returning last known position even if older
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Calculate Haversine distance between two coordinates in kilometers
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Normalize station name for reliable comparison
  static String normalizeStationName(String name) {
    var s = name.toLowerCase().trim();

    // Remove common prefixes / words
    s = s
        .replaceAll('stacja kolejowa', '')
        .replaceAll('stacja', '')
        .replaceAll('przystanek kolejowy', '')
        .replaceAll('przystanek', '')
        .replaceAll('pkp', '')
        .replaceAll('plk', '')
        .replaceAll('wkd', '')
        .replaceAll('skm', '')
        .replaceAll(RegExp(r'[^\w\sąćęłńóśźż]'), ' ');

    // Normalize Polish diacritics
    s = s
        .replaceAll('ą', 'a')
        .replaceAll('ć', 'c')
        .replaceAll('ę', 'e')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ś', 's')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z');

    // Remove extra spaces
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Query OSM Overpass mirrors or Nominatim for railway stations near given coordinates
  Future<List<Map<String, dynamic>>> queryOsmStations(
    double lat,
    double lon, {
    double radiusKm = 15.0,
  }) async {
    final radiusMeters = (radiusKm * 1000).toInt();

    final mirrors = [
      'https://overpass-api.de/api/interpreter',
      'https://lz4.overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];

    final query = '''
[out:json][timeout:6];
(
  node["railway"~"station|halt"](around:$radiusMeters,$lat,$lon);
  way["railway"~"station|halt"](around:$radiusMeters,$lat,$lon);
);
out center tags;
''';

    for (final mirror in mirrors) {
      try {
        final response = await _dio.post(
          mirror,
          data: 'data=${Uri.encodeComponent(query)}',
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.json,
          ),
        );

        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic>) {
          final elements = response.data['elements'] as List<dynamic>? ?? [];
          final results = <Map<String, dynamic>>[];

          for (final elem in elements) {
            final tags = elem['tags'] as Map<String, dynamic>?;
            if (tags == null) continue;

            final name = tags['name'] as String? ?? tags['name:pl'] as String?;
            if (name == null || name.isEmpty) continue;

            double? eLat = (elem['lat'] as num?)?.toDouble();
            double? eLon = (elem['lon'] as num?)?.toDouble();

            if (eLat == null && elem['center'] != null) {
              eLat = (elem['center']['lat'] as num?)?.toDouble();
              eLon = (elem['center']['lon'] as num?)?.toDouble();
            }

            if (eLat != null && eLon != null) {
              final dist = haversineDistance(lat, lon, eLat, eLon);
              results.add({
                'name': name,
                'lat': eLat,
                'lon': eLon,
                'distance': dist,
              });
            }
          }

          if (results.isNotEmpty) {
            results.sort((a, b) =>
                (a['distance'] as double).compareTo(b['distance'] as double));
            return results;
          }
        }
      } catch (e) {
        debugPrint('[LocationService] Overpass mirror $mirror failed: $e');
      }
    }

    // Fallback: Nominatim reverse geocode search for railway near point
    try {
      final delta = radiusKm / 111.0;
      final viewbox =
          '${lon - delta},${lat + delta},${lon + delta},${lat - delta}';
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': 'stacja kolejowa',
          'format': 'json',
          'viewbox': viewbox,
          'bounded': '1',
          'limit': '10',
          'accept-language': 'pl',
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List<dynamic>;
        final results = <Map<String, dynamic>>[];

        for (final item in list) {
          final displayName = item['display_name'] as String? ?? '';
          final parts = displayName.split(',');
          final name = parts.isNotEmpty ? parts[0].trim() : displayName;
          final nLat = double.tryParse(item['lat']?.toString() ?? '');
          final nLon = double.tryParse(item['lon']?.toString() ?? '');

          if (nLat != null && nLon != null && name.isNotEmpty) {
            final dist = haversineDistance(lat, lon, nLat, nLon);
            results.add({
              'name': name,
              'lat': nLat,
              'lon': nLon,
              'distance': dist,
            });
          }
        }

        if (results.isNotEmpty) {
          results.sort((a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double));
          return results;
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Nominatim fallback failed: $e');
    }

    return [];
  }

  /// Match OSM station names against PLK stations dictionary
  Station? matchPlkStation(String osmName, List<Station> plkStations) {
    if (plkStations.isEmpty) return null;

    final normOsm = normalizeStationName(osmName);
    if (normOsm.isEmpty) return null;

    // 1. Exact match (case-insensitive)
    for (final s in plkStations) {
      if (s.name.trim().toLowerCase() == osmName.trim().toLowerCase()) {
        return s;
      }
    }

    // 2. Exact normalized match (without Polish diacritics and prefixes)
    for (final s in plkStations) {
      if (normalizeStationName(s.name) == normOsm) {
        return s;
      }
    }

    // 3. Substring / contains match
    for (final s in plkStations) {
      final normPlk = normalizeStationName(s.name);
      if (normPlk.isNotEmpty &&
          (normPlk == normOsm ||
              normPlk.contains(normOsm) ||
              normOsm.contains(normPlk))) {
        return s;
      }
    }

    // 4. Word-by-word token overlap
    final osmTokens = normOsm.split(' ').where((w) => w.length > 2).toSet();
    if (osmTokens.isNotEmpty) {
      Station? bestMatch;
      int bestOverlap = 0;

      for (final s in plkStations) {
        final plkTokens = normalizeStationName(s.name)
            .split(' ')
            .where((w) => w.length > 2)
            .toSet();
        final overlap = osmTokens.intersection(plkTokens).length;
        if (overlap > bestOverlap) {
          bestOverlap = overlap;
          bestMatch = s;
        }
      }

      if (bestOverlap >= (osmTokens.length > 1 ? 2 : 1)) {
        return bestMatch;
      }
    }

    return null;
  }

  /// Find nearest station for current GPS position and PLK dictionary
  Future<NearestStationResult?> findNearestStation(
      List<Station> plkStations) async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;

    final osmStations = await queryOsmStations(pos.latitude, pos.longitude);
    if (osmStations.isEmpty) return null;

    for (final osm in osmStations) {
      final name = osm['name'] as String;
      final dist = osm['distance'] as double;
      final matched = matchPlkStation(name, plkStations);
      if (matched != null) {
        return NearestStationResult(
          station: matched,
          distanceKm: dist,
          userLatitude: pos.latitude,
          userLongitude: pos.longitude,
        );
      }
    }

    return null;
  }
}
