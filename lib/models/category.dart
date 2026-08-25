/// Model koji predstavlja kategoriju obveze (npr. "Fakultet", "Posao", "Osobno").
class Category {
  final int? id;
  final String name;
  final String colorHex;

  Category({this.id, required this.name, required this.colorHex});

  /// Pretvara objekt u Map<String, dynamic> kako bi ga sqflite mogao spremiti u bazu
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'colorHex': colorHex};
  }

  /// Tvornička metoda koja iz Map objekta gradi Category instancu
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String,
    );
  }
}
