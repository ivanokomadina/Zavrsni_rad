import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Enum koji opisuje sve moguće faze autentikacije aplikacije
enum AuthStatus {
  loading, // provjerava se baza
  needsSetup, // ne postoji korisnički profil
  unauthenticated, // profil postoji, ali korisnik nije unio ispravan PIN
  authenticated, // korisnik je uspješno ulogiran
}

/// Klasa koja predstavlja trenutno stanje autentikacije
class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier koji drži jedno stanje i izlaže metode koje to stanje mijenjaju
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  // Konstruktor odmah postavlja početno stanje na 'loading' i pokreće provjeru baze
  AuthNotifier(this._authService)
    : super(const AuthState(status: AuthStatus.loading)) {
    checkAuthState();
  }

  /// Provjerava postoji li korisnički profil u bazi
  Future<void> checkAuthState() async {
    final existingUser = await _authService.getExistingUser();

    if (existingUser == null) {
      state = const AuthState(status: AuthStatus.needsSetup);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated, user: existingUser);
    }
  }

  /// Kreira novi profil
  Future<void> register({required String name, required String pin}) async {
    final newUser = await _authService.createUser(name: name, pin: pin);

    state = AuthState(status: AuthStatus.authenticated, user: newUser);
  }

  /// Pokušava ulogirati korisnika s unesenim PIN-om
  Future<void> login(String enteredPin) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final isValid = await _authService.verifyPin(
      user: currentUser,
      enteredPin: enteredPin,
    );

    if (isValid) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Pogrešan PIN. Pokušaj ponovno.',
      );
    }
  }

  /// Odjava - vraća korisnika na login ekran
  void logout() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }

  /// Ponovno učitava korisničke podatke iz baze i ažurira stanje
  Future<void> refreshUser() async {
    final updated = await _authService.getExistingUser();
    if (updated != null) {
      state = state.copyWith(user: updated);
    }
  }
}

/// Provider koji izlaže AuthNotifier ostatku aplikacije
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});
