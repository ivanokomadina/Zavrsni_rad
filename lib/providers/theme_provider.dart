import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

/// Pretvara String vrijednost iz baze u Flutterov ThemeMode enum
ThemeMode _parseThemeMode(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Radi obrnutu konverziju
String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final AuthService _authService;

  ThemeNotifier(this._authService) : super(ThemeMode.system);

  /// Poziva se kad autentikacija javi da je korisnik dostupan
  void syncWithUser(String themePreference) {
    state = _parseThemeMode(themePreference);
  }

  /// Poziva se iz postavki kad korisnik odabere novu temu
  Future<void> setThemeMode(ThemeMode mode, {required int userId}) async {
    state = mode;
    await _authService.updateThemePreference(
      userId: userId,
      theme: _themeModeToString(mode),
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final notifier = ThemeNotifier(AuthService());

  ref.listen(authProvider, (previous, next) {
    if (next.user != null) {
      notifier.syncWithUser(next.user!.themePreference);
    }
  });

  return notifier;
});
