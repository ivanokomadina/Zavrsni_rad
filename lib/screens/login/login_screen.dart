import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackify/services/notification_service.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    await ref.read(authProvider.notifier).login(_pinController.text);
    // Ako je PIN pogrešan, authProvider postavlja errorMessage,
    // a mi ga prikazujemo watchanjem stanja niže u build() metodi.
    // Ako je ispravan, status postaje 'authenticated' i redirect() sam
    // prebacuje na dashboard - opet, bez ručne navigacije.
    await NotificationService.instance.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch OVDJE (unutar build) je ispravno - želimo da se
    // widget rebuilda kad god se pojavi/promijeni errorMessage.
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_person_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Bok, $userName!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Unesi svoj PIN za nastavak',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  // Prikazujemo poruku greške direktno iz authProvider stanja -
                  // nema potrebe za zasebnim lokalnim errorText poljem.
                  errorText: authState.errorMessage,
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 16),

              FilledButton(
                onPressed: _handleLogin,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Otključaj'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
