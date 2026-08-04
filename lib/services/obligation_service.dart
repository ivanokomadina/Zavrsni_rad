import '../models/obligation.dart';
import 'database_service.dart';

class ObligationService {
  final _db = DatabaseService.instance;

  /// Dohvaća sve obveze, sortirane po roku (najbliži rok prvi).
  /// Ovo je smisleno zadano sortiranje za "to-do" listu.
  Future<List<Obligation>> getAllObligations() async {
    final db = await _db.database;
    final result = await db.query('obligations', orderBy: 'dueDate ASC');
    return result.map((row) => Obligation.fromMap(row)).toList();
  }

  Future<int> insertObligation(Obligation obligation) async {
    final db = await _db.database;
    return await db.insert('obligations', obligation.toMap());
  }

  Future<void> updateObligation(Obligation obligation) async {
    final db = await _db.database;
    await db.update(
      'obligations',
      obligation.toMap(),
      where: 'id = ?',
      whereArgs: [obligation.id],
    );
  }

  Future<void> deleteObligation(int id) async {
    final db = await _db.database;
    await db.delete('obligations', where: 'id = ?', whereArgs: [id]);
  }

  /// Ažurira SAMO status obveze - koristi se kad korisnik klikne
  /// na obvezu da promijeni status bez otvaranja cijele forme za edit.
  Future<void> updateStatus({
    required int id,
    required String newStatus,
  }) async {
    final db = await _db.database;
    await db.update(
      'obligations',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
