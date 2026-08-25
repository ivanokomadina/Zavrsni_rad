import '../models/obligation.dart';
import 'database_service.dart';

class ObligationService {
  final _db = DatabaseService.instance;

  /// Dohvaća sve obveze, sortirane po roku
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

  /// Ažurira samo status obveze
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
