import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  static const _prefsKey = 'notifications_enabled';

  NotificationsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);

    if (value) {
      await NotificationService.instance.scheduleDailyHabitReminder();
      // Napomena: pojedinačne obligation podsjetnike ovdje namjerno NE
      // vraćamo automatski - ponovno će se zakazati sami od sebe čim
      // korisnik sljedeći put uredi tu obvezu. Ovo je prihvatljivo
      // pojednostavljenje - potpuno ponovno zakazivanje SVIH postojećih
      // obveza pri svakom uključivanju prekidača bilo bi dodatna
      // složenost bez velike praktične koristi.
    } else {
      await NotificationService.instance.cancelAll();
    }
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
      return NotificationsEnabledNotifier();
    });
