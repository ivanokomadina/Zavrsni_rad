import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// StateNotifier koji upravlja postavkom uključenosti obavijesti
class NotificationsEnabledNotifier extends StateNotifier<bool> {
  static const _prefsKey = 'notifications_enabled';

  // Početno stanje je 'true'
  NotificationsEnabledNotifier() : super(true) {
    _load();
  }

  /// Učitava spremljenu vrijednost pri pokretanju aplikacije
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? true;
  }

  /// Poziva se kad korisnik promijeni prekidač obavijesti u postavkama
  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);

    if (value) {
      await NotificationService.instance.scheduleDailyHabitReminder();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }
}

/// Provider koji izlaže NotificationsEnabledNotifier ostatku aplikacije
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
      return NotificationsEnabledNotifier();
    });
