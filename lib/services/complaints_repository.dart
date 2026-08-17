import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../data/seed_data.dart';
import '../utils/geo_utils.dart';

class ComplaintsRepository extends ChangeNotifier {
  static final ComplaintsRepository _instance = ComplaintsRepository._internal();
  factory ComplaintsRepository() => _instance;

  List<Complaint> _complaints = [];

  ComplaintsRepository._internal() {
    _complaints = List.from(kInitialSeedComplaints);
  }

  List<Complaint> get complaints => List.unmodifiable(_complaints.where((c) => GeoUtils.isInsideNagpur(c.lat, c.lng)));

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
        'message': 'Rejected: Location is outside Nagpur Municipal boundaries. Nagpur Setu is strictly for grievances within Nagpur city limits.',
        'isDuplicate': false,
      };
    }

    // 2. Check 7-day rate-limiting
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

  /// Upvote / "+1 Me Too"
  Complaint? upvoteComplaint(String id, String phoneHash) {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return null;

    final existing = _complaints[index];
    final updatedHashes = List<String>.from(existing.reporterPhoneHashes);
    if (!updatedHashes.contains(phoneHash)) {
      updatedHashes.add(phoneHash);
    }

    final updated = existing.copyWith(
      reportCount: existing.reportCount + 1,
      reporterPhoneHashes: updatedHashes,
    );

    _complaints[index] = updated;
    notifyListeners();
    return updated;
  }

  /// Update status (Open -> In Progress)
  void updateStatus(String id, ComplaintStatus status, {String? assignedTo}) {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return;

    _complaints[index] = _complaints[index].copyWith(
      status: status,
      assignedTo: assignedTo ?? _complaints[index].assignedTo,
    );
    notifyListeners();
  }

  /// Mark complaint resolved (STRICTLY requires after-photo!)
  Map<String, dynamic> resolveComplaint({
    required String id,
    required String resolvedPhotoUrl,
    required String resolutionNotes,
    String? assignedTo,
  }) {
    if (resolvedPhotoUrl.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Resolution constraint: An After-Photo proof is strictly required before marking resolved.',
      };
    }

    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) {
      return {'success': false, 'message': 'Complaint not found.'};
    }

    final resolved = _complaints[index].copyWith(
      status: ComplaintStatus.resolved,
      resolvedAt: DateTime.now(),
      resolvedPhotoUrl: resolvedPhotoUrl,
      resolutionNotes: resolutionNotes.trim().isEmpty
          ? 'Civic repair completed and verified by field team.'
          : resolutionNotes.trim(),
      assignedTo: assignedTo ?? _complaints[index].assignedTo ?? 'NMC Rapid Response Wing',
    );

    _complaints[index] = resolved;
    notifyListeners();

    return {
      'success': true,
      'message': 'Complaint #$id verified & resolved with After-Photo audit proof!',
      'complaint': resolved,
    };
  }
}
