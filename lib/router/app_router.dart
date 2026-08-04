import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackify/models/habit.dart';
import 'package:trackify/models/obligation.dart';
import 'package:trackify/screens/habits/add_edit_habit_screen.dart';
import 'package:trackify/screens/habits/habits_screen.dart';
import 'package:trackify/screens/obligations/add_edit_obligation_screen.dart';
import 'package:trackify/screens/obligations/obligations_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

/// GoRouter po defaultu ne zna "osluškivati" Riverpod providere.
/// Ova pomoćna klasa (ChangeNotifier) se pretplati na authProvider
/// preko ref.listen() i, kad god se authProvider promijeni,
/// pozove notifyListeners() - a to je signal koji GoRouter razumije
/// (preko parametra refreshListenable) da ponovno evaluira redirect().
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Provider koji izlaže konfigurirani GoRouter ostatku aplikacije.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,

    // redirect() se poziva prije SVAKE navigacije (uključujući onu
    // pokrenutu preko refreshListenable). Ovdje je centralizirana
    // sva logika "tko smije vidjeti koji ekran".
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentPath = state.matchedLocation;

      switch (authState.status) {
        case AuthStatus.loading:
          // Dok provjeravamo bazu, uvijek ostajemo na splashu.
          return currentPath == '/splash' ? null : '/splash';

        case AuthStatus.needsSetup:
          // Nema profila - jedino dopušteno mjesto je onboarding.
          return currentPath == '/onboarding' ? null : '/onboarding';

        case AuthStatus.unauthenticated:
          // Profil postoji, ali nije unesen ispravan PIN - jedino login.
          return currentPath == '/login' ? null : '/login';

        case AuthStatus.authenticated:
          // Ulogiran korisnik ne smije biti na splash/onboarding/login -
          // ako pokuša, prebacujemo ga na dashboard.
          const authOnlyPaths = ['/splash', '/onboarding', '/login'];
          if (authOnlyPaths.contains(currentPath)) {
            return '/dashboard';
          }
          return null; // ostani gdje jesi
      }
    },

    // null vraćen iz redirect() znači "ne preusmjeravaj, prikaži traženu rutu".
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: '/habits/add',
        builder: (context, state) => const AddEditHabitScreen(),
      ),
      GoRoute(
        path: '/habits/edit/:id',
        builder: (context, state) {
          // U ovom koraku ne dohvaćamo habit po id-u iz route parametra
          // direktno ovdje - jednostavnije rješenje: čitamo trenutni popis
          // iz providera preko ProviderContainera routera. Umjesto toga,
          // za sada prosljeđujemo Habit kroz 'extra' parametar iz habits_screen-a.
          final habit = state.extra as Habit;
          return AddEditHabitScreen(habitToEdit: habit);
        },
      ),
      GoRoute(
        path: '/obligations',
        builder: (context, state) => const ObligationsScreen(),
      ),
      GoRoute(
        path: '/obligations/add',
        builder: (context, state) => const AddEditObligationScreen(),
      ),
      GoRoute(
        path: '/obligations/edit',
        builder: (context, state) {
          final obligation = state.extra as Obligation;
          return AddEditObligationScreen(obligationToEdit: obligation);
        },
      ),
    ],
  );
});
