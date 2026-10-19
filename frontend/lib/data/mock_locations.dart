import '../models/emergency_location.dart';

class MockLocations {
  MockLocations._();

  static final List<EmergencyLocation> sampleLocations = [
    const EmergencyLocation(
      id: 'LOC-HOSP-01',
      name: 'St. Jude Marine Memorial Hospital',
      type: LocationType.hospital,
      sampleAddress: '420 Harbor View Parkway, Sector 3',
      distanceKm: 1.8,
      latitude: 18.9220,
      longitude: 72.8340,
      capacity: 350,
      occupied: 285,
      contactPhone: '+1 (555) 911-4040',
      isOpen: true,
      isSavedOffline: true,
      availableServices: [
        'Trauma Center Level 1',
        'Emergency Power Generator',
        'Decontamination',
        'Pediatric Care',
      ],
    ),

    const EmergencyLocation(
      id: 'LOC-SHEL-01',
      name: 'Central High Civic Emergency Shelter',
      type: LocationType.shelter,
      sampleAddress: '88 Oakridge Boulevard, Sector 2',
      distanceKm: 2.6,
      latitude: 18.9350,
      longitude: 72.8250,
      capacity: 600,
      occupied: 340,
      contactPhone: '+1 (555) 911-3030',
      isOpen: true,
      isSavedOffline: true,
      availableServices: [
        'Clean Water Supply',
        'Emergency Rations',
        'Temporary Cots',
        'First Aid Clinic',
        'Pet Safe',
      ],
    ),

    const EmergencyLocation(
      id: 'LOC-HOSP-02',
      name: 'Metropolitan General Trauma Center',
      type: LocationType.hospital,
      sampleAddress: '1050 Highland Expressway, North Sector',
      distanceKm: 4.9,
      latitude: 18.9480,
      longitude: 72.8420,
      capacity: 500,
      occupied: 490, // Near capacity!
      contactPhone: '+1 (555) 911-7788',
      isOpen: true,
      isSavedOffline: true,
      availableServices: [
        'Burn ICU',
        'Surgical Theater',
        'Helipad Access',
      ],
    ),

    const EmergencyLocation(
      id: 'LOC-SHEL-02',
      name: 'Bayview Arena Relief & Evacuation Hub',
      type: LocationType.shelter,
      sampleAddress: '15 Maritime Promenade, East Pier',
      distanceKm: 3.4,
      latitude: 18.9150,
      longitude: 72.8490,
      capacity: 1200,
      occupied: 620,
      contactPhone: '+1 (555) 911-2020',
      isOpen: true,
      isSavedOffline: true,
      availableServices: [
        'P2P Communications Node',
        'High-volume Rations',
        'Family Separation Desk',
        'Medical Evacuation Staging',
      ],
    ),

    const EmergencyLocation(
      id: 'LOC-CMD-01',
      name: 'District Disaster Coordination Command',
      type: LocationType.commandPost,
      sampleAddress: '1 City Hall Plaza, Central Hub',
      distanceKm: 2.1,
      latitude: 18.9300,
      longitude: 72.8330,
      capacity: 100,
      occupied: 45,
      contactPhone: '+1 (555) 911-0000',
      isOpen: true,
      isSavedOffline: true,
      availableServices: [
        'Satellite Uplink',
        'Search & Rescue Dispatch',
        'Drone Reconnaissance Hub',
      ],
    ),
  ];
}
