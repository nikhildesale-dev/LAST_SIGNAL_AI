enum LocationType {
  hospital,
  shelter,
  commandPost,
  reliefCenter,
}

class EmergencyLocation {
  final String id;
  final String name;
  final LocationType type;
  final String sampleAddress;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final int capacity;
  final int occupied;
  final String contactPhone;
  final bool isOpen;
  final bool isSavedOffline;
  final List<String> availableServices;

  const EmergencyLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.sampleAddress,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.occupied,
    required this.contactPhone,
    this.isOpen = true,
    this.isSavedOffline = true,
    required this.availableServices,
  });

  EmergencyLocation copyWith({
    String? id,
    String? name,
    LocationType? type,
    String? sampleAddress,
    double? distanceKm,
    double? latitude,
    double? longitude,
    int? capacity,
    int? occupied,
    String? contactPhone,
    bool? isOpen,
    bool? isSavedOffline,
    List<String>? availableServices,
  }) {
    return EmergencyLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sampleAddress: sampleAddress ?? this.sampleAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capacity: capacity ?? this.capacity,
      occupied: occupied ?? this.occupied,
      contactPhone: contactPhone ?? this.contactPhone,
      isOpen: isOpen ?? this.isOpen,
      isSavedOffline: isSavedOffline ?? this.isSavedOffline,
      availableServices: availableServices ?? this.availableServices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'sampleAddress': sampleAddress,
      'distanceKm': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
      'capacity': capacity,
      'occupied': occupied,
      'contactPhone': contactPhone,
      'isOpen': isOpen,
      'isSavedOffline': isSavedOffline,
      'availableServices': availableServices,
    };
  }

  factory EmergencyLocation.fromJson(Map<String, dynamic> json) {
    return EmergencyLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      type: LocationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LocationType.hospital,
      ),
      sampleAddress: json['sampleAddress'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      capacity: json['capacity'] as int,
      occupied: json['occupied'] as int,
      contactPhone: json['contactPhone'] as String,
      isOpen: json['isOpen'] as bool? ?? true,
      isSavedOffline: json['isSavedOffline'] as bool? ?? true,
      availableServices: List<String>.from(json['availableServices'] as List),
    );
  }
}
