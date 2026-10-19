import '../models/checklist_item.dart';

class MockChecklist {
  MockChecklist._();

  static final List<ChecklistItem> initialItems = [
    const ChecklistItem(
      id: 'CHK-01',
      title: '72-Hour Water Supply',
      category: 'Sustenance',
      description: 'Minimum 1 gallon per person per day for drinking and sanitation.',
      isCompleted: true,
    ),
    const ChecklistItem(
      id: 'CHK-02',
      title: 'Non-Perishable Food Reserves',
      category: 'Sustenance',
      description: 'High-calorie canned foods, energy bars, and manual can opener.',
      isCompleted: true,
    ),
    const ChecklistItem(
      id: 'CHK-03',
      title: 'Emergency Pack Offline Data Sync',
      category: 'Intelligence',
      description: 'Download offline maps, shelters, and hospital emergency contact profiles.',
      isCompleted: true,
    ),
    const ChecklistItem(
      id: 'CHK-04',
      title: 'First-Aid Kit & Prescription Medications',
      category: 'Medical',
      description: 'Sterile bandages, antiseptics, tourniquet, and 14 days of personal medications.',
      isCompleted: false,
    ),
    const ChecklistItem(
      id: 'CHK-05',
      title: 'Emergency Flashlight & Extra Batteries',
      category: 'Tools',
      description: 'Heavy-duty waterproof LED flashlight, battery bank, or crank light.',
      isCompleted: false,
    ),
    const ChecklistItem(
      id: 'CHK-06',
      title: 'Emergency Whistle & Dust Masks',
      category: 'Safety',
      description: 'N95 particulate masks for debris/smoke and signal whistle for rescuers.',
      isCompleted: false,
    ),
    const ChecklistItem(
      id: 'CHK-07',
      title: 'Physical Cash & Critical Identity Documents',
      category: 'Security',
      description: 'Waterproof pouch containing cash (ATMs offline) and photo IDs/insurance.',
      isCompleted: false,
    ),
  ];
}
