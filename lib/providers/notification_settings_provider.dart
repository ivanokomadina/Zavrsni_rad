import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  static const _prefsKey = 'notifications_enabled';

  NotificationsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    // SharedPreferences.getInstance() je asinkrono jer prvi put mora
    // pročitati podatke s diska - zato ovo ide u zaseban async _load(),
    // ne u konstruktor direktno.
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? true; // default: uključeno
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
      return NotificationsEnabledNotifier();
    });
