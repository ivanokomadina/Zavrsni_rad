import '../models/category.dart';
import 'database_service.dart';

/// Servis za CRUD nad kategorijama
class CategoryService {
  final _db = DatabaseService.instance;

  Future<List<Category>> getAllCategories() async {
    final db = await _db.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((row) => Category.fromMap(row)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await _db.database;
    return await db.insert('categories', category.toMap());
  }
}
