import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../data/seed_data.dart';
import '../utils/geo_utils.dart';
import 'network_service.dart';
import 'supabase_service.dart';

class ComplaintsRepository extends ChangeNotifier {
  static final ComplaintsRepository _instance = ComplaintsRepository._internal();
  factory ComplaintsRepository() => _instance;

  List<Complaint> _complaints = [];
  String? _citizenPhone;
  String? _citizenPhoneHash;
  bool _isRealtimeSubscribed = false;

  ComplaintsRepository._internal() {
    _complaints = List.from(kInitialSeedComplaints);
    _initSupabaseSync();
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

  /// Initialize Supabase data fetching and live Realtime WebSocket stream
  Future<void> _initSupabaseSync() async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      // 1. Fetch existing complaints from Supabase
      final response = await client
          .from('complaints')
          .select()
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final List<Complaint> liveData = response.map<Complaint>((row) {
          final statusStr = row['status'] as String? ?? 'open';
          ComplaintStatus status = ComplaintStatus.open;
          if (statusStr == 'in_progress') status = ComplaintStatus.inProgress;
          if (statusStr == 'resolved') status = ComplaintStatus.resolved;

          return Complaint(
            id: row['complaint_ref'] ?? row['id'].toString().substring(0, 8),
            title: row['title'] ?? 'Civic Issue',
            category: row['category'] ?? 'Pothole',
            description: row['description'] ?? '',
            photoUrl: row['photo_url'] ?? '',
            lat: (row['lat'] as num?)?.toDouble() ?? 21.1458,
            lng: (row['lng'] as num?)?.toDouble() ?? 79.0882,
            ward: row['ward'] ?? 'Nagpur City',
            landmark: row['landmark'] ?? 'Nagpur',
            status: status,
            createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
            reportCount: (row['report_count'] as num?)?.toInt() ?? 1,
            evidencePhotos: List<String>.from(row['evidence_photos'] ?? []),
            reporterPhoneHashes: List<String>.from(row['reporter_phone_hashes'] ?? []),
            assignedTo: row['assigned_to'],
            resolvedPhotoUrl: row['resolved_photo_url'],
            resolutionNotes: row['resolution_notes'],
            resolvedAt: DateTime.tryParse(row['resolved_at'] ?? ''),
          );
        }).toList();

        if (liveData.isNotEmpty) {
          _complaints = liveData;
          notifyListeners();
        }
      }
    } catch (_) {
      // Retain local memory seed if Supabase table is not yet migrated
    }

    // 2. Subscribe to Realtime Postgres Changes
    if (!_isRealtimeSubscribed) {
      try {
        client.from('complaints').stream(primaryKey: ['id']).listen((data) {
          _onRealtimeUpdate(data);
        });
        _isRealtimeSubscribed = true;
      } catch (_) {}
    }
  }

  void _onRealtimeUpdate(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return;

    final List<Complaint> updated = data.map<Complaint>((row) {
      final statusStr = row['status'] as String? ?? 'open';
      ComplaintStatus status = ComplaintStatus.open;
      if (statusStr == 'in_progress') status = ComplaintStatus.inProgress;
      if (statusStr == 'resolved') status = ComplaintStatus.resolved;

      return Complaint(
        id: row['complaint_ref'] ?? row['id'].toString().substring(0, 8),
        title: row['title'] ?? 'Civic Issue',
        category: row['category'] ?? 'Pothole',
        description: row['description'] ?? '',
        photoUrl: row['photo_url'] ?? '',
        lat: (row['lat'] as num?)?.toDouble() ?? 21.1458,
        lng: (row['lng'] as num?)?.toDouble() ?? 79.0882,
        ward: row['ward'] ?? 'Nagpur City',
        landmark: row['landmark'] ?? 'Nagpur',
        status: status,
        createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
        reportCount: (row['report_count'] as num?)?.toInt() ?? 1,
        evidencePhotos: List<String>.from(row['evidence_photos'] ?? []),
        reporterPhoneHashes: List<String>.from(row['reporter_phone_hashes'] ?? []),
        assignedTo: row['assigned_to'],
        resolvedPhotoUrl: row['resolved_photo_url'],
        resolutionNotes: row['resolution_notes'],
        resolvedAt: DateTime.tryParse(row['resolved_at'] ?? ''),
      );
    }).toList();

    _complaints = updated;
    notifyListeners();
  }

  void resetToDefaultSeed() {
    _complaints = List.from(kInitialSeedComplaints);
    notifyListeners();
  }

  /// Upload photo file to Supabase Storage Bucket
  Future<String> uploadImageToSupabase(String filePath, String bucketName) async {
    final client = SupabaseConfig.client;
    if (client == null) return filePath;

    try {
      final file = File(filePath);
      if (!await file.exists()) return filePath;

      final fileExt = filePath.split('.').last;
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}.$fileExt';

      await client.storage.from(bucketName).upload(fileName, file);
      final publicUrl = client.storage.from(bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (_) {
      return filePath;
    }
  }

  /// Submit new report or merge with duplicate within 50 meters
  Future<Map<String, dynamic>> submitOrMergeReport({
    required String category,
    required String description,
    required String photoUrl,
    required double lat,
    required double lng,
    required String landmark,
    required String phoneHash,
  }) async {
    // 1. Strict Nagpur Boundary Check
    if (!GeoUtils.isInsideNagpur(lat, lng)) {
      return {
        'success': false,
        'message': 'Rejected: Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}) is outside Nagpur Municipal Corporation boundaries. Pins outside Nagpur cannot be added.',
        'isDuplicate': false,
      };
    }

    // 2. Authoritative Tamper-Proof Network Time
    final trustedTime = await NetworkService.getTrustedNetworkTime();

    // 3. Strict 7-day rate-limiting per phone hash within 50 meters
    final rateLimit = GeoUtils.checkRateLimit(
      phoneHash,
      lat,
      lng,
      _complaints,
      daysWindow: 7,
      radiusMeters: 50.0,
      trustedNow: trustedTime,
    );

    if (!rateLimit['allowed']) {
      return {
        'success': false,
        'message': rateLimit['message'],
        'isDuplicate': true,
        'complaint': rateLimit['complaint'],
      };
    }

    // 4. Upload photo to Supabase storage if it's a local file path
    String finalPhotoUrl = photoUrl;
    if (!photoUrl.startsWith('http') && !kIsWeb) {
      finalPhotoUrl = await uploadImageToSupabase(photoUrl, 'complaint-evidence');
    }

    // 5. Check for duplicate open/in-progress issue within 50m
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
      if (!updatedPhotos.contains(finalPhotoUrl)) {
        updatedPhotos.add(finalPhotoUrl);
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

      // Sync merge to Supabase
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('complaints').update({
            'report_count': updated.reportCount,
            'evidence_photos': updatedPhotos,
            'reporter_phone_hashes': updatedHashes,
            'updated_at': trustedTime.toIso8601String(),
          }).eq('complaint_ref', existing.id);
        } catch (_) {}
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

    // 6. Create fresh complaint
    final newId = 'NGP-${8500 + _complaints.length + Random().nextInt(50)}';
    final newComplaint = Complaint(
      id: newId,
      title: '$category reported near $landmark',
      category: category,
      description: description.isEmpty ? '$category reported by verified citizen.' : description,
      photoUrl: finalPhotoUrl,
      lat: lat,
      lng: lng,
      ward: 'Nagpur City',
      landmark: landmark,
      status: ComplaintStatus.open,
      createdAt: trustedTime,
      reportCount: 1,
      evidencePhotos: [finalPhotoUrl],
      reporterPhoneHashes: [phoneHash],
    );

    _complaints.insert(0, newComplaint);

    // Sync insert to Supabase
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('complaints').insert({
          'complaint_ref': newId,
          'title': newComplaint.title,
          'category': category,
          'description': newComplaint.description,
          'photo_url': finalPhotoUrl,
          'evidence_photos': [finalPhotoUrl],
          'lat': lat,
          'lng': lng,
          'landmark': landmark,
          'status': 'open',
          'report_count': 1,
          'reporter_phone_hashes': [phoneHash],
          'created_at': trustedTime.toIso8601String(),
        });
      } catch (_) {}
    }

    notifyListeners();

    return {
      'success': true,
      'isDuplicate': false,
      'message': 'New civic grievance #$newId submitted! It has been pinned on the Nagpur map and added to the public grievances feed.',
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

    // Sync upvote to Supabase
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        client.from('complaints').update({
          'report_count': updated.reportCount,
          'reporter_phone_hashes': updatedHashes,
        }).eq('complaint_ref', id);
      } catch (_) {}
    }

    notifyListeners();
    return updated;
  }
}
