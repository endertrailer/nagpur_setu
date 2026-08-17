import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../data/seed_data.dart';
import '../utils/geo_utils.dart';

class ComplaintsRepository extends ChangeNotifier {
  static final ComplaintsRepository _instance = ComplaintsRepository._internal();
  factory ComplaintsRepository() => _instance;

  List<Complaint> _complaints = [];
  String? _citizenPhone;
  String? _citizenPhoneHash;

  ComplaintsRepository._internal() {
    _complaints = List.from(kInitialSeedComplaints);
  }

  List<Complaint> get complaints => List.unmodifiable(_complaints.where((c) => GeoUtils.isInsideNagpur(c.lat, c.lng)));

  String? get currentCitizenPhone => _citizenPhone;
  String? get currentCitizenPhoneHash => _citizenPhoneHash;
  bool get isCitizenLoggedIn => _citizenPhoneHash != null && _citizenPhoneHash!.isNotEmpty;

  void setCitizenSession(String phone) {
    _citizenPhone = phone;
    _citizenPhoneHash = GeoUtils.hashPhoneNumber(phone);
    notifyListeners();
  }

  bool isCorroboratedByCurrentCitizen(String complaintId) {
    if (!isCitizenLoggedIn) return false;
    return hasCorroborated(complaintId, _citizenPhoneHash!);
  }

  bool hasCorroborated(String complaintId, String phoneHash) {
    final complaint = _complaints.firstWhere(
      (c) => c.id == complaintId,
      orElse: () => _complaints.first,
    );
    return complaint.reporterPhoneHashes.contains(phoneHash);
  }

  void resetToDefaultSeed() {
    _complaints = List.from(kInitialSeedComplaints);
    notifyListeners();
  }

  /// Submit new report or merge with duplicate within 50 meters
  Map<String, dynamic> submitOrMergeReport({
    required String category,
    required String description,
    required String photoUrl,
    required double lat,
    required double lng,
    required String landmark,
    required String phoneHash,
  }) {
    // 1. Strict Nagpur Boundary Check
    if (!GeoUtils.isInsideNagpur(lat, lng)) {
      return {
        'success': false,
        'message': 'Rejected: Location is outside Nagpur Municipal Corporation boundaries. Nagpur Setu is strictly for grievances within Nagpur city limits.',
        'isDuplicate': false,
      };
    }

    // 2. Strict 7-day rate-limiting per phone hash within 50 meters
    final rateLimit = GeoUtils.checkRateLimit(
      phoneHash,
      lat,
      lng,
      _complaints,
      daysWindow: 7,
      radiusMeters: 50.0,
    );

    if (!rateLimit['allowed']) {
      return {
        'success': false,
        'message': rateLimit['message'],
        'isDuplicate': true,
        'complaint': rateLimit['complaint'],
      };
    }

    // 3. Check for duplicate open/in-progress issue within 50m
    final dupResult = GeoUtils.findDuplicateComplaint(
      lat,
      lng,
      category,
      _complaints,
      thresholdMeters: 50.0,
    );

    final Complaint? existing = dupResult['duplicate'];

    if (existing != null) {
      // Merge report
      final updatedPhotos = List<String>.from(existing.evidencePhotos);
      if (!updatedPhotos.contains(photoUrl)) {
        updatedPhotos.add(photoUrl);
      }

      final updatedHashes = List<String>.from(existing.reporterPhoneHashes);
      if (!updatedHashes.contains(phoneHash)) {
        updatedHashes.add(phoneHash);
      }

      final updated = existing.copyWith(
        reportCount: existing.reportCount + 1,
        evidencePhotos: updatedPhotos,
        reporterPhoneHashes: updatedHashes,
      );

      final index = _complaints.indexWhere((c) => c.id == existing.id);
      if (index != -1) {
        _complaints[index] = updated;
      }

      notifyListeners();

      return {
        'success': true,
        'isDuplicate': true,
        'message':
            'Corroborated existing issue #${existing.id} (${(dupResult['distanceMeters'] as double).round()}m away). Priority boosted to ${updated.reportCount} reports!',
        'complaint': updated,
      };
    }

    // 4. Create fresh complaint
    final newId = 'NGP-${8500 + _complaints.length + Random().nextInt(50)}';
    final newComplaint = Complaint(
      id: newId,
      title: '$category reported at $landmark',
      category: category,
      description: description,
      photoUrl: photoUrl,
      lat: lat,
      lng: lng,
      ward: 'Nagpur City',
      landmark: landmark,
      status: ComplaintStatus.open,
      createdAt: DateTime.now(),
      reportCount: 1,
      evidencePhotos: [photoUrl],
      reporterPhoneHashes: [phoneHash],
    );

    _complaints.insert(0, newComplaint);
    notifyListeners();

    return {
      'success': true,
      'isDuplicate': false,
      'message': 'New civic complaint #$newId submitted successfully to Nagpur Setu map!',
      'complaint': newComplaint,
    };
  }

  /// Upvote / Corroborate complaint
  Complaint? upvoteComplaint(String id, String phoneHash) {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return null;

    final existing = _complaints[index];
    final updatedHashes = List<String>.from(existing.reporterPhoneHashes);
    if (!updatedHashes.contains(phoneHash)) {
      updatedHashes.add(phoneHash);
    } else {
      return existing; // Already corroborated
    }

    final updated = existing.copyWith(
      reportCount: existing.reportCount + 1,
      reporterPhoneHashes: updatedHashes,
    );

    _complaints[index] = updated;
    notifyListeners();
    return updated;
  }
}
