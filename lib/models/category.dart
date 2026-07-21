/// Model koji predstavlja kategoriju obveze (npr. "Fakultet", "Posao", "Osobno").
/// Koristi se za grupiranje i vizualno razlikovanje obveza (npr. bojom).
class Category {
  final int? id; // null dok kategorija nije spremljena u bazu (baza sama generira id)
  final String name;
  final String colorHex; // boja spremljena kao hex string, npr. "#FF5733"

  Category({
    this.id,
    required this.name,
    required this.colorHex,
  });

  /// Pretvara objekt u Map<String, dynamic> kako bi ga sqflite mogao spremiti u bazu.
  /// Ključevi Mape moraju odgovarati nazivima stupaca u tablici.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
    };
  }

  /// Tvornička metoda (factory constructor) koja iz Map objekta (retka iz baze)
  /// gradi Category instancu. Ovo se koristi kad čitamo podatke iz SQLite-a.
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String,
    );
  }
}