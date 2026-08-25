/// Model koji predstavlja jednu naviku koju korisnik prati
class Habit {
  final int? id;
  final String name;
  final String? description;
  final String colorHex;
  final String frequency;
  final DateTime createdAt;

  Habit({
    this.id,
    required this.name,
    this.description,
    required this.colorHex,
    required this.frequency,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorHex': colorHex,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorHex: map['colorHex'] as String,
      frequency: map['frequency'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
