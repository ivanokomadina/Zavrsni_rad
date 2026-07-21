import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: TrackifyApp()));
}

class TrackifyApp extends StatelessWidget {
  const TrackifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackify',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('Trackify')),
      ),
    );
  }
}