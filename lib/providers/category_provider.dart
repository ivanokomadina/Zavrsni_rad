import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/category_service.dart';

/// StateNotifier koji drži popis kategorija. Struktura je identična
/// habitsProvideru iz prošlog koraka - isti obrazac (reload-sve-nakon-
/// promjene) primijenjen na drugi entitet.
class CategoriesNotifier extends StateNotifier<List<Category>> {
  final CategoryService _service;

  CategoriesNotifier(this._service) : super([]) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = await _service.getAllCategories();
  }

  /// Dodaje kategoriju i vraća je natrag (s dodijeljenim id-em) da je
  /// UI odmah može odabrati kao "trenutno selektiranu" bez čekanja
  /// dodatnog upita.
  Future<Category> addCategory({
    required String name,
    required String colorHex,
  }) async {
    final category = Category(name: name, colorHex: colorHex);
    final id = await _service.insertCategory(category);
    await loadCategories();
    return Category(id: id, name: name, colorHex: colorHex);
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
      return CategoriesNotifier(CategoryService());
    });
