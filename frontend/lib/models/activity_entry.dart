class ActivityEntry {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String category; // 'report', 'sync', 'verification', 'bluetooth', 'emergency'
  final String actorRole;

  const ActivityEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
    required this.actorRole,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'actorRole': actorRole,
    };
  }

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: json['category'] as String,
      actorRole: json['actorRole'] as String,
    );
  }
}
