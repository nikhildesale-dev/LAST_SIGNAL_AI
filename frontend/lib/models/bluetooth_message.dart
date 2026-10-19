class BluetoothMessage {
  final String id;
  final String reportId;
  final String sourceDevice; // e.g. 'Device A (Beacon)', 'Device B (Relay)'
  final String targetDevice; // e.g. 'Device B (Relay)', 'Device C (Citizen)'
  final String hazardType;
  final String severity;
  final String location;
  final String payloadSummary;
  final DateTime timestamp;
  final DateTime expiryTime;
  final bool isDuplicate;
  final String status; // 'In Transit', 'Received', 'Imported to Queue'

  const BluetoothMessage({
    required this.id,
    required this.reportId,
    required this.sourceDevice,
    required this.targetDevice,
    required this.hazardType,
    required this.severity,
    required this.location,
    required this.payloadSummary,
    required this.timestamp,
    required this.expiryTime,
    this.isDuplicate = false,
    this.status = 'Received',
  });

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  BluetoothMessage copyWith({
    String? id,
    String? reportId,
    String? sourceDevice,
    String? targetDevice,
    String? hazardType,
    String? severity,
    String? location,
    String? payloadSummary,
    DateTime? timestamp,
    DateTime? expiryTime,
    bool? isDuplicate,
    String? status,
  }) {
    return BluetoothMessage(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      targetDevice: targetDevice ?? this.targetDevice,
      hazardType: hazardType ?? this.hazardType,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      payloadSummary: payloadSummary ?? this.payloadSummary,
      timestamp: timestamp ?? this.timestamp,
      expiryTime: expiryTime ?? this.expiryTime,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'sourceDevice': sourceDevice,
      'targetDevice': targetDevice,
      'hazardType': hazardType,
      'severity': severity,
      'location': location,
      'payloadSummary': payloadSummary,
      'timestamp': timestamp.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
      'isDuplicate': isDuplicate,
      'status': status,
    };
  }

  factory BluetoothMessage.fromJson(Map<String, dynamic> json) {
    return BluetoothMessage(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      sourceDevice: json['sourceDevice'] as String,
      targetDevice: json['targetDevice'] as String,
      hazardType: json['hazardType'] as String,
      severity: json['severity'] as String,
      location: json['location'] as String,
      payloadSummary: json['payloadSummary'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryTime: DateTime.parse(json['expiryTime'] as String),
      isDuplicate: json['isDuplicate'] as bool? ?? false,
      status: json['status'] as String? ?? 'Received',
    );
  }
}
