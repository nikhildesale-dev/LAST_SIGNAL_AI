enum SyncStatus {
  localOnly,
  synced,
}

class HazardReport {
  final String id;
  final String hazardType;
  final String description;
  final String severity;
  final String sampleLocation;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status; // 'Pending Sync', 'Submitted', 'Under Review', 'Verified', 'Rejected', 'Resolved'
  final SyncStatus syncStatus;
  final String reporterEmail;
  final String? responderNotes;
  final String? verifiedBy;
  final bool isDraft;
  final String? photoPlaceholder;

  const HazardReport({
    required this.id,
    required this.hazardType,
    required this.description,
    required this.severity,
    required this.sampleLocation,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    required this.syncStatus,
    required this.reporterEmail,
    this.responderNotes,
    this.verifiedBy,
    this.isDraft = false,
    this.photoPlaceholder,
  });

  HazardReport copyWith({
    String? id,
    String? hazardType,
    String? description,
    String? severity,
    String? sampleLocation,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? status,
    SyncStatus? syncStatus,
    String? reporterEmail,
    String? responderNotes,
    String? verifiedBy,
    bool? isDraft,
    String? photoPlaceholder,
  }) {
    return HazardReport(
      id: id ?? this.id,
      hazardType: hazardType ?? this.hazardType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      sampleLocation: sampleLocation ?? this.sampleLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      responderNotes: responderNotes ?? this.responderNotes,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      isDraft: isDraft ?? this.isDraft,
      photoPlaceholder: photoPlaceholder ?? this.photoPlaceholder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hazardType': hazardType,
      'description': description,
      'severity': severity,
      'sampleLocation': sampleLocation,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'syncStatus': syncStatus.name,
      'reporterEmail': reporterEmail,
      'responderNotes': responderNotes,
      'verifiedBy': verifiedBy,
      'isDraft': isDraft,
      'photoPlaceholder': photoPlaceholder,
    };
  }

  factory HazardReport.fromJson(Map<String, dynamic> json) {
    return HazardReport(
      id: json['id'] as String,
      hazardType: json['hazardType'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      sampleLocation: json['sampleLocation'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.localOnly,
      ),
      reporterEmail: json['reporterEmail'] as String,
      responderNotes: json['responderNotes'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      isDraft: json['isDraft'] as bool? ?? false,
      photoPlaceholder: json['photoPlaceholder'] as String?,
    );
  }
}
