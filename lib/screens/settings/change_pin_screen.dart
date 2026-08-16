import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _authService = AuthService();

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final user = ref.read(authProvider).user!;

    // Prvo provjeravamo je li trenutni PIN stvarno ispravan - ne smijemo
    // dopustiti promjenu PIN-a samo na temelju toga da je netko trenutno
    // ulogiran (npr. netko drugi uzme telefon dok je app otključana).
    final isCurrentValid = await _authService.verifyPin(
      user: user,
      enteredPin: _currentPinController.text,
    );

    if (!isCurrentValid) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Trenutni PIN nije ispravan.';
      });
      return;
    }

    await _authService.updatePin(
      userId: user.id!,
      newPin: _newPinController.text,
    );

    // Bez ovoga bi authProvider i dalje u memoriji držao AppUser sa
    // STARIM pinHash-em (vidi objašnjenje uz refreshUser() gore).
    await ref.read(authProvider.notifier).refreshUser();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN uspješno promijenjen.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promjena PIN-a')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _currentPinController,
              decoration: InputDecoration(
                labelText: 'Trenutni PIN',
                border: const OutlineInputBorder(),
                errorText:
                    _errorMessage, // prikazuje grešku iz verifyPin provjere
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              validator: (v) => (v == null || v.length != 4)
                  ? 'Unesi PIN od 4 znamenke'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPinController,
              decoration: const InputDecoration(
                labelText: 'Novi PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              validator: (v) => (v == null || v.length != 4)
                  ? 'Unesi PIN od 4 znamenke'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Potvrdi novi PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              validator: (v) => v != _newPinController.text
                  ? 'PIN-ovi se ne podudaraju'
                  : null,
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
                  : const Text('Spremi'),
            ),
          ],
        ),
      ),
    );
  }
}
