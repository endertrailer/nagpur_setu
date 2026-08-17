import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';
import '../models/complaint.dart';

class CivicCategory {
  final String id;
  final String icon;
  final String description;

  const CivicCategory({
    required this.id,
    required this.icon,
    required this.description,
  });
}

const List<CivicCategory> kCivicCategories = [
  CivicCategory(
    id: 'Pothole',
    icon: '🕳️',
    description: 'Road damage, craters, broken asphalt, sunken utility trenches',
  ),
  CivicCategory(
    id: 'Garbage',
    icon: '🗑️',
    description: 'Illegal waste dumps, overflowing municipal bins, open litter',
  ),
  CivicCategory(
    id: 'Water Leak',
    icon: '💧',
    description: 'Burst pipelines, sewage overflows, street waterlogging',
  ),
  CivicCategory(
    id: 'Streetlight',
    icon: '💡',
    description: 'Non-functional lampposts, flickering lights, damaged electrical poles',
  ),
  CivicCategory(
    id: 'Other',
    icon: '⚠️',
    description: 'Broken footpaths, fallen trees, hazardous open drains',
  ),
];

class NagpurLocation {
  final String name;
  final double lat;
  final double lng;

  const NagpurLocation({required this.name, required this.lat, required this.lng});
}

const List<NagpurLocation> kNagpurLocations = [
  NagpurLocation(name: 'Zero Mile Stone, Civil Lines', lat: 21.1458, lng: 79.0882),
  NagpurLocation(name: 'Sitabuldi Variety Square', lat: 21.1466, lng: 79.0822),
  NagpurLocation(name: 'Dharampeth Coffee House Square, WHC Rd', lat: 21.1432, lng: 79.0620),
  NagpurLocation(name: 'Ramdaspeth Central Bazaar Road', lat: 21.1345, lng: 79.0728),
  NagpurLocation(name: 'Sadar Mount Road / Residency Road', lat: 21.1620, lng: 79.0830),
  NagpurLocation(name: 'Laxmi Nagar Square / VNIT Gate', lat: 21.1210, lng: 79.0650),
  NagpurLocation(name: 'Wardhaman Nagar Central Avenue', lat: 21.1480, lng: 79.1250),
  NagpurLocation(name: 'Mahal Gandhi Gate / Tilak Statue', lat: 21.1420, lng: 79.1020),
  NagpurLocation(name: 'Civil Lines High Court / VCA Stadium', lat: 21.1550, lng: 79.0690),
  NagpurLocation(name: 'Medical Square / GMC Hospital', lat: 21.1180, lng: 79.0980),
  NagpurLocation(name: 'Mankapur Sports Complex / Ring Road', lat: 21.1780, lng: 79.0750),
  NagpurLocation(name: 'Trimurti Nagar Ring Road', lat: 21.1120, lng: 79.0480),
  NagpurLocation(name: 'Pratap Nagar Square', lat: 21.1185, lng: 79.0555),
  NagpurLocation(name: 'Manewada Ring Road Square', lat: 21.1010, lng: 79.0920),
  NagpurLocation(name: 'Khamla Market / Deo Nagar', lat: 21.1140, lng: 79.0680),
  NagpurLocation(name: 'IT Park / Gayatri Nagar, Parsodi', lat: 21.1245, lng: 79.0510),
  NagpurLocation(name: 'Reshimbagh Ground', lat: 21.1310, lng: 79.1080),
  NagpurLocation(name: 'Nandanvan Square', lat: 21.1380, lng: 79.1310),
  NagpurLocation(name: 'Jaripatka Main Road', lat: 21.1850, lng: 79.0920),
  NagpurLocation(name: 'Futala Lake Road / Telangkhedi', lat: 21.1530, lng: 79.0440),
  NagpurLocation(name: 'Ambazari Lake Area', lat: 21.1315, lng: 79.0410),
  NagpurLocation(name: 'Seminary Hills', lat: 21.1680, lng: 79.0550),
  NagpurLocation(name: 'Ganeshpeth Bus Stand / Cotton Market', lat: 21.1410, lng: 79.0930),
];

class GeoUtils {
  static const double earthRadiusMeters = 6371000.0;

  // Strict Nagpur Bounding Box
  static const double minLat = 21.0400;
  static const double maxLat = 21.2600;
  static const double minLng = 78.9800;
  static const double maxLng = 79.2200;

  static const LatLng nagpurCenter = LatLng(21.1458, 79.0882);

  /// Check if coordinates are strictly within Nagpur municipal limits
  static bool isInsideNagpur(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Search Nagpur landmarks
  static List<NagpurLocation> searchLocations(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return kNagpurLocations.where((loc) => loc.name.toLowerCase().contains(q)).toList();
  }

  /// Haversine Great-Circle distance formula returning distance in meters
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Hash phone number using SHA-256
  static String hashPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final bytes = utf8.encode(clean);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Find duplicate complaint within threshold meters (default: 50m)
  static Map<String, dynamic> findDuplicateComplaint(
    double newLat,
    double newLng,
    String newCategory,
    List<Complaint> existingComplaints, {
    double thresholdMeters = 50.0,
  }) {
    for (final c in existingComplaints) {
      if (c.status != ComplaintStatus.resolved &&
          c.category.toLowerCase() == newCategory.toLowerCase()) {
        final dist = haversineDistance(newLat, newLng, c.lat, c.lng);
        if (dist <= thresholdMeters) {
          return {
            'duplicate': c,
            'distanceMeters': dist,
          };
        }
      }
    }
    return {
      'duplicate': null,
      'distanceMeters': 0.0,
    };
  }

  /// Check 7-day rate-limiting for the same phone hash within 50 meters
  static Map<String, dynamic> checkRateLimit(
    String phoneHash,
    double newLat,
    double newLng,
    List<Complaint> complaints, {
    int daysWindow = 7,
    double radiusMeters = 50.0,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: daysWindow));

    for (final c in complaints) {
      if (c.reporterPhoneHashes.contains(phoneHash)) {
        final dist = haversineDistance(newLat, newLng, c.lat, c.lng);
        if (dist <= radiusMeters && c.createdAt.isAfter(cutoff)) {
          final diffDays = now.difference(c.createdAt).inDays;
          final remainingDays = max(1, daysWindow - diffDays);
          return {
            'allowed': false,
            'message':
                'Rate limit: You already reported an issue at this exact location within the last $daysWindow days. Please wait $remainingDays day(s).',
            'complaint': c,
          };
        }
      }
    }

    return {
      'allowed': true,
      'message': 'Rate limit check passed.',
    };
  }
}
