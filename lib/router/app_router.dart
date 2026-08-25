import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackify/models/habit.dart';
import 'package:trackify/models/obligation.dart';
import 'package:trackify/screens/calendar/calendar_screen.dart';
import 'package:trackify/screens/habits/add_edit_habit_screen.dart';
import 'package:trackify/screens/habits/habits_screen.dart';
import 'package:trackify/screens/obligations/add_edit_obligation_screen.dart';
import 'package:trackify/screens/obligations/obligations_screen.dart';
import 'package:trackify/screens/settings/change_pin_screen.dart';
import 'package:trackify/screens/settings/settings_screen.dart';
import 'package:trackify/screens/statistics/statistics_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

/// Ova pomoćna klasa se pretplati na authProvider preko ref.listen() i, kad god se authProvider promijeni, pozove notifyListeners()
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Provider koji izlaže konfigurirani GoRouter ostatku aplikacije
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,

    // redirect() se poziva prije svake navigacije
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentPath = state.matchedLocation;

      switch (authState.status) {
        case AuthStatus.loading:
          // Dok provjeravamo bazu, uvijek ostajemo na splashu
          return currentPath == '/splash' ? null : '/splash';

        case AuthStatus.needsSetup:
          // Nema profila
          return currentPath == '/onboarding' ? null : '/onboarding';

        case AuthStatus.unauthenticated:
          // Profil postoji, ali nije unesen ispravan PIN
          return currentPath == '/login' ? null : '/login';

        case AuthStatus.authenticated:
          const authOnlyPaths = ['/splash', '/onboarding', '/login'];
          if (authOnlyPaths.contains(currentPath)) {
            return '/dashboard';
          }
          return null;
      }
    },

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
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/change-pin',
        builder: (context, state) => const ChangePinScreen(),
      ),
    ],
  );
});
