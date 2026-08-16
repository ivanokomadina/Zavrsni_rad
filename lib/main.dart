import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackify/providers/theme_provider.dart';
import 'router/app_router.dart';

void main() {
  // sqfliteFfiInit() postavlja FFI okruženje (učitava odgovarajuću
  // native SQLite biblioteku za trenutnu desktop platformu).
  sqfliteFfiInit();

  // Ovime kažemo sqflite paketu: "kad god itko pozove openDatabase()/
  // getDatabasesPath() (globalne funkcije iz sqflite paketa), koristi
  // FFI implementaciju umjesto defaultne mobile-only implementacije."
  databaseFactory = databaseFactoryFfi;

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
