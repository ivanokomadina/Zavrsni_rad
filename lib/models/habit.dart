/// Model koji predstavlja jednu naviku koju korisnik prati (npr. "Učenje 30 min").
class Habit {
  final int? id;
  final String name;
  final String? description;
  final String colorHex;
  final String frequency; // npr. "daily", "weekly", ili CSV dana poput "mon,wed,fri"
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
      // DateTime se ne može direktno spremiti u SQLite, pa ga pretvaramo
      // u ISO 8601 string (npr. "2026-07-21T10:00:00.000") i natrag.
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