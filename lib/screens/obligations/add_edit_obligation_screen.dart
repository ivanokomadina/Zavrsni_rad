import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/obligation.dart';
import '../../providers/category_provider.dart';
import '../../providers/obligation_provider.dart';

class AddEditObligationScreen extends ConsumerStatefulWidget {
  final Obligation? obligationToEdit;

  const AddEditObligationScreen({super.key, this.obligationToEdit});

  @override
  ConsumerState<AddEditObligationScreen> createState() =>
      _AddEditObligationScreenState();
}

class _AddEditObligationScreenState
    extends ConsumerState<AddEditObligationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedPriority;
  int? _selectedCategoryId;

  bool get _isEditMode => widget.obligationToEdit != null;

  @override
  void initState() {
    super.initState();
    final o = widget.obligationToEdit;
    _nameController = TextEditingController(text: o?.name ?? '');
    _descriptionController = TextEditingController(text: o?.description ?? '');
    _selectedDate = o?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedPriority = o?.priority ?? 'medium';
    _selectedCategoryId = o?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Otvara ugrađeni Flutter date picker dijalog i sprema odabrani datum
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Otvara jednostavan dijalog za brzo kreiranje nove kategorije,
  /// bez potrebe za zasebnim ekranom za upravljanje kategorijama
  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova kategorija'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Naziv kategorije'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => context.pop(controller.text.trim()),
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final newCategory = await ref
          .read(categoriesProvider.notifier)
          .addCategory(name: name, colorHex: '#78909C');
      setState(() => _selectedCategoryId = newCategory.id);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(obligationsProvider.notifier);

    if (_isEditMode) {
      final updated = Obligation(
        id: widget.obligationToEdit!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        priority: _selectedPriority,
        categoryId: _selectedCategoryId,
        status: widget.obligationToEdit!.status,
      );
      await notifier.updateObligation(updated);
    } else {
      final newObligation = Obligation(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        priority: _selectedPriority,
        categoryId: _selectedCategoryId,
        status: 'pending',
      );
      await notifier.addObligation(newObligation);
    }

    if (mounted) context.pop();
  }

  Future<void> _handleDelete() async {
    await ref
        .read(obligationsProvider.notifier)
        .deleteObligation(widget.obligationToEdit!.id!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Uredi obvezu' : 'Nova obveza'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Unesi naziv obveze' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Opis (opcionalno)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            const Text('Rok', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat('dd.MM.yyyy.').format(_selectedDate)),
            ),
            const SizedBox(height: 24),

            const Text(
              'Prioritet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Nizak'),
                  selected: _selectedPriority == 'low',
                  onSelected: (_) => setState(() => _selectedPriority = 'low'),
                ),
                ChoiceChip(
                  label: const Text('Srednji'),
                  selected: _selectedPriority == 'medium',
                  onSelected: (_) =>
                      setState(() => _selectedPriority = 'medium'),
                ),
                ChoiceChip(
                  label: const Text('Visok'),
                  selected: _selectedPriority == 'high',
                  onSelected: (_) => setState(() => _selectedPriority = 'high'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Kategorija',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Bez kategorije'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Bez kategorije'),
                      ),
                      ...categories.map(
                        (Category c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showAddCategoryDialog,
                  tooltip: 'Nova kategorija',
                ),
              ],
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditMode ? 'Spremi promjene' : 'Dodaj obvezu'),
            ),
          ],
        ),
      ),
    );
  }
}
