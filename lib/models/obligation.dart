/// Model koji predstavlja jednokratnu obvezu s rokom (npr. "Predaja zadaće").
class Obligation {
  final int? id;
  final String name;
  final String? description;
  final DateTime dueDate;
  final String priority; // "low", "medium", "high"
  final int? categoryId; // strani ključ prema Category (nullable - obveza ne mora imati kategoriju)
  final String status; // "pending", "in_progress", "done"

  Obligation({
    this.id,
    required this.name,
    this.description,
    required this.dueDate,
    required this.priority,
    this.categoryId,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'categoryId': categoryId,
      'status': status,
    };
  }

  factory Obligation.fromMap(Map<String, dynamic> map) {
    return Obligation(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['dueDate'] as String),
      priority: map['priority'] as String,
      categoryId: map['categoryId'] as int?,
      status: map['status'] as String,
    );
  }
}