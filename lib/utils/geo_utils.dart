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
  final String area;
  final double lat;
  final double lng;

  const NagpurLocation({
    required this.name,
    required this.area,
    required this.lat,
    required this.lng,
  });
}

/// Comprehensive directory of 60+ real Nagpur landmarks, squares, and localities
const List<NagpurLocation> kNagpurLocations = [
  // Central & Civil Lines
  NagpurLocation(name: 'Zero Mile Stone, Wardha Road', area: 'Civil Lines', lat: 21.1458, lng: 79.0882),
  NagpurLocation(name: 'Nagpur High Court & Walker Road', area: 'Civil Lines', lat: 21.1550, lng: 79.0690),
  NagpurLocation(name: 'VCA Stadium, Residency Road', area: 'Civil Lines', lat: 21.1565, lng: 79.0780),
  NagpurLocation(name: 'Seminary Hills & Air Force Station', area: 'Civil Lines', lat: 21.1680, lng: 79.0550),
  NagpurLocation(name: 'Futala Lake Road & Telangkhedi', area: 'West Nagpur', lat: 21.1530, lng: 79.0440),
  NagpurLocation(name: 'Japanese Garden & Governor House', area: 'Civil Lines', lat: 21.1635, lng: 79.0645),
  NagpurLocation(name: 'Nagpur District Collectorate', area: 'Civil Lines', lat: 21.1510, lng: 79.0740),
  
  // Sitabuldi & Ramdaspeth
  NagpurLocation(name: 'Sitabuldi Variety Square', area: 'Sitabuldi', lat: 21.1466, lng: 79.0822),
  NagpurLocation(name: 'Sitabuldi Interchange Metro Station', area: 'Sitabuldi', lat: 21.1455, lng: 79.0835),
  NagpurLocation(name: 'Munje Square & Main Road', area: 'Sitabuldi', lat: 21.1440, lng: 79.0850),
  NagpurLocation(name: 'Ramdaspeth Central Bazaar Road', area: 'Ramdaspeth', lat: 21.1345, lng: 79.0728),
  NagpurLocation(name: 'Canal Road & Lendra Park', area: 'Ramdaspeth', lat: 21.1370, lng: 79.0755),
  NagpurLocation(name: 'Kachipura Square & WHC Road', area: 'Ramdaspeth', lat: 21.1320, lng: 79.0690),
  
  // Dharampeth & West Nagpur
  NagpurLocation(name: 'Coffee House Square, West High Court Road', area: 'Dharampeth', lat: 21.1432, lng: 79.0620),
  NagpurLocation(name: 'Gokulpeth Market Square', area: 'Dharampeth', lat: 21.1415, lng: 79.0580),
  NagpurLocation(name: 'Shankar Nagar Square & LAD College', area: 'Dharampeth', lat: 21.1380, lng: 79.0595),
  NagpurLocation(name: 'Law College Square & Amravati Road', area: 'Dharampeth', lat: 21.1475, lng: 79.0550),
  NagpurLocation(name: 'Ravi Nagar Square & University Campus', area: 'West Nagpur', lat: 21.1505, lng: 79.0490),
  NagpurLocation(name: 'Ambazari Lake & Garden Gate', area: 'Ambazari', lat: 21.1315, lng: 79.0410),
  NagpurLocation(name: 'VNIT Main Gate, South Ambazari Road', area: 'Laxmi Nagar', lat: 21.1210, lng: 79.0650),
  NagpurLocation(name: 'Laxmi Nagar Square & Water Tank', area: 'Laxmi Nagar', lat: 21.1235, lng: 79.0675),
  NagpurLocation(name: 'Bajaj Nagar Square', area: 'Bajaj Nagar', lat: 21.1275, lng: 79.0640),
  NagpurLocation(name: 'Abhyankar Nagar Square', area: 'South West Nagpur', lat: 21.1250, lng: 79.0550),

  // South-West & Ring Road
  NagpurLocation(name: 'Trimurti Nagar Square & Ring Road', area: 'Trimurti Nagar', lat: 21.1120, lng: 79.0480),
  NagpurLocation(name: 'Pratap Nagar Square', area: 'Pratap Nagar', lat: 21.1185, lng: 79.0555),
  NagpurLocation(name: 'Khamla Market & Deo Nagar Square', area: 'Khamla', lat: 21.1140, lng: 79.0680),
  NagpurLocation(name: 'IT Park / Gayatri Nagar, Parsodi', area: 'South-West', lat: 21.1245, lng: 79.0510),
  NagpurLocation(name: 'Jaitala Main Road & T-Point', area: 'Jaitala', lat: 21.0980, lng: 79.0380),
  NagpurLocation(name: 'Swavalambi Nagar Square', area: 'South-West', lat: 21.1090, lng: 79.0450),
  NagpurLocation(name: 'Pande Layout & Ring Road', area: 'Khamla', lat: 21.1080, lng: 79.0620),

  // Wardha Road & South Nagpur
  NagpurLocation(name: 'Lokmat Square & Wardha Road', area: 'Dhantoli', lat: 21.1360, lng: 79.0810),
  NagpurLocation(name: 'Rahate Colony Square', area: 'Dhantoli', lat: 21.1310, lng: 79.0780),
  NagpurLocation(name: 'Chhatrapati Square & Flyover', area: 'Wardha Road', lat: 21.1120, lng: 79.0710),
  NagpurLocation(name: 'Ajni Railway Station Square', area: 'Ajni', lat: 21.1270, lng: 79.0830),
  NagpurLocation(name: 'Ujjwal Nagar & Somalwada Square', area: 'Wardha Road', lat: 21.0985, lng: 79.0695),
  NagpurLocation(name: 'Nagpur Airport T-Point, Sonegaon', area: 'Wardha Road', lat: 21.0890, lng: 79.0650),
  NagpurLocation(name: 'Narendra Nagar Square & Flyover', area: 'South Nagpur', lat: 21.1050, lng: 79.0800),
  NagpurLocation(name: 'Manewada Ring Road Square', area: 'Manewada', lat: 21.1010, lng: 79.0920),
  NagpurLocation(name: 'Omkar Nagar Square', area: 'Manewada', lat: 21.0950, lng: 79.0950),
  NagpurLocation(name: 'Besa Square & Ghogli Road', area: 'South Nagpur', lat: 21.0820, lng: 79.0980),
  NagpurLocation(name: 'Dighori Toll Naka & Ring Road', area: 'South East', lat: 21.1020, lng: 79.1320),

  // Medical, Mahal & Historic Nagpur
  NagpurLocation(name: 'Medical Square & GMC Hospital Gate', area: 'Hanuman Nagar', lat: 21.1180, lng: 79.0980),
  NagpurLocation(name: 'Hanuman Nagar Square & Krida Chowk', area: 'Hanuman Nagar', lat: 21.1220, lng: 79.1020),
  NagpurLocation(name: 'Reshimbagh Ground & C.P. Berar College', area: 'Reshimbagh', lat: 21.1310, lng: 79.1080),
  NagpurLocation(name: 'Baidyanath Square & Great Nag Road', area: 'Ganeshpeth', lat: 21.1340, lng: 79.0980),
  NagpurLocation(name: 'Ganeshpeth Central Bus Station (ST Stand)', area: 'Ganeshpeth', lat: 21.1410, lng: 79.0930),
  NagpurLocation(name: 'Cotton Market Square', area: 'Ganeshpeth', lat: 21.1430, lng: 79.0910),
  NagpurLocation(name: 'Mahal Gandhi Gate & Tilak Statue', area: 'Mahal', lat: 21.1420, lng: 79.1020),
  NagpurLocation(name: 'Badkas Chowk & Kotwali Police Station', area: 'Mahal', lat: 21.1445, lng: 79.1050),
  NagpurLocation(name: 'Gandhisagar Lake (Juma Talao)', area: 'Mahal', lat: 21.1460, lng: 79.0960),
  NagpurLocation(name: 'Itwari Sarafa Bazaar & Shahid Chowk', area: 'Itwari', lat: 21.1520, lng: 79.1120),
  NagpurLocation(name: 'Gandhibagh Garden & Cloth Market', area: 'Gandhibagh', lat: 21.1490, lng: 79.1060),
  NagpurLocation(name: 'Dosar Vaishya Square & Central Avenue', area: 'Central Avenue', lat: 21.1495, lng: 79.1000),
  NagpurLocation(name: 'Agrasen Chowk & Mayo Hospital Road', area: 'Gandhibagh', lat: 21.1530, lng: 79.1020),

  // East Nagpur
  NagpurLocation(name: 'Wardhaman Nagar Central Avenue', area: 'Wardhaman Nagar', lat: 21.1480, lng: 79.1250),
  NagpurLocation(name: 'Pardi Octroi Naka & Bhandara Road', area: 'East Nagpur', lat: 21.1450, lng: 79.1550),
  NagpurLocation(name: 'Nandanvan Square & Hasanbagh', area: 'Nandanvan', lat: 21.1380, lng: 79.1310),
  NagpurLocation(name: 'KDK College Road & Jagnade Chowk', area: 'Nandanvan', lat: 21.1340, lng: 79.1220),
  NagpurLocation(name: 'Shanti Nagar & Mudliar Square', area: 'East Nagpur', lat: 21.1620, lng: 79.1200),
  NagpurLocation(name: 'Lakadganj Square & Timber Market', area: 'Lakadganj', lat: 21.1510, lng: 79.1180),
  NagpurLocation(name: 'Garoba Maidan & Bagadganj', area: 'East Nagpur', lat: 21.1460, lng: 79.1380),

  // North Nagpur
  NagpurLocation(name: 'Sadar Mount Road & Residency Road', area: 'Sadar', lat: 21.1620, lng: 79.0830),
  NagpurLocation(name: 'Liberty Cinema Square & Katol Road T-Point', area: 'Sadar', lat: 21.1650, lng: 79.0790),
  NagpurLocation(name: 'Chaoni Square & Raj Bhavan Road', area: 'Sadar', lat: 21.1685, lng: 79.0750),
  NagpurLocation(name: 'Mankapur Sports Complex & Ring Road', area: 'Mankapur', lat: 21.1780, lng: 79.0750),
  NagpurLocation(name: 'Jaripatka Main Road & Sindhi Colony', area: 'Jaripatka', lat: 21.1850, lng: 79.0920),
  NagpurLocation(name: 'Kadbi Chowk & Kamptee Road', area: 'North Nagpur', lat: 21.1710, lng: 79.0910),
  NagpurLocation(name: 'Automotive Square, Kamptee Road', area: 'North Nagpur', lat: 21.1980, lng: 79.1120),
  NagpurLocation(name: 'Kamal Chowk & Pachpaoli Railway Bridge', area: 'Pachpaoli', lat: 21.1680, lng: 79.1050),
  NagpurLocation(name: 'Indora Square & Bezonbagh', area: 'North Nagpur', lat: 21.1760, lng: 79.0980),
  NagpurLocation(name: 'Koradi Road T-Point & Modern School', area: 'Mankapur', lat: 21.1880, lng: 79.0800),
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

  /// Search Nagpur landmarks and localities
  static List<NagpurLocation> searchLocations(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return kNagpurLocations.where((loc) {
      return loc.name.toLowerCase().contains(q) ||
          loc.area.toLowerCase().contains(q);
    }).toList();
  }

  /// Find closest recognized Nagpur landmark from GPS coordinates
  static NagpurLocation findClosestNagpurLandmark(double lat, double lng) {
    NagpurLocation closest = kNagpurLocations.first;
    double minDistance = double.infinity;

    for (final loc in kNagpurLocations) {
      final dist = haversineDistance(lat, lng, loc.lat, loc.lng);
      if (dist < minDistance) {
        minDistance = dist;
        closest = loc;
      }
    }
    return closest;
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

  /// Check 7-day rate-limiting with tamper-proof trusted time
  static Map<String, dynamic> checkRateLimit(
    String phoneHash,
    double newLat,
    double newLng,
    List<Complaint> complaints, {
    int daysWindow = 7,
    double radiusMeters = 50.0,
    DateTime? trustedNow,
  }) {
    final now = trustedNow ?? DateTime.now().toUtc();
    final cutoff = now.subtract(Duration(days: daysWindow));

    for (final c in complaints) {
      if (c.reporterPhoneHashes.contains(phoneHash)) {
        final dist = haversineDistance(newLat, newLng, c.lat, c.lng);
        if (dist <= radiusMeters && c.createdAt.toUtc().isAfter(cutoff)) {
          final diffDays = now.difference(c.createdAt.toUtc()).inDays;
          final remainingDays = max(1, daysWindow - diffDays);
          return {
            'allowed': false,
            'message':
                'Rate limit: This mobile number has already reported a complaint within 50 meters in the last $daysWindow days. Please wait $remainingDays day(s).',
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
