import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Enum koji opisuje sve moguće "faze" autentikacije aplikacije.
enum AuthStatus {
  loading, // provjeravamo bazu, još ne znamo stanje (prikazuje se splash)
  needsSetup, // ne postoji korisnički profil - treba onboarding
  unauthenticated, // profil postoji, ali korisnik nije unio ispravan PIN
  authenticated, // korisnik je uspješno ulogiran
}

/// Immutable klasa koja predstavlja trenutno stanje autentikacije.
/// Sadrži i status (enum iznad) i, ako postoji, podatke o korisniku.
class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage; // npr. "Pogrešan PIN" za prikaz u UI-u

  const AuthState({required this.status, this.user, this.errorMessage});

  // Pomoćni "copyWith" - standardni Dart obrazac za kreiranje kopije
  // objekta s izmijenjenim samo pojedinim poljima (jer je AuthState immutable).
  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage:
          errorMessage, // namjerno bez '??' - da možemo i obrisati grešku (proslijediti null)
    );
  }
}

/// StateNotifier je Riverpodova klasa koja "drži" jedno stanje (AuthState)
/// i izlaže metode koje to stanje mijenjaju. Kad se stanje promijeni
/// (state = novoStanje), svi widgeti koji "slušaju" ovaj provider
/// se automatski ponovno izgrade (rebuild) s novim podacima.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  // Konstruktor odmah postavlja početno stanje na 'loading'
  // i pokreće provjeru baze.
  AuthNotifier(this._authService)
    : super(const AuthState(status: AuthStatus.loading)) {
    checkAuthState();
  }

  /// Provjerava postoji li korisnički profil u bazi.
  /// Poziva se pri pokretanju aplikacije (splash ekran).
  Future<void> checkAuthState() async {
    final existingUser = await _authService.getExistingUser();

    if (existingUser == null) {
      // Nema profila -> treba onboarding
      state = const AuthState(status: AuthStatus.needsSetup);
    } else {
      // Profil postoji, ali korisnik još nije unio PIN u ovoj sesiji
      state = AuthState(status: AuthStatus.unauthenticated, user: existingUser);
    }
  }

  /// Kreira novi profil (poziva se s onboarding ekrana).
  Future<void> register({required String name, required String pin}) async {
    final newUser = await _authService.createUser(name: name, pin: pin);
    // Nakon registracije korisnik je odmah ulogiran (ne treba ponovno unositi PIN)
    state = AuthState(status: AuthStatus.authenticated, user: newUser);
  }

  /// Pokušava ulogirati korisnika s unesenim PIN-om.
  Future<void> login(String enteredPin) async {
    final currentUser = state.user;
    if (currentUser == null)
      return; // sigurnosna provjera - ne bi se smjelo dogoditi

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

  /// Odjava - vraća korisnika na login ekran (ne briše profil, samo "zaključava" app).
  void logout() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }

  /// Ponovno učitava korisničke podatke iz baze i ažurira state.
  /// Poziva se nakon operacija koje mijenjaju korisnika izvan
  /// register()/login() toka - npr. nakon promjene PIN-a.
  Future<void> refreshUser() async {
    final updated = await _authService.getExistingUser();
    if (updated != null) {
      state = state.copyWith(user: updated);
    }
  }
}

/// Provider koji izlaže AuthNotifier ostatku aplikacije.
/// Bilo koji widget može pozvati "ref.watch(authProvider)" da dobije
/// trenutno AuthState, ili "ref.read(authProvider.notifier)" da pozove
/// metode poput login()/register().
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});
