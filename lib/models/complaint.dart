enum ComplaintStatus {
  open,
  inProgress,
  resolved,
}

extension ComplaintStatusExtension on ComplaintStatus {
  String get displayName {
    switch (this) {
      case ComplaintStatus.open:
        return 'Open Ticket';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved & Verified';
    }
  }

  String get code {
    switch (this) {
      case ComplaintStatus.open:
        return 'open';
      case ComplaintStatus.inProgress:
        return 'in_progress';
      case ComplaintStatus.resolved:
        return 'resolved';
    }
  }

  static ComplaintStatus fromString(String val) {
    if (val == 'in_progress') return ComplaintStatus.inProgress;
    if (val == 'resolved') return ComplaintStatus.resolved;
    return ComplaintStatus.open;
  }
}

class Complaint {
  final String id;
  final String title;
  final String category;
  final String description;
  final String photoUrl;
  final double lat;
  final double lng;
  final String ward;
  final String landmark;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedPhotoUrl;
  final String? resolutionNotes;
  final String? assignedTo;
  final int reportCount;
  final List<String> evidencePhotos;
  final List<String> reporterPhoneHashes;

  Complaint({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.photoUrl,
    required this.lat,
    required this.lng,
    required this.ward,
    required this.landmark,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedPhotoUrl,
    this.resolutionNotes,
    this.assignedTo,
    this.reportCount = 1,
    this.evidencePhotos = const [],
    this.reporterPhoneHashes = const [],
  });

  Complaint copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? photoUrl,
    double? lat,
    double? lng,
    String? ward,
    String? landmark,
    ComplaintStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedPhotoUrl,
    String? resolutionNotes,
    String? assignedTo,
    int? reportCount,
    List<String>? evidencePhotos,
    List<String>? reporterPhoneHashes,
  }) {
    return Complaint(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      ward: ward ?? this.ward,
      landmark: landmark ?? this.landmark,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedPhotoUrl: resolvedPhotoUrl ?? this.resolvedPhotoUrl,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      reportCount: reportCount ?? this.reportCount,
      evidencePhotos: evidencePhotos ?? this.evidencePhotos,
      reporterPhoneHashes: reporterPhoneHashes ?? this.reporterPhoneHashes,
    );
  }
}
