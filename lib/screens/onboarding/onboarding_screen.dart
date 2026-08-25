import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackify/services/notification_service.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Omogućuje da se pozove validacija svih polja odjednom
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await ref
        .read(authProvider.notifier)
        .register(name: _nameController.text.trim(), pin: _pinController.text);

    // Traži se dozvola za obavijesti
    final granted = await NotificationService.instance.requestPermissions();
    if (granted) {
      await NotificationService.instance.scheduleDailyHabitReminder();
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dobrodošao u Trackify',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kreirajmo tvoj profil da možeš krenuti',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ime',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesi svoje ime';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN (4 znamenke)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  validator: (value) {
                    if (value == null || value.length != 4) {
                      return 'PIN mora imati točno 4 znamenke';
                    }
                    return null;
                  },
                ),

                TextFormField(
                  controller: _confirmPinController,
                  decoration: const InputDecoration(
                    labelText: 'Potvrdi PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  validator: (value) {
                    if (value != _pinController.text) {
                      return 'PIN-ovi se ne podudaraju';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kreiraj profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
