import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';

/// Preddefinirane boje iz kojih korisnik bira - jednostavnije od
/// punog color pickera, i dovoljno za potrebe ove aplikacije.
const _availableColors = [
  '#6750A4', // ljubičasta
  '#386A20', // zelena
  '#B3261E', // crvena
  '#8B5000', // narančasta
  '#1A73E8', // plava
];

class AddEditHabitScreen extends ConsumerStatefulWidget {
  // Ako je habitToEdit != null, ekran radi u "edit" modu umjesto "add".
  final Habit? habitToEdit;

  const AddEditHabitScreen({super.key, this.habitToEdit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedColor;
  late String _selectedFrequency;

  bool get _isEditMode => widget.habitToEdit != null;

  @override
  void initState() {
    super.initState();
    // Ako uređujemo postojeću naviku, polja se popunjavaju njenim podacima.
    // Inače kreću prazna / na default vrijednosti.
    final habit = widget.habitToEdit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _descriptionController = TextEditingController(
      text: habit?.description ?? '',
    );
    _selectedColor = habit?.colorHex ?? _availableColors.first;
    _selectedFrequency = habit?.frequency ?? 'daily';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(habitsProvider.notifier);

    if (_isEditMode) {
      final updated = Habit(
        id: widget.habitToEdit!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        colorHex: _selectedColor,
        frequency: _selectedFrequency,
        createdAt:
            widget.habitToEdit!.createdAt, // ne mijenjamo datum kreiranja
      );
      await notifier.updateHabit(updated);
    } else {
      await notifier.addHabit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        colorHex: _selectedColor,
        frequency: _selectedFrequency,
      );
    }

    if (mounted) context.pop(); // vrati se na habits listu
  }

  Future<void> _handleDelete() async {
    await ref
        .read(habitsProvider.notifier)
        .deleteHabit(widget.habitToEdit!.id!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Uredi naviku' : 'Nova navika'),
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
                  (v == null || v.trim().isEmpty) ? 'Unesi naziv navike' : null,
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

            const Text(
              'Učestalost',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Wrap + ChoiceChip - standardan Flutter obrazac za odabir
            // jedne opcije iz kratkog popisa (alternativa dropdownu).
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Svaki dan'),
                  selected: _selectedFrequency == 'daily',
                  onSelected: (_) =>
                      setState(() => _selectedFrequency = 'daily'),
                ),
                ChoiceChip(
                  label: const Text('Tjedno'),
                  selected: _selectedFrequency == 'weekly',
                  onSelected: (_) =>
                      setState(() => _selectedFrequency = 'weekly'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Boja', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _availableColors.map((colorHex) {
                final color = Color(
                  int.parse(colorHex.replaceFirst('#', '0xFF')),
                );
                final isSelected = _selectedColor == colorHex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorHex),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: isSelected ? 22 : 18,
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditMode ? 'Spremi promjene' : 'Dodaj naviku'),
            ),
          ],
        ),
      ),
    );
  }
}
