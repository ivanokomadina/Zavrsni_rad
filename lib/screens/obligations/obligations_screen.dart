import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/obligation_provider.dart';
import '../../widgets/obligation_card.dart';
import '../../widgets/app_bottom_nav.dart';

class ObligationsScreen extends ConsumerWidget {
  const ObligationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligations = ref.watch(obligationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Obveze')),
      body: obligations.isEmpty
          ? const Center(child: Text('Nemaš nijednu obvezu. Dodaj prvu!'))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: obligations.length,
              itemBuilder: (context, index) {
                final obligation = obligations[index];
                return ObligationCard(
                  obligation: obligation,
                  onStatusTap: () => ref
                      .read(obligationsProvider.notifier)
                      .cycleStatus(obligation),
                  onTap: () =>
                      context.push('/obligations/edit', extra: obligation),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/obligations/add'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
