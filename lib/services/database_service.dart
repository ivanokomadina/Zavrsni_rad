import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton servis koji upravlja SQLite bazom podataka cijele aplikacije.
/// Singleton znači da postoji samo JEDNA instanca ove klase tijekom
/// izvršavanja aplikacije - time izbjegavamo otvaranje više konekcija
/// prema istoj bazi, što bi moglo izazvati konflikte.
class DatabaseService {
  // Privatni konstruktor - sprječava kreiranje instance izvana (new DatabaseService()).
  DatabaseService._internal();

  // Jedina instanca ove klase, kreirana odmah pri učitavanju.
  static final DatabaseService instance = DatabaseService._internal();

  // Referenca na otvorenu bazu - null dok se prvi put ne otvori.
  static Database? _database;

  /// Getter koji vraća otvorenu bazu. Ako baza još nije otvorena,
  /// otvara je (i kreira tablice ako baza ne postoji).
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // getDatabasesPath() vraća platformski odgovarajuću putanju
    // gdje aplikacija smije spremati svoje baze (na Androidu/iOS-u
    // to je privatni app-specific folder).
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trackify.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate:
          _onCreate, // poziva se SAMO kad baza ne postoji (prvo pokretanje)
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Definicija sheme baze - kreira sve tablice.
  /// SQL naredbe ovdje su "nacrt" naših modela iz models/ foldera.
  Future<void> _onCreate(Database db, int version) async {
    // Tablica korisnika
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pinHash TEXT NOT NULL,
        themePreference TEXT NOT NULL DEFAULT 'system'
      )
    ''');

    // Tablica kategorija
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorHex TEXT NOT NULL
      )
    ''');

    // Tablica navika
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        colorHex TEXT NOT NULL,
        frequency TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Tablica logova navika - povezana s habits preko FOREIGN KEY-a.
    // ON DELETE CASCADE znači: ako se obriše navika, automatski se
    // brišu i svi njeni logovi (nema "osiročenih" zapisa u bazi).
    await db.execute('''
      CREATE TABLE habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    // Tablica obveza - povezana s categories preko FOREIGN KEY-a.
    // ON DELETE SET NULL znači: ako se obriše kategorija, obveza ostaje,
    // ali joj se categoryId postavi na NULL (ne briše se cijela obveza).
    await db.execute('''
      CREATE TABLE obligations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        priority TEXT NOT NULL,
        categoryId INTEGER,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');
  }
}
