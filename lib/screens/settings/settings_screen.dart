import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final userId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Postavke')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Izgled',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Svijetla'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Tamna'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistemska'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                if (userId != null) {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(selection.first, userId: userId);
                }
              },
            ),
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Notifikacije',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Podsjetnici'),
            subtitle: const Text('Obavijesti za navike i rokove obveza'),
            value: notificationsEnabled,
            onChanged: (value) => ref
                .read(notificationsEnabledProvider.notifier)
                .setEnabled(value),
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Račun', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Promijeni PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/change-pin'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Odjava', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
