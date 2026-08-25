import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'database_service.dart';

/// Servis odgovoran za autentikaciju: hashiranje PIN-a te spremanje/
/// dohvaćanje korisničkog profila iz baze
class AuthService {
  final _db = DatabaseService.instance;

  /// Hashira PIN pomoću SHA-256 algoritma
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Provjerava postoji li već kreiran korisnički profil
  Future<AppUser?> getExistingUser() async {
    final db = await _db.database;
    final result = await db.query('users', limit: 1);

    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  /// Kreira novi korisnički profil
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

  /// Provjerava odgovara li uneseni PIN spremljenom hashu
  Future<bool> verifyPin({
    required AppUser user,
    required String enteredPin,
  }) async {
    final enteredHash = _hashPin(enteredPin);
    return enteredHash == user.pinHash;
  }

  /// Ažurira temu korisnika
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

  /// Mijenja PIN korisnika
  Future<void> updatePin({required int userId, required String newPin}) async {
    final db = await _db.database;
    final newHash = _hashPin(newPin);

    await db.update(
      'users',
      {'pinHash': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
