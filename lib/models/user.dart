/// Model korisničkog profila
class AppUser {
  final int? id;
  final String name;
  final String pinHash;
  final String themePreference;

  AppUser({
    this.id,
    required this.name,
    required this.pinHash,
    required this.themePreference,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pinHash': pinHash,
      'themePreference': themePreference,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      pinHash: map['pinHash'] as String,
      themePreference: map['themePreference'] as String,
    );
  }
}
