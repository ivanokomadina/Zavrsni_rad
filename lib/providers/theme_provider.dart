import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

/// Pretvara String vrijednost iz baze (kako je spremamo u users.themePreference)
/// u Flutterov ThemeMode enum.
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

/// Radi obrnutu konverziju - ThemeMode enum natrag u String za spremanje.
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

  // Počinjemo sa ThemeMode.system prije nego se korisnik uopće
  // ulogira (na splash/onboarding ekranu nemamo još spremljenu
  // preferenciju - koristimo sistemsku temu uređaja kao razuman default).
  ThemeNotifier(this._authService) : super(ThemeMode.system);

  /// Poziva se kad autentikacija javi da je korisnik dostupan (ulogiran
  /// ili tek registriran) - postavlja temu na onu spremljenu u profilu.
  void syncWithUser(String themePreference) {
    state = _parseThemeMode(themePreference);
  }

  /// Poziva se iz Postavki kad korisnik odabere novu temu.
  Future<void> setThemeMode(ThemeMode mode, {required int userId}) async {
    state = mode; // odmah ažuriramo UI, ne čekamo da baza završi s pisanjem
    await _authService.updateThemePreference(
      userId: userId,
      theme: _themeModeToString(mode),
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final notifier = ThemeNotifier(AuthService());

  // ref.listen ovdje je KLJUČAN dio - ThemeNotifier sam po sebi ne zna
  // ništa o autentikaciji. Ovaj listener "spaja" dva odvojena providera:
  // svaki put kad se authProvider promijeni i korisnik postane dostupan
  // (bilo kroz login, bilo kroz register), automatski pozivamo
  // syncWithUser() da primijenimo NJEGOVU spremljenu temu.
  ref.listen(authProvider, (previous, next) {
    if (next.user != null) {
      notifier.syncWithUser(next.user!.themePreference);
    }
  });

  return notifier;
});
