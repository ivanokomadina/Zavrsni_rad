import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'database_service.dart';

/// Servis odgovoran za autentikaciju: hashiranje PIN-a te spremanje/
/// dohvaćanje korisničkog profila iz baze. Aplikacija je single-user,
/// pa uvijek radimo s najviše jednim retkom u tablici 'users'.
class AuthService {
  final _db = DatabaseService.instance;

  /// Hashira PIN pomoću SHA-256 algoritma.
  /// NIKAD ne spremamo PIN u čistom (plain text) obliku - uvijek samo hash.
  /// SHA-256 je jednosmjerna funkcija: lako je izračunati hash iz PIN-a,
  /// ali (praktički) nemoguće izračunati PIN natrag iz hasha.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin); // string -> bytes
    final digest = sha256.convert(bytes); // bytes -> hash
    return digest.toString(); // hash -> hex string za spremanje u bazu
  }

  /// Provjerava postoji li već kreiran korisnički profil.
  /// Vraća AppUser ako postoji, ili null ako je ovo prvo pokretanje aplikacije.
  Future<AppUser?> getExistingUser() async {
    final db = await _db.database;
    final result = await db.query('users', limit: 1);

    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  /// Kreira novi korisnički profil (poziva se samo jednom, kod onboardinga).
  /// PIN se hashira PRIJE spremanja u bazu.
  Future<AppUser> createUser({
    required String name,
    required String pin,
  }) async {
    final db = await _db.database;
    final pinHash = _hashPin(pin);

    final id = await db.insert('users', {
      'name': name,
      'pinHash': pinHash,
      'themePreference': 'system',
    });

    return AppUser(
      id: id,
      name: name,
      pinHash: pinHash,
      themePreference: 'system',
    );
  }

  /// Provjerava odgovara li uneseni PIN spremljenom hashu.
  /// Hashira uneseni PIN i uspoređuje ga sa spremljenim hashem -
  /// nikad se ne dohvaća/uspoređuje "pravi" PIN.
  Future<bool> verifyPin({
    required AppUser user,
    required String enteredPin,
  }) async {
    final enteredHash = _hashPin(enteredPin);
    return enteredHash == user.pinHash;
  }

  /// Ažurira temu korisnika (koristit ćemo kasnije u postavkama).
  Future<void> updateThemePreference({
    required int userId,
    required String theme,
  }) async {
    final db = await _db.database;
    await db.update(
      'users',
      {'themePreference': theme},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}