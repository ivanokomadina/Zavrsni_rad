import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackify/providers/theme_provider.dart';
import 'package:trackify/services/notification_service.dart';
import 'router/app_router.dart';

void main() async {
  // Obavezno PRIJE bilo kakvog await poziva ili korištenja platform
  // channela (poput NotificationService.initialize()) - Flutter to
  // zahtijeva da bi mogao ispravno povezati engine s frameworkom.
  WidgetsFlutterBinding.ensureInitialized();

  // FFI implementacija SQLite-a treba se koristiti SAMO na desktopu -
  // na Androidu/iOS-u sqflite već ima native implementaciju, pa
  // postavljanje FFI factory-ja tamo nije potrebno.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: TrackifyApp()));
}

/// ConsumerWidget umjesto StatelessWidget jer treba pristup 'ref'
/// da dohvati routerProvider.
class TrackifyApp extends ConsumerWidget {
  const TrackifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider); // dodano

    // MaterialApp.router (umjesto običnog MaterialApp) je varijanta
    // napravljena za rad s "declarative" routing paketima poput go_router.
    return MaterialApp.router(
      title: 'Trackify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode:
          themeMode, // dodano - ranije nije bilo eksplicitno postavljeno (default je system)
      routerConfig: router,
    );
  }
}
