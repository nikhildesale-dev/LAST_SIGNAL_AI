class ChecklistItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final bool isCompleted;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.isCompleted = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
