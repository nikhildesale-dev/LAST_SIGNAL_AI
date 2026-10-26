import 'package:flutter/material.dart';
import '../data/mock_checklist.dart';
import '../data/mock_locations.dart';
import '../models/checklist_item.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_location.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class EmergencyPackProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  final ApiService? _apiService;

  List<EmergencyContact> _contacts = [];
  List<ChecklistItem> _checklistItems = [];
  List<EmergencyLocation> _savedLocations = [];
  String _emergencyInstructions = '';
  DateTime _lastUpdated = DateTime.now();

  EmergencyPackProvider(this._storage, [this._apiService]);

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  List<ChecklistItem> get checklistItems => List.unmodifiable(_checklistItems);
  List<EmergencyLocation> get savedLocations => List.unmodifiable(_savedLocations);
  String get emergencyInstructions => _emergencyInstructions;
  DateTime get lastUpdated => _lastUpdated;

  int get completedChecklistCount => _checklistItems.where((i) => i.isCompleted).length;
  int get totalChecklistCount => _checklistItems.length;
  double get checklistProgress =>
      totalChecklistCount == 0 ? 0.0 : completedChecklistCount / totalChecklistCount;

  Future<void> init() async {
    // 1. Load contacts
    final savedContacts = await _storage.getContacts();
    if (savedContacts != null && savedContacts.isNotEmpty) {
      _contacts = savedContacts;
    } else {
      _contacts = [
        const EmergencyContact(
          id: 'CONT-01',
          name: 'David Lin',
          relationship: 'Spouse',
          phone: '+1 (555) 019-2834',
          isPrimary: true,
          notes: 'Home address: Sector 4 Maritime Ridge.',
        ),
        const EmergencyContact(
          id: 'CONT-02',
          name: 'Central Coast Search & Rescue Dispatch',
          relationship: 'Emergency Authority',
          phone: '+1 (555) 911-0000',
          isPrimary: false,
          notes: 'Emergency broadcast monitoring channel 16.',
        ),
      ];
      await _storage.saveContacts(_contacts);
    }

    // 2. Load instructions
    final savedInstructions = await _storage.getInstructions();
    if (savedInstructions != null && savedInstructions.isNotEmpty) {
      _emergencyInstructions = savedInstructions;
    } else {
      _emergencyInstructions =
          'PRIMARY RALLY POINT: North Ridge Evacuation Shelter.\n'
          'SECONDARY RENDEZVOUS: Sector 4 Relief Distribution Center.\n'
          'EMERGENCY COMM: Bluetooth P2P Relay Mesh active.\n'
          'MEDICAL PRIORITY: Maya Lin has mild asthma (inhaler packed in pack).';
      await _storage.saveInstructions(_emergencyInstructions);
    }

    // 3. Load checklist & completion states
    final baseChecklist = List<ChecklistItem>.from(MockChecklist.initialItems);
    final savedChecklistStates = await _storage.getChecklistState();

    if (savedChecklistStates != null) {
      _checklistItems = baseChecklist.map((item) {
        if (savedChecklistStates.containsKey(item.id)) {
          return item.copyWith(isCompleted: savedChecklistStates[item.id]!);
        }
        return item;
      }).toList();
    } else {
      _checklistItems = baseChecklist;
      final initialMap = {for (var item in _checklistItems) item.id: item.isCompleted};
      await _storage.saveChecklistState(initialMap);
    }

    // 4. Saved offline emergency locations (attempt backend live load, fall back to sample locations)
    _savedLocations = List.from(MockLocations.sampleLocations);
    if (_apiService != null) {
      try {
        final remoteLocs = await _apiService.fetchLocations();
        if (remoteLocs != null && remoteLocs.isNotEmpty) {
          _savedLocations = remoteLocs;
        }
      } catch (_) {}
    }

    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  // --- Contact Actions ---
  Future<void> addContact({
    required String name,
    required String relationship,
    required String phone,
    bool isPrimary = false,
    String? notes,
  }) async {
    final newContact = EmergencyContact(
      id: 'CONT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      name: name,
      relationship: relationship,
      phone: phone,
      isPrimary: isPrimary,
      notes: notes,
    );

    if (isPrimary) {
      _contacts = _contacts.map((c) => c.copyWith(isPrimary: false)).toList();
    }

    _contacts.add(newContact);
    _lastUpdated = DateTime.now();
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }

  Future<void> updateContact(EmergencyContact updatedContact) async {
    _contacts = _contacts.map((c) {
      if (c.id == updatedContact.id) {
        return updatedContact;
      }
      if (updatedContact.isPrimary) {
        return c.copyWith(isPrimary: false);
      }
      return c;
    }).toList();

    _lastUpdated = DateTime.now();
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }

  Future<void> removeContact(String contactId) async {
    _contacts.removeWhere((c) => c.id == contactId);
    _lastUpdated = DateTime.now();
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }

  // --- Instructions Actions ---
  Future<void> updateInstructions(String newInstructions) async {
    _emergencyInstructions = newInstructions;
    _lastUpdated = DateTime.now();
    await _storage.saveInstructions(_emergencyInstructions);
    notifyListeners();
  }

  // --- Checklist Actions ---
  Future<void> toggleChecklistItem(String itemId) async {
    _checklistItems = _checklistItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    final stateMap = {for (var item in _checklistItems) item.id: item.isCompleted};
    _lastUpdated = DateTime.now();
    await _storage.saveChecklistState(stateMap);
    notifyListeners();
  }
}
